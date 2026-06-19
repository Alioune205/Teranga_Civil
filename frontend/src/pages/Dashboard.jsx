import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useDashboard } from '@/hooks/useDashboard';
import { useAuth } from '@/hooks/useAuth';
import { KPICard } from '@/components/KPICard';
import { Button } from '@/components/ui/button';
import { toast } from '@/components/ui/use-toast';
import { FileText, Clock, Eye, CheckCircle, XCircle, TrendingUp, RefreshCw, Download, ArrowRight } from 'lucide-react';

import { ActiviteMensuelle } from '@/components/dashboard/ActiviteMensuelle';
import { RepartitionStatut } from '@/components/dashboard/RepartitionStatut';
import { Top5Communes } from '@/components/dashboard/Top5Communes';
import { DemandesParType } from '@/components/dashboard/DemandesParType';
import { ActiviteRecente } from '@/components/dashboard/ActiviteRecente';

const exportCSV = (stats, globalStats) => {
  if (!stats) return;
  const headers = ['Métrique', 'Valeur'];
  const rows = [
    ['Total Demandes', stats.total_dossiers],
    ['Soumis', stats.status_counts?.submitted || 0],
    ['En vérification', stats.status_counts?.in_review || 0],
    ['Approuvés/Validés', (stats.status_counts?.validated || stats.status_counts?.approved) || 0],
    ['Rejetés', stats.status_counts?.rejected || 0],
    ['Terminés/Délivrés', (stats.status_counts?.delivered || stats.status_counts?.completed) || 0],
    ['Taux d\'approbation', `${globalStats?.taux_approbation || 0}%`],
    ['Temps moyen de traitement', stats.average_review_time || 'N/A'],
  ];

  if (stats.dossiers_par_commune) {
    rows.push(['', '']);
    rows.push(['Commune', 'Nombre de demandes']);
    stats.dossiers_par_commune.forEach((c) => {
      rows.push([c.commune, c.count]);
    });
  }

  const csv = [headers, ...rows].map((r) => r.join(';')).join('\n');
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `export_dashboard_${new Date().toISOString().split('T')[0]}.csv`;
  a.click();
  URL.revokeObjectURL(a.href);

  toast({ title: 'Export réussi', description: 'Le fichier CSV a été téléchargé.', variant: 'success' });
};

