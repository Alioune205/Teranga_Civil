import { useState, useEffect, useMemo } from 'react';
import { getAuditLogs } from '@/api/auditLogs';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { toast } from '@/components/ui/use-toast';
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import {
  Search, RotateCcw, ChevronLeft, ChevronRight,
  Copy, LogIn, LogOut, Eye, Plus, Edit, Trash, AlertCircle, Bot, User, HelpCircle, Activity, TrendingUp, Users
} from 'lucide-react';

const getActionBadge = (action, status) => {
  if (status === 'FAILURE' || status === 'ERROR') {
    return { label: 'Erreur', className: 'bg-white text-[#EF4444] border border-[#EF4444]', icon: AlertCircle };
  }
  switch (action) {
    case 'LOGIN': return { label: 'Connexion', className: 'bg-blue-50 text-[#1D4ED8] border-blue-200', icon: LogIn };
    case 'LOGOUT': return { label: 'Déconnexion', className: 'bg-layer-3 text-text-300 border-border-strong', icon: LogOut };
    case 'CREATE': return { label: 'Création', className: 'bg-[#10B981] text-white border-[#10B981]', icon: Plus };
    case 'UPDATE': return { label: 'Modification', className: 'bg-[#F59E0B] text-white border-[#F59E0B]', icon: Edit };
    case 'DELETE': return { label: 'Suppression', className: 'bg-[#EF4444] text-white border-[#EF4444]', icon: Trash };
    default: return { label: 'Consultation', className: 'bg-layer-3 text-text-300 border-border-strong', icon: Eye };
  }
};

const getReadableDetail = (log) => {
  if (!log.details || typeof log.details !== 'object') return 'Action sur la ressource';
  const { path, method } = log.details;
  if (!path || !method) return 'Action sur la ressource';
  
  if (path.includes('/auth/login') && method === 'POST') return 'Tentative de connexion';
  if (path.includes('/auth/logout') && method === 'POST') return 'Déconnexion';
  if (path.includes('/auth/refresh') && method === 'POST') return 'Renouvellement de session';
  if (path.includes('/ai/') && path.includes('/chat') && method === 'POST') return 'Requête IA';
  
  return `Action sur [${log.resource_type || 'ressource'}]`;
};

const ACTOR_OPTIONS = [
  { value: 'all', label: 'Tous' },
  { value: 'USER', label: 'Utilisateurs' },
  { value: 'SYSTEM', label: 'Système' },
  { value: 'ANONYMOUS', label: 'Anonymes' },
];

const RESULT_OPTIONS = [
  { value: 'all', label: 'Tous' },
  { value: 'SUCCESS', label: 'Succès' },
  { value: 'FAILURE', label: 'Échec' },
  { value: 'ERROR', label: 'Erreur' },
];

const RESOURCE_OPTIONS = [
  { value: 'all', label: 'Toutes' },
  { value: 'auth', label: 'Authentification' },
  { value: 'dossiers', label: 'Dossiers' },
  { value: 'communes', label: 'Communes' },
  { value: 'agents', label: 'Agents' },
  { value: 'ai', label: 'IA' },
];

