import React, { useState, useEffect } from 'react';
import { Users, FileText, CheckCircle, XCircle, CreditCard, Building2, AlertTriangle, Info, Clock, Activity, ArrowRight, AlertCircle, ShieldAlert } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, Legend, ResponsiveContainer, LineChart, Line, PieChart, Pie, Cell } from 'recharts';
import { Link } from 'react-router-dom';
import api from '@/api/axiosClient';

// Helper for relative time
const timeAgo = (dateStr) => {
  const date = new Date(dateStr);
  const seconds = Math.round((new Date() - date) / 1000);
  const minutes = Math.round(seconds / 60);
  const hours = Math.round(minutes / 60);
  const days = Math.round(hours / 24);
  if (seconds < 60) return `à l'instant`;
  if (minutes < 60) return `il y a ${minutes} min`;
  if (hours < 24) return `il y a ${hours} h`;
  if (days === 1) return `hier`;
  return `il y a ${days} j`;
};

const COLORS = ['#3b82f6', '#ef4444', '#8b5cf6', '#10b981', '#f59e0b'];

export default function SuperOverview() {
  // Global States
  const [stats, setStats] = useState(null);
  const [loadingStats, setLoadingStats] = useState(true);

  // Charts States (Bloc 1 & 2)
  const [chartsData, setChartsData] = useState(null);
  const [loadingCharts, setLoadingCharts] = useState(true);
  const [chartPeriod, setChartPeriod] = useState('30d'); // 7d, 30d, 6m, 1y

  // Communes & Top Communes States (Bloc 3 & 4)
  const [communeStats, setCommuneStats] = useState([]);
  const [loadingCommunes, setLoadingCommunes] = useState(true);

  // Alerts State (Bloc 5)
  const [alerts, setAlerts] = useState([]);
  const [loadingAlerts, setLoadingAlerts] = useState(true);

  // Activities State (Bloc 6)
  const [activities, setActivities] = useState([]);
  const [loadingActivities, setLoadingActivities] = useState(true);

  // 1. Fetch Global Stats
  useEffect(() => {
    api.get('/api/dashboard/superadmin/overview/')
      .then(res => setStats(res.data))
      .catch(console.error)
      .finally(() => setLoadingStats(false));
  }, []);

  // 2. Fetch Charts (reacts to chartPeriod)
  useEffect(() => {
    setLoadingCharts(true);
    api.get(`/api/dashboard/superadmin/charts/?period=${chartPeriod}`)
      .then(res => setChartsData(res.data))
      .catch(console.error)
      .finally(() => setLoadingCharts(false));
  }, [chartPeriod]);

  // 3. Fetch Communes (for BarChart & Top Communes)
  useEffect(() => {
    api.get('/api/dashboard/superadmin/communes/performance/')
      .then(res => {
        const formattedData = res.data.map(item => {
          const pending = Math.max(0, item.total_dossiers - item.approved_dossiers - item.rejected_dossiers);
          const approvalRate = item.total_dossiers > 0 ? Math.round((item.approved_dossiers / item.total_dossiers) * 100) : 0;
          return {
            name: item.name,
            total: item.total_dossiers,
            Approuvés: item.approved_dossiers,
            'En attente': pending,
            Rejetés: item.rejected_dossiers,
            revenue: item.revenue || 0,
            approvalRate
          };
        });
        setCommuneStats(formattedData);
      })
      .catch(console.error)
      .finally(() => setLoadingCommunes(false));
  }, []);

  // 4. Fetch Alerts
  useEffect(() => {
    api.get('/api/dashboard/superadmin/alerts/')
      .then(res => setAlerts(res.data))
      .catch(console.error)
      .finally(() => setLoadingAlerts(false));
  }, []);

  // 5. Fetch Activities (limit 10)
  useEffect(() => {
    // AuditLogViewSet using standard pagination/limit
    api.get('/api/audit-logs/?limit=10')
      .then(res => {
        // Handle DRF paginated response or list
        const data = res.data.results || res.data;
        setActivities(data.slice(0, 10)); // Force limit fallback
      })
      .catch(console.error)
      .finally(() => setLoadingActivities(false));
  }, []);


  const kpis = stats ? [
    { label: 'Citoyens', value: stats.citizens, icon: Users, color: 'text-blue-500', bg: 'bg-blue-50' },
    { label: 'Agents Actifs', value: stats.agents, icon: Users, color: 'text-indigo-500', bg: 'bg-indigo-50' },
    { label: 'Communes', value: stats.communes, icon: Building2, color: 'text-purple-500', bg: 'bg-purple-50' },
    { label: 'Demandes (Total)', value: stats.dossiers.total, icon: FileText, color: 'text-text-400', bg: 'bg-layer-2' },
    { label: 'En attente', value: stats.dossiers.pending, icon: FileText, color: 'text-amber-500', bg: 'bg-amber-50' },
    { label: 'Approuvées', value: stats.dossiers.approved, icon: CheckCircle, color: 'text-emerald-500', bg: 'bg-emerald-50' },
    { label: 'Rejetées', value: stats.dossiers.rejected, icon: XCircle, color: 'text-red-500', bg: 'bg-red-50' },
    { label: 'Revenus', value: `${stats.payments.revenue.toLocaleString()} FCFA`, icon: CreditCard, color: 'text-green-600', bg: 'bg-green-50' },
  ] : [];

  // Render Helpers
  const renderMedal = (index) => {
    if (index === 0) return "🥇";
    if (index === 1) return "🥈";
    if (index === 2) return "🥉";
    return <span className="text-text-400 font-medium pl-1">{index + 1}</span>;
  };

  const getApprovalColor = (rate) => {
    if (rate >= 80) return "bg-emerald-500";
    if (rate >= 50) return "bg-amber-500";
    return "bg-red-500";
  };

  const getAlertIcon = (type) => {
    switch (type) {
      case 'error': return <AlertCircle className="w-5 h-5 text-red-500" />;
      case 'warning': return <AlertTriangle className="w-5 h-5 text-orange-500" />;
      default: return <Info className="w-5 h-5 text-blue-500" />;
    }
  };

  const getAlertBg = (type) => {
    switch (type) {
      case 'error': return "bg-red-50 border-red-100";
      case 'warning': return "bg-orange-50 border-orange-100";
      default: return "bg-blue-50 border-blue-100";
    }
  };

  // Prepare Donut data
  const pieData = chartsData?.documents_breakdown?.map(item => ({
    name: item.type === 'birth_certificate' ? 'Acte de naissance' :
          item.type === 'death_certificate' ? 'Certificat de décès' :
          item.type === 'marriage_certificate' ? 'Certificat de mariage' :
          item.type === 'residence_certificate' ? 'Certificat de résidence' : 'Autre',
    value: item.count
  })) || [];

  const totalPie = pieData.reduce((acc, curr) => acc + curr.value, 0);

  // Prepare Trends Data
  const formatXAxisDate = (tickItem) => {
    const d = new Date(tickItem);
    if (chartPeriod === '1y') return `${d.getMonth() + 1}/${d.getFullYear()}`;
    return `${d.getDate()}/${d.getMonth() + 1}`;
  };

  return (
    <div className="space-y-6 pb-12">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text-200">Vue Nationale</h1>
          <p className="text-sm text-text-400">Supervision stratégique de l'état civil</p>
        </div>
      </div>

      {/* 1. KPIs Grid */}
      {loadingStats ? (
        <div className="h-32 bg-layer-2 animate-pulse rounded-2xl"></div>
      ) : stats ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {kpis.map((kpi, idx) => (
            <div key={idx} className="bg-white p-5 rounded-2xl border border-border-subtle shadow-sm flex items-center space-x-4">
              <div className={`p-3 rounded-xl ${kpi.bg}`}>
                <kpi.icon className={`w-6 h-6 ${kpi.color}`} />
              </div>
              <div>
                <p className="text-sm text-text-400 font-medium">{kpi.label}</p>
                <h3 className="text-2xl font-bold text-text-200">{kpi.value}</h3>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="p-8 text-center text-red-500 bg-red-50 rounded-2xl border border-red-100">Erreur de chargement des statistiques.</div>
      )}

      {/* 2. Évolution temporelle */}
      <div className="bg-white p-6 rounded-2xl border border-border-subtle shadow-sm">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-6 gap-4">
          <h2 className="text-lg font-bold text-text-200 flex items-center gap-2">
            <Activity className="w-5 h-5 text-primary" />
            Évolution des demandes
          </h2>
          <div className="flex items-center bg-layer-3 p-1 rounded-lg">
            {['7d', '30d', '6m', '1y'].map((period) => (
              <button
                key={period}
                onClick={() => setChartPeriod(period)}
                className={`px-3 py-1.5 text-sm font-medium rounded-md transition-colors ${
                  chartPeriod === period ? 'bg-white text-primary shadow-sm' : 'text-text-400 hover:text-text-200'
                }`}
              >
                {period === '7d' ? '7 Jours' : period === '30d' ? '30 Jours' : period === '6m' ? '6 Mois' : '1 An'}
              </button>
            ))}
          </div>
        </div>
        <div className="h-[350px] w-full">
          {loadingCharts ? (
            <div className="h-full w-full flex items-center justify-center text-text-400">Chargement du graphique...</div>
          ) : chartsData?.dossiers_trend?.length > 0 ? (
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartsData.dossiers_trend} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                <XAxis dataKey="date" tickFormatter={formatXAxisDate} tick={{ fill: '#64748b', fontSize: 12 }} axisLine={false} tickLine={false} dy={10} />
                <YAxis tick={{ fill: '#64748b', fontSize: 12 }} axisLine={false} tickLine={false} />
                <RechartsTooltip
                  labelFormatter={formatXAxisDate}
                  contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                />
                <Legend wrapperStyle={{ paddingTop: '20px' }} />
                <Line type="monotone" name="Total Demandes" dataKey="total" stroke="#3b82f6" strokeWidth={3} dot={{ r: 4, fill: '#3b82f6' }} activeDot={{ r: 6 }} />
                <Line type="monotone" name="Approuvées" dataKey="approved" stroke="#10b981" strokeWidth={3} dot={false} activeDot={{ r: 6 }} />
                <Line type="monotone" name="En attente" dataKey="pending" stroke="#f59e0b" strokeWidth={3} dot={false} activeDot={{ r: 6 }} />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-full flex items-center justify-center text-text-400">Aucune donnée pour cette période.</div>
          )}
        </div>
      </div>

      {/* 3. Répartition par type & Top Communes */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* PieChart - Répartition */}
        <div className="bg-white p-6 rounded-2xl border border-border-subtle shadow-sm flex flex-col">
          <h2 className="text-lg font-bold text-text-200 mb-6 flex items-center gap-2">
            <FileText className="w-5 h-5 text-primary" />
            Types de documents
          </h2>
          <div className="flex-1 flex flex-col items-center justify-center relative">
            {loadingCharts ? (
              <div className="text-text-400">Chargement...</div>
            ) : totalPie > 0 ? (
              <div className="h-[300px] w-full relative">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={pieData}
                      cx="50%"
                      cy="50%"
                      innerRadius={80}
                      outerRadius={110}
                      paddingAngle={2}
                      dataKey="value"
                    >
                      {pieData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <RechartsTooltip contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }} />
                    <Legend verticalAlign="bottom" height={36} />
                  </PieChart>
                </ResponsiveContainer>
                {/* Total centré */}
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none pb-8">
                  <span className="text-3xl font-bold text-text-200">{totalPie}</span>
                  <span className="text-xs text-text-400 uppercase font-medium">Demandes</span>
                </div>
              </div>
            ) : (
              <div className="text-text-400">Aucune donnée disponible.</div>
            )}
          </div>
        </div>

        {/* Classement Top Communes */}
        <div className="bg-white p-6 rounded-2xl border border-border-subtle shadow-sm overflow-hidden flex flex-col">
          <h2 className="text-lg font-bold text-text-200 mb-6 flex items-center gap-2">
            <Building2 className="w-5 h-5 text-primary" />
            Classement des communes
          </h2>
          <div className="flex-1 overflow-auto">
            {loadingCommunes ? (
              <div className="text-text-400 text-center py-10">Chargement des communes...</div>
            ) : communeStats.length > 0 ? (
              <table className="w-full text-left text-sm text-text-300">
                <thead className="bg-layer-2 text-text-400 text-xs uppercase font-semibold sticky top-0">
                  <tr>
                    <th className="px-4 py-3 rounded-l-lg">Rang</th>
                    <th className="px-4 py-3">Commune</th>
                    <th className="px-4 py-3 text-right">Dossiers</th>
                    <th className="px-4 py-3 w-1/3">Approbation</th>
                    <th className="px-4 py-3 text-right rounded-r-lg">Revenus (FCFA)</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {communeStats.slice(0, 8).map((commune, idx) => (
                    <tr key={idx} className="hover:bg-layer-2 transition-colors">
                      <td className="px-4 py-3 text-lg">{renderMedal(idx)}</td>
                      <td className="px-4 py-3 font-medium text-text-200">{commune.name}</td>
                      <td className="px-4 py-3 text-right font-semibold">{commune.total}</td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-medium w-8">{commune.approvalRate}%</span>
                          <div className="w-full bg-layer-3 rounded-full h-1.5">
                            <div 
                              className={`h-1.5 rounded-full ${getApprovalColor(commune.approvalRate)}`} 
                              style={{ width: `${commune.approvalRate}%` }}
                            ></div>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-right font-medium text-green-600">
                        {commune.revenue.toLocaleString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <div className="text-center text-text-400 py-10">Aucune commune active.</div>
            )}
          </div>
        </div>

      </div>

      {/* 4. Activité par commune (BarChart) */}
      <div className="bg-white p-6 rounded-2xl border border-border-subtle shadow-sm mt-6">
        <h2 className="text-lg font-bold text-text-200 mb-6 flex items-center gap-2">
          <BarChart className="w-5 h-5 text-primary" />
          Activité par commune
        </h2>
        <div className="h-[400px] w-full">
          {loadingCommunes ? (
            <div className="h-full flex items-center justify-center text-text-400">Chargement...</div>
          ) : communeStats.length > 0 ? (
            <ResponsiveContainer width="100%" height="100%">
              <BarChart
                data={communeStats}
                layout="vertical"
                margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
              >
                <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#e2e8f0" />
                <XAxis type="number" />
                <YAxis 
                  dataKey="name" 
                  type="category" 
                  axisLine={false} 
                  tickLine={false}
                  tick={{ fill: '#64748b', fontSize: 13 }}
                  width={120}
                />
                <RechartsTooltip 
                  cursor={{ fill: '#f8fafc' }}
                  contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                />
                <Legend wrapperStyle={{ paddingTop: '20px' }} />
                <Bar dataKey="Approuvés" stackId="a" fill="#10b981" radius={[0, 0, 0, 0]} barSize={24} />
                <Bar dataKey="En attente" stackId="a" fill="#f59e0b" radius={[0, 0, 0, 0]} />
                <Bar dataKey="Rejetés" stackId="a" fill="#ef4444" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-full flex items-center justify-center text-text-400">Aucune donnée disponible.</div>
          )}
        </div>
      </div>

      {/* Row: Alertes & Activités */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* 5. Alertes intelligentes */}
        <div className="bg-white p-6 rounded-2xl border border-border-subtle shadow-sm flex flex-col">
          <h2 className="text-lg font-bold text-text-200 mb-6 flex items-center gap-2">
            <ShieldAlert className="w-5 h-5 text-red-500" />
            Alertes système
          </h2>
          <div className="flex-1 space-y-3 overflow-y-auto max-h-[400px] pr-2">
            {loadingAlerts ? (
              <div className="text-text-400">Recherche d'anomalies...</div>
            ) : alerts.length > 0 ? (
              alerts.map((alert, idx) => (
                <div key={idx} className={`p-4 rounded-xl border flex items-start gap-4 ${getAlertBg(alert.type)}`}>
                  <div className="mt-1">{getAlertIcon(alert.type)}</div>
                  <div className="flex-1">
                    <h4 className="font-bold text-text-200 text-sm">{alert.title}</h4>
                    <p className="text-sm text-text-300 mt-1">{alert.message}</p>
                    <Link to={alert.link} className="inline-flex items-center gap-1 text-xs font-semibold text-primary mt-2 hover:underline">
                      Consulter <ArrowRight className="w-3 h-3" />
                    </Link>
                  </div>
                </div>
              ))
            ) : (
              <div className="flex flex-col items-center justify-center h-full text-text-400 py-10">
                <CheckCircle className="w-12 h-12 text-emerald-400 mb-3 opacity-50" />
                <p>Aucune alerte. Tout fonctionne normalement.</p>
              </div>
            )}
          </div>
        </div>

        {/* 6. Dernières activités */}
        <div className="bg-white p-6 rounded-2xl border border-border-subtle shadow-sm flex flex-col">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-bold text-text-200 flex items-center gap-2">
              <Clock className="w-5 h-5 text-primary" />
              Activité récente
            </h2>
            <Link to="/super/audit" className="text-sm font-medium text-primary hover:underline flex items-center gap-1">
              Voir tout <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
          <div className="flex-1 overflow-y-auto max-h-[400px] pr-2">
            {loadingActivities ? (
              <div className="text-text-400">Chargement de l'audit...</div>
            ) : activities.length > 0 ? (
              <div className="space-y-4">
                {activities.map((act, idx) => (
                  <div key={act.id || idx} className="flex gap-4 relative">
                    {/* Ligne connectrice */}
                    {idx !== activities.length - 1 && (
                      <div className="absolute left-[11px] top-8 bottom-[-16px] w-[2px] bg-layer-3"></div>
                    )}
                    <div className="relative z-10 w-6 h-6 rounded-full bg-layer-3 flex items-center justify-center shrink-0 mt-1 border-2 border-white shadow-sm">
                      <div className={`w-2 h-2 rounded-full ${act.status === 'success' ? 'bg-emerald-500' : 'bg-slate-400'}`}></div>
                    </div>
                    <div className="flex-1 pb-1">
                      <div className="flex justify-between items-start">
                        <p className="text-sm text-text-200">
                          {(() => {
                            const user = act.user || 'Système';
                            const action = act.action;
                            const res = act.resource_type;
                            try {
                              const details = typeof act.details === 'string' ? JSON.parse(act.details) : (act.details || {});
                              if (action === 'LOGIN') return `Connexion de ${user}`;
                              if (action === 'CREATE' && res === 'dossier') return `${user} a créé le dossier ${details.reference || ''}`;
                              if (action === 'STATUS_CHANGE' && res === 'dossier') return `Dossier ${details.reference || ''} passé en ${details.new_status || details.status || ''}`;
                              if (action === 'UPDATE' && res === 'user') return `Profil de ${user} mis à jour`;
                              if (action === 'CREATE' && res === 'auth') return `Nouveau compte créé`;
                              if (details.message) return details.message;
                              return `${user} a ${action} sur ${res}`;
                            } catch(e) {
                              return `${user} a ${action} sur ${res}`;
                            }
                          })()}
                        </p>
                        <span className="text-xs text-text-400 whitespace-nowrap ml-4">
                          {timeAgo(act.created_at)}
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-text-400 text-center py-10">Aucune activité enregistrée.</div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}
