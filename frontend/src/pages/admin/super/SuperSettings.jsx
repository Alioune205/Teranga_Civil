import React, { useState, useEffect } from 'react';
import {
  Settings, ShieldAlert, Users, Database, Globe, Server,
  Building2, RefreshCw, AlertTriangle, CheckCircle2,
  Shield, Clock, HardDrive, Cpu, Wifi, Eye, EyeOff,
  Plus, ToggleLeft, ToggleRight, KeyRound, Loader2, Copy, Info,
  Lock,
} from 'lucide-react';
import api from '@/api/axiosClient';
import { useToast } from '@/components/ui/use-toast';
import WizardNouvelleMairie from '@/components/superadmin/WizardNouvelleMairie';

// ─── Helpers ─────────────────────────────────────────────────────────────────
const Badge = ({ children, color = 'slate' }) => {
  const colors = {
    green: 'bg-emerald-100 text-emerald-700',
    red: 'bg-red-100 text-red-700',
    blue: 'bg-blue-100 text-blue-700',
    amber: 'bg-amber-100 text-amber-700',
    slate: 'bg-layer-3 text-text-300',
    purple: 'bg-purple-100 text-purple-700',
  };
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold ${colors[color]}`}>
      {children}
    </span>
  );
};

const InfoRow = ({ label, value, mono = false }) => (
  <div className="flex justify-between items-center py-3 border-b border-border-subtle last:border-0">
    <span className="text-sm text-text-400">{label}</span>
    <span className={`text-sm font-semibold text-text-200 ${mono ? 'font-mono' : ''}`}>{value ?? '—'}</span>
  </div>
);

const SectionCard = ({ title, icon: Icon, children, className = '' }) => (
  <div className={`bg-white rounded-2xl border border-border-subtle shadow-sm p-6 ${className}`}>
    {title && (
      <div className="flex items-center gap-3 mb-5">
        {Icon && <div className="bg-primary/10 text-primary p-2 rounded-xl"><Icon className="w-5 h-5" /></div>}
        <h2 className="text-base font-bold text-text-200">{title}</h2>
      </div>
    )}
    {children}
  </div>
);

// ─── Onglet 1 : Général ───────────────────────────────────────────────────────
function OngletGeneral() {
  const [info, setInfo] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/api/system/info/')
      .then(res => setInfo(res.data))
      .catch(err => console.error('Erreur chargement info système:', err))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!info) {
    return (
      <div className="text-center py-20 text-text-400">
        <Server className="w-12 h-12 mx-auto mb-3 text-slate-300" />
        <p>Impossible de charger les informations système.</p>
      </div>
    );
  }

  const { platform, database, system_stats, config } = info;

  const diskPercent = system_stats?.disk?.percent_used ?? 0;
  const diskColor = diskPercent > 85 ? 'bg-red-500' : diskPercent > 70 ? 'bg-amber-500' : 'bg-emerald-500';

  return (
    <div className="space-y-6">
      {/* Infos plateforme */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <SectionCard title="Informations de la Plateforme" icon={Globe}>
          <InfoRow label="Nom" value={platform?.name} />
          <InfoRow label="Version" value={platform?.version_label} />
          <InfoRow label="Environnement" value={
            <Badge color={platform?.debug_mode ? 'amber' : 'green'}>
              {platform?.environment}
            </Badge>
          } />
          <InfoRow label="Base de données" value={
            <Badge color="blue">{database?.engine}</Badge>
          } />
          <InfoRow label="Taille DB" value={database?.size} mono />
        </SectionCard>

        <SectionCard title="Statistiques Système" icon={Database}>
          <InfoRow label="Communes enregistrées" value={
            <span className="text-primary font-bold text-lg">{system_stats?.total_communes}</span>
          } />
          <InfoRow label="Utilisateurs totaux" value={
            <span className="font-bold text-text-200 text-lg">{system_stats?.total_users}</span>
          } />
          <InfoRow label="Dossiers traités" value={
            <span className="font-bold text-text-200 text-lg">{system_stats?.total_dossiers}</span>
          } />
          <InfoRow label="Uptime serveur" value={system_stats?.uptime} />
        </SectionCard>
      </div>

      {/* Espace disque */}
      {system_stats?.disk && !system_stats.disk.error && (
        <SectionCard title="Espace de Stockage" icon={HardDrive}>
          <div className="flex justify-between text-sm text-text-400 mb-2">
            <span>Utilisé : <span className="font-semibold text-text-200">{system_stats.disk.used_gb} GB</span></span>
            <span>Total : <span className="font-semibold text-text-200">{system_stats.disk.total_gb} GB</span></span>
          </div>
          <div className="w-full bg-layer-3 rounded-full h-3 mb-2">
            <div
              className={`${diskColor} h-3 rounded-full transition-all duration-700`}
              style={{ width: `${diskPercent}%` }}
            />
          </div>
          <div className="flex justify-between text-xs text-text-400">
            <span>{diskPercent}% utilisé</span>
            <span>{system_stats.disk.free_gb} GB libres</span>
          </div>
        </SectionCard>
      )}

      {/* Configuration */}
      <SectionCard title="Configuration (Lecture seule)" icon={Settings}>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8">
          <div>
            <InfoRow label="Mode Debug" value={
              <Badge color={config?.debug_mode ? 'amber' : 'green'}>
                {config?.debug_mode ? 'Activé' : 'Désactivé'}
              </Badge>
            } />
            <InfoRow label="Langue" value={config?.language_code} mono />
            <InfoRow label="Fuseau horaire" value={config?.time_zone} mono />
          </div>
          <div>
            <InfoRow label="CORS (All Origins)" value={
              <Badge color={config?.cors_allow_all ? 'amber' : 'green'}>
                {config?.cors_allow_all ? 'Ouvert (DEV)' : 'Restreint'}
              </Badge>
            } />
            <InfoRow label="Hosts autorisés" value={
              <code className="text-xs bg-layer-3 px-2 py-1 rounded">
                {(config?.allowed_hosts || []).join(', ')}
              </code>
            } />
          </div>
        </div>
        {config?.cors_origins?.length > 0 && config.cors_origins[0] !== '*' && (
          <div className="mt-4 bg-layer-2 rounded-lg p-3">
            <p className="text-xs text-text-400 font-medium mb-2">Origines CORS autorisées :</p>
            <div className="flex flex-wrap gap-2">
              {config.cors_origins.map((origin, i) => (
                <code key={i} className="text-xs bg-white border rounded px-2 py-1 text-text-200">{origin}</code>
              ))}
            </div>
          </div>
        )}
      </SectionCard>

      <div className="bg-indigo-50 border border-indigo-100 rounded-xl p-4 flex gap-3 items-start">
        <Info className="w-5 h-5 text-indigo-500 flex-shrink-0 mt-0.5" />
        <div className="text-sm text-indigo-700">
          <p className="font-semibold">Teranga Civil — Hackathon APD Promotion 6</p>
          <p className="text-indigo-500 mt-1">ISEP Dakar 2026 · Digitalisation de l'État Civil Sénégalais</p>
        </div>
      </div>
    </div>
  );
}

// ─── Onglet 2 : Sécurité ──────────────────────────────────────────────────────
function OngletSecurite() {
  const [passationUsers, setPassationUsers] = useState([]);
  const [passationId, setPassationId] = useState('');
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loadingPassation, setLoadingPassation] = useState(false);
  const [sessions, setSessions] = useState([]);
  const { toast } = useToast();

  useEffect(() => {
    // Charger les utilisateurs éligibles à la passation
    api.get('/api/users/?role=civil_admin,super_admin,civil_admin_supervisor')
      .then(res => setPassationUsers(res.data?.data || res.data || []))
      .catch(err => console.error(err));

    // Charger les dernières sessions (audit logs)
    api.get('/api/dashboard/superadmin/activity/')
      .then(res => setSessions(res.data?.last_logins || []))
      .catch(() => {});
  }, []);

  const handlePassationConfirm = async () => {
    if (!confirmPassword) {
      toast({ title: 'Erreur', description: 'Veuillez entrer votre mot de passe.', variant: 'destructive' });
      return;
    }
    setLoadingPassation(true);
    try {
      await api.post('/api/dashboard/superadmin/passation/', {
        new_super_admin_id: passationId,
        current_password: confirmPassword,
      });
      toast({ title: 'Succès', description: 'Passation de service réussie. Déconnexion en cours...', variant: 'default' });
      setShowConfirmModal(false);
      setTimeout(() => { window.location.href = '/login'; }, 2000);
    } catch (error) {
      toast({ title: 'Erreur', description: error.response?.data?.error || 'Échec de la passation', variant: 'destructive' });
    } finally {
      setLoadingPassation(false);
    }
  };

  const roleLabel = (role) => {
    const labels = { super_admin: 'Super Admin', civil_admin: 'Admin Civil', civil_admin_supervisor: 'Superviseur', agent: 'Agent', citizen: 'Citoyen' };
    return labels[role] || role;
  };

  return (
    <div className="space-y-6">
      {/* Politique de sécurité */}
      <SectionCard title="Politique de Sécurité" icon={Shield}>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-emerald-50 border border-emerald-100 rounded-xl p-4 text-center">
            <CheckCircle2 className="w-7 h-7 text-emerald-500 mx-auto mb-2" />
            <p className="font-bold text-text-200 text-sm">Authentification JWT</p>
            <p className="text-xs text-text-400 mt-1">Tokens signés HS256</p>
          </div>
          <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 text-center">
            <Lock className="w-7 h-7 text-blue-500 mx-auto mb-2" />
            <p className="font-bold text-text-200 text-sm">Rôles RBAC</p>
            <p className="text-xs text-text-400 mt-1">Contrôle d'accès par rôle</p>
          </div>
          <div className="bg-amber-50 border border-amber-100 rounded-xl p-4 text-center">
            <Clock className="w-7 h-7 text-amber-500 mx-auto mb-2" />
            <p className="font-bold text-text-200 text-sm">Session 30 min</p>
            <p className="text-xs text-text-400 mt-1">Expiration automatique</p>
          </div>
        </div>
      </SectionCard>

      {/* Sessions actives */}
      {sessions.length > 0 && (
        <SectionCard title="Dernières Connexions" icon={Clock}>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-2 text-text-400 font-medium">Utilisateur</th>
                  <th className="text-left py-2 text-text-400 font-medium">Rôle</th>
                  <th className="text-left py-2 text-text-400 font-medium">Commune</th>
                  <th className="text-left py-2 text-text-400 font-medium">Dernière connexion</th>
                </tr>
              </thead>
              <tbody>
                {sessions.slice(0, 8).map((s, i) => (
                  <tr key={i} className="border-b border-border-subtle hover:bg-layer-2">
                    <td className="py-2 font-medium text-text-200">{s.first_name} {s.last_name}</td>
                    <td className="py-2">
                      <Badge color={s.role === 'super_admin' ? 'purple' : s.role === 'civil_admin_supervisor' ? 'blue' : 'slate'}>
                        {roleLabel(s.role)}
                      </Badge>
                    </td>
                    <td className="py-2 text-text-400">{s.commune__name || '—'}</td>
                    <td className="py-2 text-text-400 font-mono text-xs">
                      {s.last_login ? new Date(s.last_login).toLocaleString('fr-FR') : '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </SectionCard>
      )}

      {/* Zone dangereuse */}
      <div className="bg-red-50 rounded-2xl border border-red-200 p-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="bg-red-100 p-2 rounded-xl">
            <AlertTriangle className="w-5 h-5 text-red-600" />
          </div>
          <h2 className="text-base font-bold text-red-700">⚠️ Zone Dangereuse — Passation de Service</h2>
        </div>
        <p className="text-red-600 text-sm mb-6">
          Cette action transfère <strong>définitivement</strong> les droits Super Administrateur à un autre utilisateur.
          Votre compte perdra immédiatement tous ses privilèges et vous serez déconnecté.
        </p>

        <div className="flex flex-col sm:flex-row gap-4">
          <select
            value={passationId}
            onChange={(e) => setPassationId(e.target.value)}
            className="flex-1 border border-red-200 bg-white rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-red-400 focus:ring-1 focus:ring-red-400"
          >
            <option value="">Sélectionner le successeur...</option>
            {(Array.isArray(passationUsers) ? passationUsers : []).map(u => (
              <option key={u.id} value={u.id}>{u.first_name} {u.last_name} ({u.role})</option>
            ))}
          </select>
          <button
            disabled={!passationId}
            onClick={() => setShowConfirmModal(true)}
            className="px-5 py-2 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 transition-colors disabled:opacity-40 disabled:cursor-not-allowed whitespace-nowrap flex items-center gap-2"
          >
            <ShieldAlert className="w-4 h-4" />
            Transférer les privilèges
          </button>
        </div>
      </div>

      {/* Modal de confirmation double */}
      {showConfirmModal && (
        <div className="fixed inset-0 z-[200] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
            <div className="text-center mb-6">
              <div className="bg-red-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <AlertTriangle className="w-8 h-8 text-red-600" />
              </div>
              <h3 className="text-xl font-bold text-text-200">Confirmation requise</h3>
              <p className="text-text-400 text-sm mt-2">
                Confirmez la passation en entrant votre mot de passe actuel.
                Cette action est <strong>irréversible</strong>.
              </p>
            </div>

            <div className="mb-6">
              <label className="block text-sm font-medium text-text-200 mb-2">
                <KeyRound className="w-4 h-4 inline mr-1" />
                Votre mot de passe actuel
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={e => setConfirmPassword(e.target.value)}
                  placeholder="Entrez votre mot de passe..."
                  className="w-full border border-border-strong rounded-lg px-3 py-2 pr-10 text-sm focus:outline-none focus:ring-2 focus:ring-red-400"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-text-400"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => { setShowConfirmModal(false); setConfirmPassword(''); }}
                className="flex-1 px-4 py-2 border border-border-strong rounded-lg text-text-300 font-medium hover:bg-layer-2"
              >
                Annuler
              </button>
              <button
                onClick={handlePassationConfirm}
                disabled={loadingPassation || !confirmPassword}
                className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 disabled:opacity-40 flex items-center justify-center gap-2"
              >
                {loadingPassation && <Loader2 className="w-4 h-4 animate-spin" />}
                Confirmer la passation
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Onglet 3 : Administrateurs ───────────────────────────────────────────────
function OngletAdministrateurs() {
  const [communes, setCommunes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showWizard, setShowWizard] = useState(false);
  const [togglingId, setTogglingId] = useState(null);
  const [search, setSearch] = useState('');
  const { toast } = useToast();

  const fetchCommunes = async () => {
    setLoading(true);
    try {
      const res = await api.get('/api/dashboard/superadmin/communes/manage/');
      setCommunes(res.data || []);
    } catch (err) {
      console.error('Erreur chargement communes:', err);
      toast({ title: 'Erreur', description: 'Impossible de charger la liste des mairies.', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchCommunes(); }, []);

  const handleToggle = async (commune) => {
    setTogglingId(commune.id);
    try {
      const res = await api.patch(`/api/dashboard/superadmin/communes/${commune.id}/toggle-status/`);
      toast({ title: res.data.is_active ? 'Commune activée' : 'Commune désactivée', description: res.data.message });
      fetchCommunes();
    } catch (err) {
      toast({ title: 'Erreur', description: err.response?.data?.error || 'Échec de l\'opération', variant: 'destructive' });
    } finally {
      setTogglingId(null);
    }
  };

  const handleResetPassword = async (adminEmail) => {
    if (!window.confirm(`Réinitialiser le mot de passe de ${adminEmail} ?`)) return;
    try {
      await api.post('/api/users/reset-password/', { email: adminEmail });
      toast({ title: 'Succès', description: `Un email de réinitialisation a été envoyé à ${adminEmail}.` });
    } catch {
      toast({ title: 'Info', description: 'La réinitialisation sera envoyée par email.', variant: 'default' });
    }
  };

  const filteredCommunes = communes.filter(c =>
    !search || c.name?.toLowerCase().includes(search.toLowerCase()) ||
    c.region?.toLowerCase().includes(search.toLowerCase())
  );

  const roleLabel = (role) => {
    const labels = { civil_admin: 'Admin RH', civil_admin_supervisor: 'Superviseur', super_admin: 'Super Admin' };
    return labels[role] || role;
  };
  const roleBadgeColor = (role) => {
    const colors = { civil_admin: 'blue', civil_admin_supervisor: 'purple', super_admin: 'red' };
    return colors[role] || 'slate';
  };

  return (
    <div className="space-y-6">
      {/* Header avec bouton */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-base font-bold text-text-200">Mairies enregistrées</h2>
          <p className="text-sm text-text-400">{communes.length} commune{communes.length > 1 ? 's' : ''} dans le système</p>
        </div>
        <div className="flex gap-3 w-full sm:w-auto">
          <input
            type="text"
            placeholder="Rechercher une commune..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="flex-1 sm:w-64 border border-border-strong rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30"
          />
          <button
            onClick={() => setShowWizard(true)}
            className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg font-medium hover:bg-primary/90 whitespace-nowrap shadow-md shadow-primary/20"
          >
            <Plus className="w-4 h-4" />
            Nouvelle Mairie
          </button>
        </div>
      </div>

      {/* Tableau */}
      <div className="bg-white rounded-2xl border border-border-subtle shadow-sm overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-primary" />
          </div>
        ) : filteredCommunes.length === 0 ? (
          <div className="text-center py-16 text-text-400">
            <Building2 className="w-12 h-12 mx-auto mb-3 text-slate-300" />
            <p className="font-medium">Aucune commune trouvée</p>
            <p className="text-sm mt-1">Utilisez "Nouvelle Mairie" pour en créer une.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-layer-2 border-b border-border-subtle">
                <tr>
                  <th className="text-left px-4 py-3 font-semibold text-text-300">Commune</th>
                  <th className="text-left px-4 py-3 font-semibold text-text-300">Région</th>
                  <th className="text-left px-4 py-3 font-semibold text-text-300">Département</th>
                  <th className="text-left px-4 py-3 font-semibold text-text-300">Administrateurs</th>
                  <th className="text-left px-4 py-3 font-semibold text-text-300">Statut</th>
                  <th className="text-right px-4 py-3 font-semibold text-text-300">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {filteredCommunes.map(commune => {
                  const supervisor = commune.admins?.find(a => a.role === 'civil_admin_supervisor');
                  const rh = commune.admins?.find(a => a.role === 'civil_admin');
                  const isToggling = togglingId === commune.id;
                  return (
                    <tr key={commune.id} className="hover:bg-layer-2 transition-colors">
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-3">
                          <div className="bg-primary/10 p-2 rounded-lg">
                            <Building2 className="w-4 h-4 text-primary" />
                          </div>
                          <div>
                            <p className="font-semibold text-text-200">{commune.name}</p>
                            <p className="text-xs text-text-400 font-mono">{commune.code}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-text-300">{commune.region || '—'}</td>
                      <td className="px-4 py-4 text-text-300">{commune.department || '—'}</td>
                      <td className="px-4 py-4">
                        {commune.admins?.length > 0 ? (
                          <div className="space-y-1">
                            {commune.admins.slice(0, 2).map(admin => (
                              <div key={admin.id} className="flex items-center gap-2">
                                <Badge color={roleBadgeColor(admin.role)}>{roleLabel(admin.role)}</Badge>
                                <span className="text-text-300 text-xs">{admin.first_name} {admin.last_name}</span>
                              </div>
                            ))}
                          </div>
                        ) : (
                          <span className="text-text-400 italic text-xs">Aucun administrateur</span>
                        )}
                      </td>
                      <td className="px-4 py-4">
                        <Badge color={commune.is_active ? 'green' : 'red'}>
                          {commune.is_active ? 'Active' : 'Désactivée'}
                        </Badge>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center justify-end gap-2">
                          {/* Toggle statut */}
                          <button
                            onClick={() => handleToggle(commune)}
                            disabled={isToggling}
                            title={commune.is_active ? 'Désactiver' : 'Activer'}
                            className={`p-2 rounded-lg transition-colors ${commune.is_active ? 'text-emerald-600 hover:bg-emerald-50' : 'text-text-400 hover:bg-layer-3'}`}
                          >
                            {isToggling
                              ? <Loader2 className="w-4 h-4 animate-spin" />
                              : commune.is_active ? <ToggleRight className="w-5 h-5" /> : <ToggleLeft className="w-5 h-5" />
                            }
                          </button>

                          {/* Réinitialiser MDP du supervisor */}
                          {supervisor && (
                            <button
                              onClick={() => handleResetPassword(supervisor.email)}
                              title="Réinitialiser mot de passe Admin"
                              className="p-2 rounded-lg text-amber-600 hover:bg-amber-50 transition-colors"
                            >
                              <KeyRound className="w-4 h-4" />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Wizard */}
      <WizardNouvelleMairie
        isOpen={showWizard}
        onClose={() => setShowWizard(false)}
        onSuccess={() => {
          setShowWizard(false);
          fetchCommunes();
        }}
      />
    </div>
  );
}

// ─── Composant principal ──────────────────────────────────────────────────────
export default function SuperSettings() {
  const [activeTab, setActiveTab] = useState('general');

  const tabs = [
    { id: 'general', label: 'Général', icon: Globe },
    { id: 'security', label: 'Sécurité', icon: ShieldAlert },
    { id: 'admins', label: 'Administrateurs', icon: Users },
  ];

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-2xl font-bold text-text-200">Paramètres Système</h1>
          <p className="text-text-400 mt-1">Configuration globale de Teranga Civil</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="bg-white rounded-xl shadow-sm border border-border-subtle p-1 flex gap-1">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex-1 flex items-center justify-center gap-2 py-3 px-4 rounded-lg font-medium text-sm transition-all ${
              activeTab === tab.id
                ? 'bg-primary text-white shadow-md'
                : 'text-text-400 hover:bg-layer-2 hover:text-text-200'
            }`}
          >
            <tab.icon className="w-4 h-4" />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Content */}
      <div>
        {activeTab === 'general' && <OngletGeneral />}
        {activeTab === 'security' && <OngletSecurite />}
        {activeTab === 'admins' && <OngletAdministrateurs />}
      </div>
    </div>
  );
}
