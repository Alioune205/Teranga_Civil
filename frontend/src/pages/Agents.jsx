// src/pages/Agents.jsx
import { useState, useEffect, useMemo } from 'react';
import { useAuth } from '@/hooks/useAuth';
import {
  getUserList,
  createUser,
  deleteUser,
  changeUserPassword,
  toggleAgentBreak,
  toggleAgentDispatchEligibility,
} from '@/api/users';
import { getCommuneList } from '@/api/communes';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Skeleton } from '@/components/ui/skeleton';
import { toast } from '@/components/ui/use-toast';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog';
import { Search, Plus, Loader2, Trash2, FileText, Coffee, PowerOff, Power } from 'lucide-react';

/* ─── Données statiques ──────────────────────────────────────────────── */
const ROLE_BADGES = {
  agent:               { label: "Agent Civil",   cls: 'bg-blue-100 text-blue-800' },
  civil_admin:         { label: 'Admin Civil',    cls: 'bg-emerald-100 text-emerald-800' },
  civil_admin_supervisor: { label: 'Superviseur', cls: 'bg-orange-100 text-orange-800' },
  super_admin:         { label: 'Super Admin',    cls: 'bg-purple-100 text-purple-800' },
};

const ROLE_OPTIONS = [
  { value: '',                   label: 'Tous les rôles' },
  { value: 'agent',              label: "Agent Civil" },
];

const STATUS_OPTIONS = [
  { value: '',      label: 'Tous les statuts' },
  { value: 'true',  label: 'Actif' },
  { value: 'false', label: 'Inactif' },
];

const EMPTY_FORM = { full_name: '', email: '', phone: '', role: 'agent', commune: '', password: '' };

/* ─── Helpers ────────────────────────────────────────────────────────── */
function initials(name = '') {
  return name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase() || '?';
}

function formatDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('fr-FR', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
}

/* ─── Sous-composants ────────────────────────────────────────────────── */
function Avatar({ name }) {
  return (
    <div
      style={{ background: 'linear-gradient(135deg,#3b82f6,#6366f1)' }}
      className="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 shadow-sm"
    >
      <span className="text-[10px] font-bold text-white leading-none">{initials(name)}</span>
    </div>
  );
}

function DspBadge({ u }) {
  if (!u.is_dispatch_eligible)
    return <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-red-100 text-red-700">Absent</span>;
  if (u.is_on_break) {
    const t = u.break_started_at
      ? new Date(u.break_started_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })
      : null;
    return (
      <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-orange-100 text-orange-700">
        En pause{t ? ` · ${t}` : ''}
      </span>
    );
  }
  return <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-700">Disponible</span>;
}

