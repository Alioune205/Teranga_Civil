import { useState, useEffect, useCallback } from 'react';
import { getCitoyens, getCitoyenById } from '@/services/citoyenApi';
import { getCommuneList } from '@/api/communes';
import { useToast } from '@/components/ui/use-toast';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import { Search, Plus, Zap, Users, Filter, X } from 'lucide-react';
import CitoyenDrawer from '@/components/citoyens/CitoyenDrawer';
import GuichetRapide from '@/components/citoyens/GuichetRapide';
import NouveauCitoyen from '@/components/citoyens/NouveauCitoyen';

export default function CitoyenRepertoire() {
  const { toast } = useToast();
  const { role } = useAuth();
  const [citoyens, setCitoyens] = useState([]);
  const [communes, setCommunes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [totalCount, setTotalCount] = useState(0);

  // Filtres
  const [searchQuery, setSearchQuery] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [filters, setFilters] = useState({
    commune_id: '',
    quartier: ''
  });

  // UI State
  const [selectedCitoyen, setSelectedCitoyen] = useState(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [isGuichetOpen, setIsGuichetOpen] = useState(false);
  const [isNouveauOpen, setIsNouveauOpen] = useState(false);

  // Debounce search
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(searchQuery);
    }, 400);
    return () => clearTimeout(timer);
  }, [searchQuery]);

  // Load Communes
  useEffect(() => {
    const loadCommunes = async () => {
      try {
        const data = await getCommuneList();
        setCommunes(data.results || data);
      } catch (e) {
        console.error(e);
      }
    };
    loadCommunes();
  }, []);

  // Fetch Citoyens
  const fetchCitoyens = useCallback(async () => {
    setLoading(true);
    try {
      const params = {
        search: debouncedSearch,
        ...filters
      };
      // Clean empty filters
      Object.keys(params).forEach(key => !params[key] && delete params[key]);

      const data = await getCitoyens(params);
      setCitoyens(data.results || []);
      setTotalCount(data.count || 0);
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de charger la liste des citoyens.",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  }, [debouncedSearch, filters, toast]);

  useEffect(() => {
    fetchCitoyens();
  }, [fetchCitoyens]);

  const handleResetFilters = () => {
    setSearchQuery('');
    setFilters({ commune_id: '', quartier: '' });
  };

  const handleOpenDrawer = async (citoyen) => {
    try {
      // Afficher le tiroir immédiatement avec les infos de base
      setSelectedCitoyen(citoyen);
      setIsDrawerOpen(true);
      
      // Charger les détails complets (historique, etc.)
      const fullCitoyen = await getCitoyenById(citoyen.id);
      setSelectedCitoyen(fullCitoyen);
    } catch (e) {
      toast({
        title: "Erreur",
        description: "Impossible de charger les détails du citoyen.",
        variant: "destructive"
      });
    }
  };

  const handleOpenGuichet = (citoyen = null) => {
    setSelectedCitoyen(citoyen);
    setIsGuichetOpen(true);
  };

  const handleNouveauCitoyenSuccess = (newCitoyen) => {
    fetchCitoyens();
    // Proposer l'ouverture du guichet
    setSelectedCitoyen(newCitoyen);
    setIsGuichetOpen(true);
  };

  return (
    <div className="h-full flex flex-col bg-layer-0 animate-enter relative">
      {/* Header Sticky */}
      <div className="sticky top-0 z-20 bg-layer-1/80 backdrop-blur-md border-b border-border-strong px-6 py-5 shrink-0">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="p-2.5 bg-primary/10 rounded-xl">
              <Users className="h-6 w-6 text-primary" />
            </div>
            <div>
              <h1 className="text-2xl font-bold font-jakarta text-text-100">Répertoire Citoyen</h1>
              <p className="text-sm text-text-400 mt-0.5">
                {totalCount} citoyen{totalCount !== 1 ? 's' : ''} enregistré{totalCount !== 1 ? 's' : ''}
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
            {role !== 'civil_admin_supervisor' && (
              <>
                <Button 
                  variant="outline" 
                  className="border-primary text-primary hover:bg-primary/5 shadow-sm"
                  onClick={() => setIsNouveauOpen(true)}
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Nouveau citoyen
                </Button>
                <Button 
                  className="bg-emerald-500 hover:bg-emerald-600 text-white shadow-sm font-medium"
                  onClick={() => handleOpenGuichet(null)}
                >
                  <Zap className="h-4 w-4 mr-2" />
                  Guichet Rapide
                </Button>
              </>
            )}
          </div>
        </div>

        {/* Barre de recherche et filtres */}
        <div className="mt-6 flex flex-col md:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-text-400" />
            <input
              type="text"
              placeholder="Rechercher par nom, téléphone ou numéro CNI..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 bg-layer-2 border border-border-strong rounded-xl text-text-100 placeholder:text-text-400 focus:outline-none focus:ring-2 focus:ring-primary/50 transition-shadow"
            />
          </div>
          
          <div className="flex items-center gap-3 overflow-x-auto pb-1 md:pb-0">
            {role === 'super_admin' && (
              <div className="flex items-center gap-2 bg-layer-2 border border-border-strong rounded-xl px-3 py-2.5 shrink-0">
                <Filter className="h-4 w-4 text-text-400" />
                <select 
                  className="bg-transparent border-none text-sm text-text-100 focus:ring-0 cursor-pointer outline-none w-[160px]"
                  value={filters.commune_id}
                  onChange={(e) => setFilters(prev => ({ ...prev, commune_id: e.target.value }))}
                >
                  <option value="">Toutes les communes</option>
                  {communes.map(c => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>
            )}
            
            {(searchQuery || filters.commune_id || filters.quartier) && (
              <Button 
                variant="ghost" 
                size="sm" 
                onClick={handleResetFilters}
                className="text-text-400 hover:text-error shrink-0"
              >
                <X className="h-4 w-4 mr-1" />
                Réinitialiser
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Tableau */}
      <div className="flex-1 p-6 overflow-hidden flex flex-col">
        <div className="bg-layer-1 border border-border-strong rounded-xl shadow-sm overflow-hidden flex-1 flex flex-col">
          <div className="overflow-x-auto flex-1">
            <table className="w-full text-left text-sm whitespace-nowrap">
              <thead className="bg-layer-2 border-b border-border-strong text-text-300 uppercase text-xs font-semibold tracking-wider sticky top-0 z-10">
                <tr>
                  <th className="px-6 py-4">Citoyen</th>
                  <th className="px-6 py-4">Téléphone</th>
                  <th className="px-6 py-4">Commune / Quartier</th>
                  <th className="px-6 py-4">Numéro CNI</th>
                  <th className="px-6 py-4 text-center">Demandes</th>
                  <th className="px-6 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-subtle">
                {loading ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-12 text-center text-text-400">
                      Chargement des citoyens...
                    </td>
                  </tr>
                ) : citoyens.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-12 text-center">
                      <div className="flex flex-col items-center justify-center">
                        <Users className="h-10 w-10 text-text-400 mb-3" />
                        <p className="text-text-200 font-medium">Aucun citoyen trouvé</p>
                        <p className="text-sm text-text-400 mt-1">Modifiez vos critères de recherche ou ajoutez un citoyen.</p>
                      </div>
                    </td>
                  </tr>
                ) : (
                  citoyens.map((citoyen) => (
                    <tr 
                      key={citoyen.id} 
                      className="hover:bg-layer-2 transition-colors group cursor-pointer"
                      onClick={() => handleOpenDrawer(citoyen)}
                    >
                      <td className="px-6 py-3">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-sm shrink-0">
                            {citoyen.prenom.charAt(0)}{citoyen.nom.charAt(0)}
                          </div>
                          <div>
                            <div className="font-medium text-text-100 group-hover:text-primary transition-colors">
                              {citoyen.nom_complet}
                            </div>
                            <div className="text-xs text-text-400 mt-0.5">
                              {citoyen.age ? `${citoyen.age} ans` : 'Âge inconnu'} • {citoyen.sexe === 'M' ? 'H' : 'F'}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-3 text-text-200">
                        {citoyen.telephone}
                      </td>
                      <td className="px-6 py-3 text-text-200">
                        <div className="font-medium text-text-100">{citoyen.commune?.name || '—'}</div>
                        <div className="text-xs text-text-400">{citoyen.quartier || '—'}</div>
                      </td>
                      <td className="px-6 py-3">
                        <span className="font-mono text-xs bg-layer-3 px-2 py-1 rounded text-text-300">
                          {citoyen.numero_cni || 'Non renseigné'}
                        </span>
                      </td>
                      <td className="px-6 py-3 text-center">
                        <div className="inline-flex items-center justify-center px-2.5 py-1 rounded-full bg-layer-3 text-text-200 text-xs font-medium">
                          {citoyen.nombre_demandes_total}
                        </div>
                      </td>
                      <td className="px-6 py-3 text-right">
                        <div className="flex items-center justify-end gap-2" onClick={e => e.stopPropagation()}>
                          <Button 
                            variant="ghost" 
                            size="sm"
                            className="text-text-300 hover:text-primary hover:bg-primary/10"
                            onClick={() => handleOpenDrawer(citoyen)}
                          >
                            Voir fiche
                          </Button>
                          {role !== 'civil_admin_supervisor' && (
                            <Button 
                              variant="ghost" 
                              size="icon"
                              className="text-emerald-500 hover:bg-emerald-50 dark:hover:bg-emerald-500/10"
                              onClick={() => handleOpenGuichet(citoyen)}
                              title="Guichet Rapide"
                            >
                              <Zap className="h-4 w-4" />
                            </Button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Modals & Drawers */}
      <CitoyenDrawer 
        open={isDrawerOpen} 
        onOpenChange={setIsDrawerOpen} 
        citoyen={selectedCitoyen}
        onOpenGuichet={handleOpenGuichet}
      />
      
      <GuichetRapide 
        open={isGuichetOpen} 
        onOpenChange={setIsGuichetOpen} 
        initialCitoyen={selectedCitoyen}
        onOpenNouveauCitoyen={setIsNouveauOpen}
      />
      
      <NouveauCitoyen 
        open={isNouveauOpen} 
        onOpenChange={setIsNouveauOpen}
        onSuccess={handleNouveauCitoyenSuccess}
      />
    </div>
  );
}
