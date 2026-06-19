import React, { useState, useEffect } from 'react';
import { ShieldAlert, Activity, UserCheck, AlertTriangle } from 'lucide-react';
import api from '@/api/axiosClient';

export default function SuperAuditLog() {
  const [activity, setActivity] = useState(null);
  const [auditLogs, setAuditLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [actRes, logRes] = await Promise.all([
          api.get('/api/dashboard/superadmin/activity/'),
          api.get('/api/dashboard/superadmin/audit/')
        ]);
        setActivity(actRes.data);
        setAuditLogs(logRes.data);
      } catch (error) {
        console.error(error);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  if (loading) return <div className="p-8 text-center text-text-400">Chargement de l'audit...</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text-200">Sécurité & Audit</h1>
          <p className="text-sm text-text-400">Contrôle de l'activité du système</p>
        </div>
      </div>

      {/* Activity Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-5 rounded-2xl border border-border-subtle shadow-sm flex items-center space-x-4">
          <div className="p-3 rounded-xl bg-blue-50 text-blue-600">
            <Activity className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm text-text-400">Actions (Aujourd'hui)</p>
            <h3 className="text-2xl font-bold text-text-200">{activity?.actions_today || 0}</h3>
          </div>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-border-subtle shadow-sm flex items-center space-x-4">
          <div className="p-3 rounded-xl bg-indigo-50 text-indigo-600">
            <UserCheck className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm text-text-400">Utilisateurs Actifs</p>
            <h3 className="text-2xl font-bold text-text-200">{activity?.active_users_today || 0}</h3>
          </div>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-amber-200 bg-amber-50 shadow-sm flex items-center space-x-4">
          <div className="p-3 rounded-xl bg-amber-100 text-amber-600">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm text-amber-700">Alertes Actives</p>
            <h3 className="text-2xl font-bold text-amber-900">{activity?.alerts?.length || 0}</h3>
          </div>
        </div>
      </div>

      {/* Smart Alerts */}
      {activity?.alerts && activity.alerts.length > 0 && (
        <div className="space-y-3">
          <h3 className="text-lg font-bold text-text-200">Alertes Intelligentes</h3>
          {activity.alerts.map((alert, idx) => (
            <div key={idx} className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg flex items-center gap-3">
              <AlertTriangle className="w-5 h-5 text-red-500" />
              <span>{alert.message}</span>
            </div>
          ))}
        </div>
      )}

      {/* Audit Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-border-strong overflow-hidden">
        <div className="p-4 border-b border-border-strong bg-layer-2">
          <h3 className="font-bold text-text-200 flex items-center gap-2">
            <ShieldAlert className="w-5 h-5 text-text-400" /> Journal Complet (100 dernières actions)
          </h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-text-300">
            <thead className="bg-layer-2 text-text-400 font-medium border-b border-border-strong">
              <tr>
                <th className="px-6 py-4">Date</th>
                <th className="px-6 py-4">Utilisateur</th>
                <th className="px-6 py-4">Action</th>
                <th className="px-6 py-4">Ressource</th>
                <th className="px-6 py-4">Statut</th>
                <th className="px-6 py-4">IP</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {auditLogs.map(log => (
                <tr key={log.id} className="hover:bg-layer-2 transition-colors">
                  <td className="px-6 py-4 whitespace-nowrap">{new Date(log.created_at).toLocaleString('fr-FR')}</td>
                  <td className="px-6 py-4">{log.user}</td>
                  <td className="px-6 py-4">
                    <span className="bg-layer-3 text-text-200 px-2 py-1 rounded text-xs font-medium">{log.action}</span>
                  </td>
                  <td className="px-6 py-4">{log.resource_type}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded text-xs font-bold ${
                      log.status === 'SUCCESS' ? 'bg-emerald-100 text-emerald-700' : 
                      log.status === 'FAILURE' ? 'bg-red-100 text-red-700' : 'bg-layer-3 text-text-200'
                    }`}>
                      {log.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-text-400 text-xs">{log.ip_address || 'N/A'}</td>
                </tr>
              ))}
              {auditLogs.length === 0 && (
                <tr>
                  <td colSpan="6" className="px-6 py-8 text-center text-text-400">
                    Aucun log d'audit trouvé.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
