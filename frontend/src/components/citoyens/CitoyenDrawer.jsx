import { useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Copy, Zap, FileText, MapPin, Mail, Phone, Calendar, User, ExternalLink, Activity, X } from 'lucide-react';
import { StatusBadge } from '@/components/StatusBadge';
import { useToast } from '@/components/ui/use-toast';
import { useAuth } from '@/hooks/useAuth';
import { downloadPdf } from '@/api/dossiers';

export default function CitoyenDrawer({ open, onOpenChange, citoyen, onOpenGuichet }) {
  const { toast } = useToast();
  const { role } = useAuth();

  useEffect(() => {
    const handleEscape = (e) => {
      if (e.key === 'Escape') onOpenChange(false);
    };
    if (open) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = '';
    };
  }, [open, onOpenChange]);

  if (!citoyen) return null;

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    toast({
      title: "Copié",
      description: "Le numéro CNI a été copié dans le presse-papiers."
    });
  };

  const handleDownloadPdf = async (dossier) => {
    try {
      toast({
        title: "Téléchargement",
        description: "Ouverture du PDF en cours...",
      });
      const blob = await downloadPdf(dossier.id);
      const url = window.URL.createObjectURL(new Blob([blob], { type: 'application/pdf' }));
      const link = document.createElement('a');
      link.href = url;
      link.target = '_blank';
      link.download = `Certificat_${dossier.reference}.pdf`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      setTimeout(() => window.URL.revokeObjectURL(url), 1000);
    } catch (err) {
      console.error("Erreur téléchargement PDF:", err);
      toast({
        title: "Erreur",
        description: "Impossible de télécharger le PDF.",
        variant: "destructive"
      });
    }
  };

  return (
    <>
      <div 
        className={`fixed inset-0 bg-black/40 z-40 transition-opacity duration-300 ${open ? 'opacity-100' : 'opacity-0 pointer-events-none'}`} 
        onClick={() => onOpenChange(false)}
      />
      <div 
        className={`fixed top-0 right-0 bottom-0 w-[440px] max-w-[100vw] h-[100dvh] flex flex-col bg-layer-1 shadow-[-4px_0_16px_rgba(0,0,0,0.1)] z-50 transition-transform duration-300 ease-out ${open ? 'translate-x-0' : 'translate-x-full'}`}
      >
        
        {/* En-tête du tiroir */}
        <div className="p-6 border-b border-border-subtle bg-layer-2 shrink-0">
          <div className="flex items-start justify-between relative">
            <div className="flex items-center gap-4">
              <div className="w-20 h-20 rounded-full bg-primary flex items-center justify-center text-white font-bold text-2xl shadow-lg ring-4 ring-primary/20">
                {citoyen.prenom?.charAt(0)}{citoyen.nom?.charAt(0)}
              </div>
              <div>
                <h2 className="text-2xl font-bold font-jakarta text-text-100">
                  {citoyen.nom_complet}
                </h2>
                <div className="flex items-center gap-2 mt-2">
                  <Badge className="bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400 hover:bg-emerald-100 border-0 flex items-center gap-1">
                    <Activity className="h-3 w-3" />
                    {citoyen.est_actif ? 'Actif & Vérifié' : 'Inactif'}
                  </Badge>
                </div>
              </div>
            </div>
            <Button variant="ghost" size="icon" onClick={() => onOpenChange(false)} className="absolute -top-2 -right-2 text-text-400 hover:text-text-100 hover:bg-layer-3">
              <X className="h-5 w-5" />
            </Button>
          </div>
          
          <div className="flex gap-3 mt-6">
            {role !== 'civil_admin_supervisor' && (
              <>
                <Button onClick={() => { onOpenChange(false); onOpenGuichet(citoyen); }} className="flex-1 bg-emerald-500 text-white hover:bg-emerald-600 shadow-sm">
                  <Zap className="h-4 w-4 mr-2" />
                  Guichet Rapide
                </Button>
                <Button variant="outline" className="flex-1 border-primary text-primary hover:bg-primary/5">
                  Modifier
                </Button>
              </>
            )}
          </div>
        </div>

        {/* Contenu scrollable */}
        <div className="flex-1 overflow-y-auto p-6 space-y-8">
          
          {/* Informations personnelles */}
          <section>
            <h3 className="text-sm font-semibold text-text-400 uppercase tracking-wider mb-4 flex items-center gap-2">
              <User className="h-4 w-4" /> Informations Personnelles
            </h3>
            <div className="grid grid-cols-2 gap-y-4 gap-x-6 text-sm">
              <div>
                <span className="text-text-400 block mb-1">Date de naissance</span>
                <span className="font-medium text-text-100 flex items-center gap-2">
                  <Calendar className="h-3 w-3 text-text-300" />
                  {citoyen.date_naissance} ({citoyen.age} ans)
                </span>
              </div>
              <div>
                <span className="text-text-400 block mb-1">Sexe / Nat.</span>
                <span className="font-medium text-text-100">
                  {citoyen.sexe === 'M' ? 'Masculin' : 'Féminin'} • {citoyen.nationalite}
                </span>
              </div>
              <div>
                <span className="text-text-400 block mb-1">Téléphone</span>
                <span className="font-medium text-text-100 flex items-center gap-2">
                  <Phone className="h-3 w-3 text-text-300" />
                  {citoyen.telephone}
                </span>
              </div>
              <div>
                <span className="text-text-400 block mb-1">Email</span>
                <span className="font-medium text-text-100 flex items-center gap-2 truncate" title={citoyen.email}>
                  <Mail className="h-3 w-3 text-text-300" />
                  {citoyen.email || '—'}
                </span>
              </div>
              <div className="col-span-2">
                <span className="text-text-400 block mb-1">Adresse & Commune</span>
                <span className="font-medium text-text-100 flex items-center gap-2">
                  <MapPin className="h-3 w-3 text-text-300 shrink-0" />
                  {citoyen.adresse ? `${citoyen.adresse}, ` : ''}{citoyen.commune?.name}{citoyen.quartier ? ` — Quartier ${citoyen.quartier}` : ''}
                </span>
              </div>
              <div className="col-span-2 p-3 bg-layer-2 border border-border-strong rounded-lg mt-2 flex justify-between items-center">
                <div>
                  <span className="text-xs text-text-400 uppercase tracking-wider font-semibold">Numéro CNI</span>
                  <div className="font-mono text-lg font-bold text-text-100 mt-1">
                    {citoyen.numero_cni || 'Non renseigné'}
                  </div>
                  {citoyen.date_expiration_cni && (
                    <span className="text-xs text-text-300 mt-1 block">Exp: {citoyen.date_expiration_cni}</span>
                  )}
                </div>
                {citoyen.numero_cni && (
                  <Button variant="ghost" size="icon" onClick={() => copyToClipboard(citoyen.numero_cni)} title="Copier" className="text-text-300 hover:text-primary">
                    <Copy className="h-4 w-4" />
                  </Button>
                )}
              </div>
            </div>
          </section>

          {/* Filiation */}
          <section>
            <h3 className="text-sm font-semibold text-text-400 uppercase tracking-wider mb-4 flex items-center gap-2">
              <User className="h-4 w-4" /> Filiation
            </h3>
            <div className="grid grid-cols-2 gap-y-4 gap-x-6 text-sm">
              <div>
                <span className="text-text-400 block mb-1">Nom du père</span>
                <span className="font-medium text-text-100">
                  {citoyen.nom_pere || 'Non renseigné'}
                </span>
              </div>
              <div>
                <span className="text-text-400 block mb-1">Nom de la mère</span>
                <span className="font-medium text-text-100">
                  {citoyen.nom_mere || 'Non renseigné'}
                </span>
              </div>
            </div>
          </section>

          {/* Historique des demandes */}
          <section>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-semibold text-text-400 uppercase tracking-wider flex items-center gap-2">
                <FileText className="h-4 w-4" /> Historique ({citoyen.nombre_demandes_total})
              </h3>
              {citoyen.nombre_demandes_total > 5 && (
                <button className="text-xs text-primary hover:underline font-medium">Voir tout</button>
              )}
            </div>
            
            <div className="space-y-3">
              {citoyen.dossiers_history && citoyen.dossiers_history.length > 0 ? (
                citoyen.dossiers_history.slice(0, 5).map(dossier => (
                  <div key={dossier.id} className="p-3 bg-layer-2 border border-border-strong rounded-lg flex items-center justify-between group hover:border-primary/50 transition-colors">
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-xs font-mono bg-layer-3 px-1.5 py-0.5 rounded text-text-300">
                          {dossier.reference}
                        </span>
                        <StatusBadge status={dossier.status} />
                      </div>
                      <p className="font-medium text-sm text-text-100">{dossier.type_display || dossier.type}</p>
                      <p className="text-xs text-text-400 mt-1">
                        {new Date(dossier.created_at).toLocaleDateString('fr-FR')}
                      </p>
                    </div>
                    {['approved', 'completed', 'delivered'].includes(dossier.status) && (
                      <Button variant="ghost" size="icon" className="text-primary opacity-0 group-hover:opacity-100 transition-opacity" onClick={() => handleDownloadPdf(dossier)}>
                        <ExternalLink className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                ))
              ) : (
                <div className="text-center p-6 bg-layer-2 border border-border-strong border-dashed rounded-lg">
                  <p className="text-sm text-text-400">Aucune demande enregistrée</p>
                </div>
              )}
            </div>
          </section>
        </div>

        {/* Action fixe en bas */}
        {role !== 'civil_admin_supervisor' && (
          <div className="p-4 border-t border-border-subtle bg-layer-2 shrink-0">
            <Button 
              className="w-full bg-emerald-500 hover:bg-emerald-600 text-white shadow-md font-medium"
              onClick={() => { onOpenChange(false); onOpenGuichet(citoyen); }}
            >
              <Zap className="h-4 w-4 mr-2" />
              Démarrer une demande au guichet
            </Button>
          </div>
        )}

      </div>
    </>
  );
}