export default function Dashboard() {
  const navigate = useNavigate();
  const { stats, globalStats, activity, loading, lastUpdated, refresh } = useDashboard();
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState('overview');
  
  const role = user?.role;
  const isLocalAgent = ['agent', 'verification_agent', 'reception_agent'].includes(role);

  const getTimeSinceUpdate = () => {
    if (!lastUpdated) return '';
    const diff = Math.floor((Date.now() - lastUpdated.getTime()) / 60000);
    if (diff < 1) return 'à l\'instant';
    if (diff === 1) return 'il y a 1 min';
    return `il y a ${diff} min`;
  };

  const isDossiersEmpty = !stats || stats.total_dossiers === 0;
  const approbationRateValue = isDossiersEmpty ? '–' : `${globalStats?.taux_approbation || 0}%`;

  return (
    <div className="h-full flex flex-col overflow-y-auto overflow-x-hidden gap-4 pb-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-border-subtle shrink-0">
        <div className="space-y-1">
          <h1 className="text-xl font-bold text-text-100">
            Aperçu de l'activité du centre d'état civil
          </h1>
          <p className="text-[13px] text-text-400 font-normal">
            Données synchronisées {lastUpdated ? getTimeSinceUpdate() : "à l'instant"}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="default" size="sm" onClick={() => navigate('/dossiers?status=approved')} className="gap-2 bg-blue-600 hover:bg-blue-700">
            En attente de signature <ArrowRight className="h-4 w-4" />
          </Button>
          <div className="h-6 w-px bg-border-strong hidden sm:block" />
          <Button variant="outline" size="sm" onClick={() => exportCSV(stats, globalStats)} disabled={loading || !stats} className="gap-2">
            <Download className="h-4 w-4" /> Export CSV
          </Button>
          <Button variant="outline" size="sm" onClick={refresh} disabled={loading} className="gap-2">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} /> Rafraîchir
          </Button>
        </div>
      </div>

      {/* Section A — 5 KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 xl:grid-cols-5 gap-6 shrink-0">
        <KPICard title="Total demandes" value={stats?.total_dossiers ?? 0} icon={FileText} iconColorClass="text-blue-700 bg-blue-50 dark:bg-blue-900/20" criticalStatus="info" loading={loading} onClick={() => navigate('/dossiers')} />
        <KPICard title="En attente" value={(stats?.status_counts?.submitted ?? 0) + (stats?.status_counts?.draft ?? 0)} icon={Clock} iconColorClass="text-amber-500 bg-amber-50 dark:bg-amber-900/20" criticalStatus="warning" loading={loading} onClick={() => navigate('/dossiers?status=submitted')} />
        <KPICard title="En traitement" value={(stats?.status_counts?.in_review ?? 0) + (stats?.status_counts?.generated ?? 0)} icon={Eye} iconColorClass="text-blue-500 bg-blue-50 dark:bg-blue-900/20" criticalStatus="info" loading={loading} onClick={() => navigate('/dossiers?status=in_review')} />
        <KPICard title="Terminés" value={(stats?.status_counts?.validated ?? 0) + (stats?.status_counts?.approved ?? 0) + (stats?.status_counts?.delivered ?? 0) + (stats?.status_counts?.completed ?? 0)} icon={CheckCircle} iconColorClass="text-emerald-500 bg-emerald-50 dark:bg-emerald-900/20" criticalStatus="success" loading={loading} onClick={() => navigate('/dossiers?status=validated')} />
        <div className={`transition-all duration-300 ${(stats?.status_counts?.rejected ?? 0) > 10 ? 'animate-pulse ring-2 ring-red-500 rounded-xl' : ''}`}>
          <KPICard title="Rejetés" value={stats?.status_counts?.rejected ?? 0} icon={XCircle} iconColorClass="text-red-500 bg-red-50 dark:bg-red-900/20" criticalStatus="error" loading={loading} onClick={() => navigate('/dossiers?status=rejected')} />
        </div>
      </div>

      {/* Tabs Navigation */}
      <div className="flex items-center gap-4 border-b border-border-subtle">
        <button
          onClick={() => setActiveTab('overview')}
          className={`pb-2 px-4 text-sm font-medium transition-colors border-b-2 ${
            activeTab === 'overview'
              ? 'border-blue-600 text-blue-600 dark:text-blue-400 dark:border-blue-400'
              : 'border-transparent text-text-300 hover:text-text-100'
          }`}
        >
          Vue Globale
        </button>
        <button
          onClick={() => setActiveTab('details')}
          className={`pb-2 px-4 text-sm font-medium transition-colors border-b-2 ${
            activeTab === 'details'
              ? 'border-blue-600 text-blue-600 dark:text-blue-400 dark:border-blue-400'
              : 'border-transparent text-text-300 hover:text-text-100'
          }`}
        >
          Détails & Activité
        </button>
      </div>

      {/* Sections Graphiques */}
      <div className="flex flex-col lg:grid lg:grid-cols-5 gap-6 items-stretch pb-4 animate-in fade-in duration-300">
        {activeTab === 'overview' ? (
          <>
            <ActiviteMensuelle loading={loading} activity={activity} approbationRate={approbationRateValue} />
            <RepartitionStatut loading={loading} stats={stats} />
          </>
        ) : (
          <>
            <ActiviteRecente />
            <DemandesParType loading={loading} stats={stats} />
            {!isLocalAgent && <Top5Communes loading={loading} stats={stats} />}
          </>
        )}
      </div>
    </div>
  );
}
