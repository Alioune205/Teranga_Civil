// src/components/dashboard/ActiviteRecente.jsx
import { useEffect, useState } from 'react';
import { getAuditLogs } from '@/api/auditLogs';
import { Loader2, Activity } from 'lucide-react';

const formatTimeAgo = (dateString) => {
  if (!dateString) return '';
  const diff = Math.floor((new Date() - new Date(dateString)) / 60000);
  if (diff < 1) return 'À l\'instant';
  if (diff < 60) return `Il y a ${diff} min`;
  const hours = Math.floor(diff / 60);
  if (hours < 24) return `Il y a ${hours} h`;
  const days = Math.floor(hours / 24);
  return `Il y a ${days} j`;
};

export function ActiviteRecente() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchLogs = async () => {
      try {
        const response = await getAuditLogs({ limit: 5 });
        setLogs(response.results || response.data || (Array.isArray(response) ? response : []));
      } catch (err) {
        console.error('Erreur ActiviteRecente', err);
      } finally {
        setLoading(false);
      }
    };

    fetchLogs();
  }, []);

  return (
    <div className="bg-layer-1 border border-border-strong rounded-xl p-5 shadow-sm lg:col-span-2 h-full flex flex-col">
      <div className="flex items-center gap-2 mb-4 shrink-0">
        <div className="h-8 w-8 rounded-lg bg-blue-50 dark:bg-blue-900/20 text-blue-600 flex items-center justify-center">
          <Activity className="h-4 w-4" />
        </div>
        <h3 className="text-sm font-bold text-text-100">Activité récente</h3>
      </div>

      <div className="space-y-4 flex-1 overflow-y-auto pr-2">
        {loading ? (
          <div className="flex justify-center py-4">
            <Loader2 className="h-5 w-5 animate-spin text-text-400" />
          </div>
        ) : logs.length === 0 ? (
          <p className="text-xs text-text-400 text-center py-4">Aucune activité récente.</p>
        ) : (
          logs.slice(0, 5).map((log) => {
            const actorName = log.actor_name || log.user?.first_name || log.user?.email || 'Système';
            const actionText = log.action || log.action_type || 'modifié';
            const target = log.target_reference || log.object_repr || 'un dossier';
            const date = log.created_at || log.timestamp;
            
            return (
              <div key={log.id || Math.random()} className="flex flex-col gap-1 text-sm border-b border-border-subtle pb-3 last:border-0 last:pb-0">
                <p className="text-text-300 leading-snug">
                  <span className="font-medium text-text-100">{actorName}</span>{' '}
                  <span className="text-text-400">{actionText.toLowerCase()}</span>{' '}
                  <strong className="font-medium text-text-200">{target}</strong>
                </p>
                <div className="flex items-center gap-1.5 text-[11px] text-text-400 uppercase tracking-wider font-medium">
                  <Activity className="h-3 w-3" />
                  {formatTimeAgo(date)}
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
