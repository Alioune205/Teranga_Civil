// src/pages/Communes.jsx
import { useState, useEffect, useMemo } from 'react';
import { getCommuneList, createCommune, updateCommune, patchCommune } from '@/api/communes';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Card } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { toast } from '@/components/ui/use-toast';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog';
import {
  Search,
  Plus,
  Pencil,
  ToggleLeft,
  ToggleRight,
  Loader2,
  Building2,
} from 'lucide-react';

const EMPTY_FORM = {
  name: '',
  region: '',
  departement: '',
  code: '',
  phone: '',
  email: '',
};

export default function Communes() {
  const [communes, setCommunes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingCommune, setEditingCommune] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState({});

  const fetchCommunes = async () => {
    setLoading(true);
    try {
      const data = await getCommuneList();
      setCommunes(Array.isArray(data) ? data : data.results || []);
    } catch (error) {
      toast({ title: 'Erreur', description: 'Impossible de charger les communes.', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCommunes();
  }, []);

  const filteredCommunes = useMemo(() => {
    if (!search) return communes;
    const lowerSearch = search.toLowerCase();
    return communes.filter(
      (c) =>
        c.name?.toLowerCase().includes(lowerSearch) ||
        c.region?.toLowerCase().includes(lowerSearch) ||
        c.departement?.toLowerCase().includes(lowerSearch) ||
        c.code?.toLowerCase().includes(lowerSearch)
    );
  }, [communes, search]);

  const openCreateDialog = () => {
    setEditingCommune(null);
    setForm(EMPTY_FORM);
    setErrors({});
    setDialogOpen(true);
  };

  const openEditDialog = (commune) => {
    setEditingCommune(commune);
    setForm({
      name: commune.name || '',
      region: commune.region || '',
      departement: commune.departement || '',
      code: commune.code || '',
      phone: commune.phone || '',
      email: commune.email || '',
    });
    setErrors({});
    setDialogOpen(true);
  };

  const validateForm = () => {
    const newErrors = {};
    if (!form.name.trim()) newErrors.name = 'Le nom est obligatoire';
    if (!form.region.trim()) newErrors.region = 'La région est obligatoire';
    if (!form.departement.trim()) newErrors.departement = 'Le département est obligatoire';
    if (!form.code.trim()) newErrors.code = 'Le code est obligatoire';
    if (form.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
      newErrors.email = 'Email invalide';
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async () => {
    if (!validateForm()) return;
    setSaving(true);
    try {
      if (editingCommune) {
        await updateCommune(editingCommune.id, form);
        toast({ title: 'Commune modifiée', description: `${form.name} a été mise à jour.`, variant: 'success' });
      } else {
        await createCommune(form);
        toast({ title: 'Commune créée', description: `${form.name} a été créée.`, variant: 'success' });
      }
      setDialogOpen(false);
      fetchCommunes();
    } catch (error) {
      toast({
        title: 'Erreur',
        description: error.response?.data?.detail || 'Impossible de sauvegarder la commune.',
        variant: 'destructive',
      });
    } finally {
      setSaving(false);
    }
  };

  const toggleActive = async (commune) => {
    try {
      await patchCommune(commune.id, { is_active: !commune.is_active });
      toast({
        title: commune.is_active ? 'Commune désactivée' : 'Commune activée',
        description: `${commune.name} a été ${commune.is_active ? 'désactivée' : 'activée'}.`,
        variant: 'success',
      });
      fetchCommunes();
    } catch (error) {
      toast({ title: 'Erreur', description: 'Impossible de modifier le statut.', variant: 'destructive' });
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-secondary">Communes</h1>
          <p className="text-sm text-text-400 mt-1">
            {communes.length} commune{communes.length > 1 ? 's' : ''} enregistrée{communes.length > 1 ? 's' : ''}
          </p>
        </div>
        <Button onClick={openCreateDialog} className="gap-2">
          <Plus className="h-4 w-4" />
          Nouvelle commune
        </Button>
      </div>

      {/* Barre de recherche */}
      <Card className="p-4 border-border-subtle">
        <div className="relative max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-text-400" />
          <Input
            placeholder="Rechercher une commune..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
      </Card>

      {/* Table */}
      <Card className="table-container">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-border-subtle bg-layer-2">
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Nom</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Région</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Département</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Code</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Téléphone</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Email</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Statut</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i} className="border-b border-border-subtle">
                    {[...Array(8)].map((_, j) => (
                      <td key={j} className="px-4 py-3">
                        <Skeleton className="h-5 w-full" />
                      </td>
                    ))}
                  </tr>
                ))
              ) : filteredCommunes.length > 0 ? (
                filteredCommunes.map((commune) => (
                  <tr key={commune.id} className="border-b border-border-subtle hover:bg-layer-2 transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <Building2 className="h-4 w-4 text-primary" />
                        <span className="text-sm font-medium text-secondary">{commune.name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-text-300">{commune.region || '—'}</td>
                    <td className="px-4 py-3 text-sm text-text-300">{commune.departement || '—'}</td>
                    <td className="px-4 py-3">
                      <code className="text-xs bg-layer-3 px-2 py-1 rounded font-mono">{commune.code}</code>
                    </td>
                    <td className="px-4 py-3 text-sm text-text-300">{commune.phone || '—'}</td>
                    <td className="px-4 py-3 text-sm text-text-300">{commune.email || '—'}</td>
                    <td className="px-4 py-3">
                      <Badge className={commune.is_active ? 'bg-success text-white border-success' : 'bg-layer-3 text-text-400 border-border-strong'}>
                        {commune.is_active ? 'Actif' : 'Inactif'}
                      </Badge>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1">
                        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => openEditDialog(commune)}>
                          <Pencil className="h-4 w-4 text-text-400" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8"
                          onClick={() => toggleActive(commune)}
                          title={commune.is_active ? 'Désactiver' : 'Activer'}
                        >
                          {commune.is_active ? (
                            <ToggleRight className="h-4 w-4 text-success" />
                          ) : (
                            <ToggleLeft className="h-4 w-4 text-text-400" />
                          )}
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={8} className="px-4 py-12 text-center text-text-400">
                    Aucune commune trouvée
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Dialog Créer/Modifier */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editingCommune ? 'Modifier la commune' : 'Nouvelle commune'}</DialogTitle>
            <DialogDescription>
              {editingCommune
                ? `Modifier les informations de ${editingCommune.name}`
                : 'Renseignez les informations de la nouvelle commune'}
            </DialogDescription>
          </DialogHeader>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Nom *</Label>
              <Input
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="Ex: Dakar-Plateau"
              />
              {errors.name && <p className="text-xs text-danger">{errors.name}</p>}
            </div>
            <div className="space-y-2">
              <Label>Code *</Label>
              <Input
                value={form.code}
                onChange={(e) => setForm({ ...form, code: e.target.value })}
                placeholder="Ex: DK-01"
              />
              {errors.code && <p className="text-xs text-danger">{errors.code}</p>}
            </div>
            <div className="space-y-2">
              <Label>Région *</Label>
              <Input
                value={form.region}
                onChange={(e) => setForm({ ...form, region: e.target.value })}
                placeholder="Ex: Dakar"
              />
              {errors.region && <p className="text-xs text-danger">{errors.region}</p>}
            </div>
            <div className="space-y-2">
              <Label>Département *</Label>
              <Input
                value={form.departement}
                onChange={(e) => setForm({ ...form, departement: e.target.value })}
                placeholder="Ex: Dakar"
              />
              {errors.departement && <p className="text-xs text-danger">{errors.departement}</p>}
            </div>
            <div className="space-y-2">
              <Label>Téléphone</Label>
              <Input
                value={form.phone}
                onChange={(e) => setForm({ ...form, phone: e.target.value })}
                placeholder="Ex: 338201234"
              />
            </div>
            <div className="space-y-2">
              <Label>Email</Label>
              <Input
                type="email"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                placeholder="Ex: mairie@dakar.sn"
              />
              {errors.email && <p className="text-xs text-danger">{errors.email}</p>}
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Annuler
            </Button>
            <Button onClick={handleSubmit} disabled={saving}>
              {saving && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              {editingCommune ? 'Modifier' : 'Créer'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