export default function AuditLogs() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [userTypeFilter, setUserTypeFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [resourceFilter, setResourceFilter] = useState('all');
  const [suspectOnly, setSuspectOnly] = useState(false);
  const [userSearch, setUserSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const pageSize = 20;

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const params = { page, page_size: pageSize };
      if (dateFrom) params.date_from = dateFrom;
      if (dateTo) params.date_to = dateTo;
      if (userSearch) params.search = userSearch;
      if (userTypeFilter !== 'all') params.user_type = userTypeFilter;
      if (statusFilter !== 'all') params.status = statusFilter;
      if (resourceFilter !== 'all') params.resource_type = resourceFilter;
      if (suspectOnly) params.suspect = 'true';

      const data = await getAuditLogs(params);
      
      if (Array.isArray(data)) {
        setLogs(data);
        setTotalCount(data.length);
      } else {
        setLogs(data.results || []);
        setTotalCount(data.count || 0);
      }
    } catch (error) {
      toast({ title: 'Erreur', description: 'Impossible de charger les logs.', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [page, dateFrom, dateTo, userSearch, userTypeFilter, statusFilter, resourceFilter, suspectOnly]);

  const handleReset = () => {
    setDateFrom('');
    setDateTo('');
    setUserSearch('');
    setUserTypeFilter('all');
    setStatusFilter('all');
    setResourceFilter('all');
    setSuspectOnly(false);
    setPage(1);
  };

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    toast({ title: 'Copié', description: 'ID copié dans le presse-papier.', variant: 'success' });
  };

  const formatTimestamp = (ts) => {
    if (!ts) return '—';
    return new Date(ts).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit' });
  };

  const totalPages = Math.ceil(totalCount / pageSize);

  // Metrics (approximées sur la vue actuelle pour la démo)
  const metrics = useMemo(() => {
    const today = new Date().toISOString().split('T')[0];
    const todayLogs = logs.filter(l => l.created_at?.startsWith(today)).length;
    const uniqueActors = new Set(logs.map(l => l.user_email || l.user_type)).size;
    const suspectCount = logs.filter(l => l.status === 'ERROR' || l.status === 'FAILURE' || l.user_type === 'ANONYMOUS').length;
    return { todayLogs, uniqueActors, suspectCount };
  }, [logs]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-text-100">Journal d'audit</h1>
        <p className="text-sm text-text-400 mt-1">
          Traçabilité et analyse sécurisée de l'activité
        </p>
      </div>

      {/* 3 Metric Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="p-4 flex items-center gap-4 cursor-pointer hover:border-primary/50 transition-colors" onClick={() => { setDateFrom(new Date().toISOString().split('T')[0]); setPage(1); }}>
          <div className="w-12 h-12 rounded-full bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center text-blue-600 dark:text-blue-400">
            <Activity className="h-6 w-6" />
          </div>
          <div>
            <p className="text-sm text-text-400 font-medium">Événements aujourd'hui</p>
            <div className="flex items-center gap-2">
              <h3 className="text-2xl font-bold">{metrics.todayLogs}</h3>
              <span className="text-xs text-emerald-500 flex items-center"><TrendingUp className="h-3 w-3 mr-1" /> Actif</span>
            </div>
          </div>
        </Card>
        <Card className="p-4 flex items-center gap-4 cursor-pointer hover:border-primary/50 transition-colors" onClick={() => { setUserTypeFilter('USER'); setPage(1); }}>
          <div className="w-12 h-12 rounded-full bg-indigo-50 dark:bg-indigo-900/20 flex items-center justify-center text-indigo-600 dark:text-indigo-400">
            <Users className="h-6 w-6" />
          </div>
          <div>
            <p className="text-sm text-text-400 font-medium">Acteurs actifs</p>
            <h3 className="text-2xl font-bold">{metrics.uniqueActors}</h3>
          </div>
        </Card>
        <Card className="p-4 flex items-center gap-4 cursor-pointer hover:border-error/50 transition-colors" onClick={() => { setSuspectOnly(true); setPage(1); }}>
          <div className="w-12 h-12 rounded-full bg-red-50 dark:bg-red-900/20 flex items-center justify-center text-red-600 dark:text-red-400">
            <AlertCircle className="h-6 w-6" />
          </div>
          <div>
            <p className="text-sm text-text-400 font-medium">Événements suspects</p>
            <h3 className="text-2xl font-bold text-red-600 dark:text-red-400">{metrics.suspectCount}</h3>
          </div>
        </Card>
      </div>

      {/* Filtres */}
      <Card className="p-4 border-border-subtle">
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative flex-1 min-w-[150px]">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-text-400" />
            <Input placeholder="Chercher utilisateur..." value={userSearch} onChange={(e) => { setUserSearch(e.target.value); setPage(1); }} className="pl-9" />
          </div>
          <Select value={userTypeFilter} onValueChange={(val) => { setUserTypeFilter(val); setPage(1); }}>
            <SelectTrigger className="w-[140px]"><SelectValue placeholder="Acteur" /></SelectTrigger>
            <SelectContent>
              {ACTOR_OPTIONS.map(opt => <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>)}
            </SelectContent>
          </Select>
          <Select value={statusFilter} onValueChange={(val) => { setStatusFilter(val); setPage(1); }}>
            <SelectTrigger className="w-[120px]"><SelectValue placeholder="Résultat" /></SelectTrigger>
            <SelectContent>
              {RESULT_OPTIONS.map(opt => <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>)}
            </SelectContent>
          </Select>
          <Select value={resourceFilter} onValueChange={(val) => { setResourceFilter(val); setPage(1); }}>
            <SelectTrigger className="w-[140px]"><SelectValue placeholder="Ressource" /></SelectTrigger>
            <SelectContent>
              {RESOURCE_OPTIONS.map(opt => <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>)}
            </SelectContent>
          </Select>
          <div className="flex items-center gap-2 bg-layer-2 px-3 py-1.5 rounded-md border border-border-strong">
            <input 
              type="checkbox" 
              id="suspect" 
              className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary cursor-pointer"
              checked={suspectOnly} 
              onChange={(e) => { setSuspectOnly(e.target.checked); setPage(1); }} 
            />
            <Label htmlFor="suspect" className="text-sm font-medium cursor-pointer">Suspects uniquement</Label>
          </div>
          <div className="flex items-center gap-2">
            <Input type="date" value={dateFrom} onChange={(e) => { setDateFrom(e.target.value); setPage(1); }} className="w-[130px]" />
            <Input type="date" value={dateTo} onChange={(e) => { setDateTo(e.target.value); setPage(1); }} className="w-[130px]" />
          </div>
          <Button variant="outline" size="icon" onClick={handleReset} title="Réinitialiser">
            <RotateCcw className="h-4 w-4" />
          </Button>
        </div>
      </Card>

      {/* Table */}
      <Card className="table-container overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-border-subtle bg-layer-2 dark:bg-slate-900/50">
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase">Horodatage</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase">Utilisateur</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase">Action</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase">Ressource</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase">Détails</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i} className="border-b border-border-subtle dark:border-slate-800 h-[48px]">
                    {[...Array(5)].map((_, j) => (
                      <td key={j} className="px-4 align-middle"><Skeleton className="h-4 w-full" /></td>
                    ))}
                  </tr>
                ))
              ) : logs.length > 0 ? (
                logs.map((log, index) => {
                  const actionData = getActionBadge(log.action, log.status);
                  const Icon = actionData.icon;
                  const isEven = index % 2 === 0;
                  
                  let ActorIcon = User;
                  let actorBg = 'bg-layer-3 text-text-300';
                  let actorName = log.user_name || log.user_email || '—';
                  
                  if (log.user_type === 'SYSTEM') {
                    ActorIcon = Bot;
                    actorBg = 'bg-border-strong text-text-200';
                    actorName = 'Système';
                  } else if (log.user_type === 'ANONYMOUS') {
                    ActorIcon = HelpCircle;
                    actorBg = 'bg-amber-100 text-amber-700 border border-amber-300';
                    actorName = 'Anonyme';
                  } else if (!log.user_name && !log.user_email) {
                    ActorIcon = AlertCircle;
                    actorBg = 'bg-red-100 text-red-700 border border-red-300';
                    actorName = 'Erreur résolution';
                  }

                  return (
                    <tr key={log.id} className={`border-b border-border-subtle dark:border-slate-800 transition-colors h-[48px] overflow-hidden ${isEven ? 'bg-transparent' : 'bg-layer-2 dark:bg-slate-900/30'} hover:bg-layer-2 dark:hover:bg-slate-800`}>
                      <td className="px-4 align-middle whitespace-nowrap">
                        <span className="text-[13px] text-text-400 font-mono">
                          {formatTimestamp(log.created_at)}
                        </span>
                      </td>
                      <td className="px-4 align-middle whitespace-nowrap" title={log.user_email || log.user_type}>
                        <div className="flex items-center gap-2">
                          <div className={`w-6 h-6 rounded-full flex items-center justify-center ${actorBg}`}>
                            <ActorIcon className="h-3 w-3" />
                          </div>
                          <span className="text-[13px] font-medium text-text-300 truncate max-w-[150px]">{actorName}</span>
                        </div>
                      </td>
                      <td className="px-4 align-middle whitespace-nowrap">
                        <Badge variant="outline" className={`${actionData.className} text-[11px] font-medium flex items-center w-fit gap-1.5 px-2 py-0.5`}>
                          <Icon className="h-3 w-3" />
                          {actionData.label}
                        </Badge>
                      </td>
                      <td className="px-4 align-middle whitespace-nowrap">
                        <div className="flex items-center gap-2 text-[13px]">
                          <span className="text-text-300 font-medium capitalize">{log.resource_type || '—'}</span>
                          {log.resource_id && (
                            <div className="flex items-center gap-1 group">
                              <span className="text-text-400 font-mono text-[11px] bg-layer-3 px-1.5 py-0.5 rounded cursor-help" title={log.resource_id}>
                                {log.resource_id.substring(0, 8)}…
                              </span>
                              <button onClick={() => copyToClipboard(log.resource_id)} className="opacity-0 group-hover:opacity-100 text-text-400 hover:text-primary transition-opacity" title="Copier l'UUID complet">
                                <Copy className="h-3 w-3" />
                              </button>
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="px-4 align-middle">
                        <p className="text-[13px] text-text-300 dark:text-slate-400 truncate max-w-[250px]" title={typeof log.details === 'object' ? JSON.stringify(log.details) : 'Aucun détail JSON'}>
                          {getReadableDetail(log)}
                        </p>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={5} className="px-4 py-12 text-center text-text-400">
                    Aucun log trouvé
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-border-subtle">
            <p className="text-sm text-text-400">Page {page} sur {totalPages}</p>
            <div className="flex items-center gap-2">
              <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage(page - 1)}><ChevronLeft className="h-4 w-4" /></Button>
              <Button variant="outline" size="sm" disabled={page >= totalPages} onClick={() => setPage(page + 1)}><ChevronRight className="h-4 w-4" /></Button>
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}