/* ═══════════════════════════════════════════════════════════════════════ */
export default function Agents() {
  const { user } = useAuth();
  const [users,     setUsers]    = useState([]);
  const [communes,  setCommunes] = useState([]);
  const [loading,   setLoading]  = useState(true);
  const [search,    setSearch]   = useState('');
  const [filterRole,    setFilterRole]    = useState('');
  const [filterCommune, setFilterCommune] = useState('');
  const [filterStatus,  setFilterStatus]  = useState('');
  const [dialogOpen,  setDialogOpen]  = useState(false);
  const [form,        setForm]        = useState(EMPTY_FORM);
  const [saving,      setSaving]      = useState(false);
  const [errors,      setErrors]      = useState({});
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [selAgent,    setSelAgent]    = useState(null);
  const [newPwd,      setNewPwd]      = useState('');
  const [changingPwd, setChangingPwd] = useState(false);
  const [busyId,      setBusyId]      = useState(null); // id en cours

  /* ─── Fetch ─────────────────────────────────────────────────────────── */
  const fetchUsers = async () => {
    setLoading(true);
    try {
      const params = {};
      if (filterRole    && filterRole    !== 'all') params.role      = filterRole;
      if (filterCommune && filterCommune !== 'all') params.commune   = filterCommune;
      if (filterStatus  && filterStatus  !== 'all') params.is_active = filterStatus;
      const data = await getUserList(params);
      setUsers(Array.isArray(data) ? data : data.results || []);
    } catch (err) {
      if (err?.response?.status !== 401 && err?.status !== 401)
        toast({ title: 'Erreur', description: 'Impossible de charger les agents.', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchUsers(); }, [filterRole, filterCommune, filterStatus]);
  useEffect(() => {
    getCommuneList()
      .then((d) => setCommunes(Array.isArray(d) ? d : d.results || []))
      .catch(() => {});
  }, []);

  /* ─── Dérivés ───────────────────────────────────────────────────────── */
  const availableCommunes = useMemo(() => {
    if (user?.role === 'super_admin') return communes;
    const cid = user?.commune?.id || user?.commune;
    return cid ? communes.filter((c) => c.id === cid) : [];
  }, [communes, user]);

  const filteredUsers = useMemo(() => {
    let result = users.filter((u) => !['super_admin', 'civil_admin', 'civil_admin_supervisor'].includes(u.role));
    if (search) {
      const q = search.toLowerCase();
      result = result.filter((u) => u.full_name?.toLowerCase().includes(q) || u.email?.toLowerCase().includes(q));
    }
    return result;
  }, [users, search]);

  /* ─── Handlers ──────────────────────────────────────────────────────── */
  const validate = () => {
    const e = {};
    if (!form.full_name.trim())  e.full_name = 'Obligatoire';
    if (!form.email.trim())      e.email     = 'Obligatoire';
    if (form.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) e.email = 'Email invalide';
    if (!form.role)              e.role      = 'Obligatoire';
    if (!form.commune)           e.commune   = 'Obligatoire';
    if (!form.password || form.password.length < 6) e.password = 'Min. 6 caractères';
    setErrors(e);
    return !Object.keys(e).length;
  };

  const handleSubmit = async () => {
    if (!validate()) return;
    setSaving(true);
    try {
      const parts = form.full_name.trim().split(' ');
      const payload = {
        ...form,
        first_name: parts[0],
        last_name:  parts.slice(1).join(' '),
      };
      delete payload.full_name;
      await createUser(payload);
      toast({ title: 'Agent créé', description: `${form.full_name} créé avec succès.` });
      setDialogOpen(false);
      setForm(EMPTY_FORM);
      fetchUsers();
    } catch (err) {
      toast({ title: 'Erreur', description: err.response?.data?.message || "Impossible de créer l'agent.", variant: 'destructive' });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id, name) => {
    if (!window.confirm(`Supprimer l'agent ${name} ?`)) return;
    try {
      await deleteUser(id);
      toast({ title: 'Agent supprimé', description: `${name} supprimé.` });
      setDetailsOpen(false);
      fetchUsers();
    } catch (err) {
      toast({ title: 'Erreur', description: 'Impossible de supprimer.', variant: 'destructive' });
    }
  };

  const handleChangePwd = async () => {
    if (!newPwd || newPwd.length < 6) {
      toast({ title: 'Erreur', description: 'Minimum 6 caractères.', variant: 'destructive' });
      return;
    }
    setChangingPwd(true);
    try {
      await changeUserPassword(selAgent.id, newPwd);
      toast({ title: 'Succès', description: 'Mot de passe modifié.' });
      setNewPwd('');
    } catch {
      toast({ title: 'Erreur', description: 'Impossible de modifier le mot de passe.', variant: 'destructive' });
    } finally {
      setChangingPwd(false);
    }
  };

  const handleBreak = async (ru) => {
    setBusyId(ru.id + '_break');
    try {
      await toggleAgentBreak(ru.id);
      await fetchUsers();
      toast({ title: ru.is_on_break ? 'Pause terminée' : 'En pause', description: ru.full_name });
    } catch (err) {
      const msg = err?.response?.data?.message || err?.response?.data?.detail;
      toast({ title: 'Erreur', description: msg || 'Action impossible. Vérifiez que le serveur est redémarré.', variant: 'destructive' });
    } finally {
      setBusyId(null);
    }
  };

  const handleAbsence = async (ru) => {
    if (ru.is_dispatch_eligible && !window.confirm(`Mettre ${ru.full_name} en absence ? Il ne recevra plus de tâches.`)) return;
    setBusyId(ru.id + '_abs');
    try {
      await toggleAgentDispatchEligibility(ru.id);
      await fetchUsers();
      toast({ title: ru.is_dispatch_eligible ? 'Agent mis en absence' : 'Agent réactivé', description: ru.full_name });
    } catch (err) {
      const msg = err?.response?.data?.message || err?.response?.data?.detail;
      toast({ title: 'Erreur', description: msg || 'Action impossible. Vérifiez que le serveur est redémarré.', variant: 'destructive' });
    } finally {
      setBusyId(null);
    }
  };

  const canManage = ['super_admin', 'civil_admin', 'civil_admin_supervisor'].includes(user?.role);

  /* ─── Rendu ─────────────────────────────────────────────────────────── */
  return (
    <div className="p-0 space-y-4">
      {/* Titre + bouton */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-text-100">Agents</h1>
          <p className="text-xs text-text-400 mt-0.5">Gestion des utilisateurs et disponibilités</p>
        </div>
        {canManage && (
          <Button
            size="sm"
            className="gap-1.5 text-sm"
            onClick={() => {
              const cid = user?.role !== 'super_admin' ? String(user?.commune?.id || user?.commune || '') : '';
              setForm({ ...EMPTY_FORM, commune: cid });
              setErrors({});
              setDialogOpen(true);
            }}
          >
            <Plus className="h-3.5 w-3.5" />
            Nouvel agent
          </Button>
        )}
      </div>

      {/* Barre de filtres */}
      <div className="flex flex-wrap gap-2 p-3 bg-white border border-border-strong rounded-lg shadow-sm">
        <div className="relative flex-1 min-w-[180px]">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-text-400 pointer-events-none" />
          <Input
            placeholder="Nom ou email…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-8 h-8 text-sm border-border-strong bg-layer-2"
          />
        </div>
        <Select value={filterRole} onValueChange={setFilterRole}>
          <SelectTrigger className="h-8 text-sm w-[150px] border-border-strong">
            <SelectValue placeholder="Rôle" />
          </SelectTrigger>
          <SelectContent>
            {ROLE_OPTIONS.map((o) => <SelectItem key={o.value || '_'} value={o.value || 'all'}>{o.label}</SelectItem>)}
          </SelectContent>
        </Select>
        {user?.role === 'super_admin' && (
          <Select value={filterCommune} onValueChange={setFilterCommune}>
            <SelectTrigger className="h-8 text-sm w-[165px] border-border-strong">
              <SelectValue placeholder="Commune" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Toutes communes</SelectItem>
              {communes.map((c) => <SelectItem key={c.id} value={String(c.id)}>{c.name}</SelectItem>)}
            </SelectContent>
          </Select>
        )}
        <Select value={filterStatus} onValueChange={setFilterStatus}>
          <SelectTrigger className="h-8 text-sm w-[130px] border-border-strong">
            <SelectValue placeholder="Statut" />
          </SelectTrigger>
          <SelectContent>
            {STATUS_OPTIONS.map((o) => <SelectItem key={o.value || '_s'} value={o.value || 'all'}>{o.label}</SelectItem>)}
          </SelectContent>
        </Select>
      </div>

      {/* Tableau */}
      <div className="bg-white border border-border-strong rounded-lg shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm border-collapse">
            <thead>
              <tr style={{ background: '#f8fafc' }} className="border-b border-border-strong">
                {['Nom', 'Rôle', 'Commune', 'Statut', 'Disponibilité', 'Dernière connexion', 'Actions'].map((h) => (
                  <th
                    key={h}
                    className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-text-400 whitespace-nowrap"
                  >
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i} className="border-b border-border-subtle">
                    {[...Array(7)].map((_, j) => (
                      <td key={j} className="px-4 py-3">
                        <Skeleton className="h-4 rounded" />
                      </td>
                    ))}
                  </tr>
                ))
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-12 text-center text-sm text-text-400">
                    Aucun agent trouvé
                  </td>
                </tr>
              ) : (
                filteredUsers.map((ru) => {
                  const rb = ROLE_BADGES[ru.role] || ROLE_BADGES.agent;
                  const communeName = communes.find((c) => c.id === ru.commune)?.name || '—';
                  const isAgent = ru.role === 'agent';
                  const busyBreak = busyId === ru.id + '_break';
                  const busyAbs   = busyId === ru.id + '_abs';

                  return (
                    <tr key={ru.id} className="border-b border-border-subtle hover:bg-layer-2 transition-colors">
                      {/* Nom */}
                      <td className="px-4 py-3 whitespace-nowrap">
                        <div className="flex items-center gap-2.5">
                          <Avatar name={ru.full_name} />
                          <div>
                            <p className="font-medium text-text-200 text-sm leading-tight">{ru.full_name}</p>
                            <p className="text-[11px] text-text-400 leading-tight">{ru.email}</p>
                          </div>
                        </div>
                      </td>

                      {/* Rôle */}
                      <td className="px-4 py-3 whitespace-nowrap">
                        <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${rb.cls}`}>{rb.label}</span>
                      </td>

                      {/* Commune */}
                      <td className="px-4 py-3 text-text-300 whitespace-nowrap text-xs">{communeName}</td>

                      {/* Statut */}
                      <td className="px-4 py-3 whitespace-nowrap">
                        <span
                          className={`flex items-center gap-1 w-fit px-2 py-0.5 rounded-full text-xs font-semibold ${
                            ru.is_active ? 'bg-emerald-100 text-emerald-700' : 'bg-layer-3 text-text-400'
                          }`}
                        >
                          <span className={`w-1.5 h-1.5 rounded-full ${ru.is_active ? 'bg-emerald-500' : 'bg-slate-400'}`} />
                          {ru.is_active ? 'Actif' : 'Inactif'}
                        </span>
                      </td>

                      {/* Disponibilité */}
                      <td className="px-4 py-3 whitespace-nowrap">
                        <DspBadge u={ru} />
                      </td>

                      {/* Dernière connexion */}
                      <td className="px-4 py-3 text-[11px] text-text-400 whitespace-nowrap">
                        {formatDate(ru.last_login)}
                      </td>

                      {/* Actions */}
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-1">
                          {/* ☕ Pause */}
                          {canManage && isAgent && (
                            <Button
                              variant="ghost"
                              size="sm"
                              disabled={!!busyId}
                              onClick={() => handleBreak(ru)}
                              title={ru.is_on_break ? 'Terminer la pause' : 'Mettre en pause'}
                              className={`h-7 w-7 p-0 ${ru.is_on_break ? 'text-orange-600 bg-orange-50 hover:bg-orange-100' : 'text-text-400 hover:text-text-200 hover:bg-layer-3'}`}
                            >
                              {busyBreak ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Coffee className="h-3.5 w-3.5" />}
                            </Button>
                          )}

                          {/* ⏻ Absence */}
                          {canManage && isAgent && (
                            <Button
                              variant="ghost"
                              size="sm"
                              disabled={!!busyId}
                              onClick={() => handleAbsence(ru)}
                              title={ru.is_dispatch_eligible ? 'Mettre en absence' : 'Réactiver'}
                              className={`h-7 w-7 p-0 ${!ru.is_dispatch_eligible ? 'text-red-600 bg-red-50 hover:bg-red-100' : 'text-text-400 hover:text-text-200 hover:bg-layer-3'}`}
                            >
                              {busyAbs ? (
                                <Loader2 className="h-3.5 w-3.5 animate-spin" />
                              ) : !ru.is_dispatch_eligible ? (
                                <Power className="h-3.5 w-3.5" />
                              ) : (
                                <PowerOff className="h-3.5 w-3.5" />
                              )}
                            </Button>
                          )}

                          {/* 📄 Fiche */}
                          {user.id !== ru.id &&
                            (user.role === 'super_admin' ||
                              (['civil_admin_supervisor', 'civil_admin'].includes(user.role) && isAgent)) && (
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => { setSelAgent(ru); setNewPwd(''); setDetailsOpen(true); }}
                                title="Fiche de l'agent"
                                className="h-7 w-7 p-0 text-text-400 hover:text-blue-600 hover:bg-blue-50"
                              >
                                <FileText className="h-3.5 w-3.5" />
                              </Button>
                            )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Footer */}
        {!loading && filteredUsers.length > 0 && (
          <div className="px-4 py-2 border-t border-border-subtle bg-layer-2 text-[11px] text-text-400">
            {filteredUsers.length} utilisateur{filteredUsers.length > 1 ? 's' : ''}
          </div>
        )}
      </div>

      {/* ── Dialog : Créer un agent ── */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Nouvel agent</DialogTitle>
            <DialogDescription>Créer un nouveau compte utilisateur</DialogDescription>
          </DialogHeader>
          <div className="grid grid-cols-2 gap-4 pt-1">
            <div className="col-span-2 space-y-1.5">
              <Label>Nom complet *</Label>
              <Input value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} placeholder="Awa Sall" />
              {errors.full_name && <p className="text-xs text-red-500">{errors.full_name}</p>}
            </div>
            <div className="space-y-1.5">
              <Label>Email *</Label>
              <Input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} placeholder="a.sall@tc.sn" />
              {errors.email && <p className="text-xs text-red-500">{errors.email}</p>}
            </div>
            <div className="space-y-1.5">
              <Label>Téléphone</Label>
              <Input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} placeholder="771234567" />
            </div>
            <div className="space-y-1.5">
              <Label>Rôle *</Label>
              <Select value={form.role} onValueChange={(v) => setForm({ ...form, role: v })}>
                <SelectTrigger><SelectValue placeholder="Rôle" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="agent">Agent Civil</SelectItem>
                  {user?.role === 'super_admin' && (
                    <>
                      <SelectItem value="civil_admin">Admin Civil</SelectItem>
                      <SelectItem value="civil_admin_supervisor">Superviseur</SelectItem>
                    </>
                  )}
                </SelectContent>
              </Select>
              {errors.role && <p className="text-xs text-red-500">{errors.role}</p>}
            </div>
            <div className="space-y-1.5">
              <Label>Commune *</Label>
              <Select value={form.commune} onValueChange={(v) => setForm({ ...form, commune: v })}>
                <SelectTrigger><SelectValue placeholder="Commune" /></SelectTrigger>
                <SelectContent>
                  {availableCommunes.map((c) => <SelectItem key={c.id} value={String(c.id)}>{c.name}</SelectItem>)}
                </SelectContent>
              </Select>
              {errors.commune && <p className="text-xs text-red-500">{errors.commune}</p>}
            </div>
            <div className="col-span-2 space-y-1.5">
              <Label>Mot de passe *</Label>
              <Input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} placeholder="Min. 6 caractères" />
              {errors.password && <p className="text-xs text-red-500">{errors.password}</p>}
            </div>
          </div>
          <DialogFooter className="pt-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Annuler</Button>
            <Button onClick={handleSubmit} disabled={saving}>
              {saving && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              Créer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* ── Dialog : Fiche agent ── */}
      <Dialog open={detailsOpen} onOpenChange={setDetailsOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Fiche agent</DialogTitle>
            <DialogDescription>Informations et gestion du compte</DialogDescription>
          </DialogHeader>
          {selAgent && (
            <div className="space-y-5 pt-1">
              <div className="flex items-center gap-3">
                <Avatar name={selAgent.full_name} />
                <div>
                  <p className="font-semibold text-text-200">{selAgent.full_name}</p>
                  <p className="text-xs text-text-400">{selAgent.email}</p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3 text-sm border-t pt-4">
                <div>
                  <p className="text-[10px] text-text-400 uppercase tracking-wide mb-0.5">Téléphone</p>
                  <p className="font-medium text-text-200">{selAgent.phone || '—'}</p>
                </div>
                <div>
                  <p className="text-[10px] text-text-400 uppercase tracking-wide mb-0.5">Commune</p>
                  <p className="font-medium text-text-200">{communes.find((c) => c.id === selAgent.commune)?.name || '—'}</p>
                </div>
                <div>
                  <p className="text-[10px] text-text-400 uppercase tracking-wide mb-0.5">Disponibilité</p>
                  <DspBadge u={selAgent} />
                </div>
                <div>
                  <p className="text-[10px] text-text-400 uppercase tracking-wide mb-0.5">Statut</p>
                  <span className={`text-sm font-semibold ${selAgent.is_active ? 'text-emerald-600' : 'text-text-400'}`}>
                    {selAgent.is_active ? 'Actif' : 'Inactif'}
                  </span>
                </div>
              </div>
              <div className="border-t pt-4 space-y-2">
                <p className="text-sm font-semibold text-text-200">Changer le mot de passe</p>
                <div className="flex gap-2">
                  <Input type="password" placeholder="Nouveau mot de passe" value={newPwd} onChange={(e) => setNewPwd(e.target.value)} />
                  <Button onClick={handleChangePwd} disabled={changingPwd || !newPwd} className="shrink-0">
                    {changingPwd && <Loader2 className="h-4 w-4 mr-1.5 animate-spin" />}
                    Modifier
                  </Button>
                </div>
              </div>
              <div className="border-t pt-4">
                <Button variant="destructive" className="w-full" onClick={() => handleDelete(selAgent.id, selAgent.full_name)}>
                  <Trash2 className="h-4 w-4 mr-2" />
                  Supprimer l'agent
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
