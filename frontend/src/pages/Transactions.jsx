import { useState, useEffect, useCallback } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { getTransactions, getTransactionStats } from '@/api/transactions';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { toast } from '@/components/ui/use-toast';
import { 
  Search, 
  RotateCcw, 
  ChevronLeft, 
  ChevronRight, 
  Activity, 
  TrendingUp, 
  Download, 
  Eye, 
  X, 
  CreditCard, 
  Clock,
  FileText
} from 'lucide-react';
import axiosClient from '@/api/axiosClient';

const STATUS_BADGES = {
  pending: { label: 'En attente', className: 'bg-[#F59E0B] text-white border-[#F59E0B]' },
  success: { label: 'Validé', className: 'bg-[#10B981] text-white border-[#10B981]' },
  failed: { label: 'Échoué', className: 'bg-[#EF4444] text-white border-[#EF4444]' },
  refunded: { label: 'Remboursé', className: 'bg-layer-3 text-text-200 dark:bg-slate-800 dark:text-slate-200 border-border-strong' },
};

const PAYMENT_TYPE_LABELS = {
  card: 'Carte bancaire (CB/Visa/Mastercard)',
  wave: 'Mobile Money Wave',
  orange_money: 'Mobile Money Orange Money',
  free_money: 'Mobile Money Free Money',
  transfer: 'Virement bancaire',
  agency: 'Paiement en agence',
  cash: 'Espèces (caisse)',
};

export default function Transactions() {
  const { role } = useAuth();

  // Restriction super_admin et civil_admin_supervisor uniquement
  if (role !== 'super_admin' && role !== 'civil_admin_supervisor') {
    return <Navigate to="/dashboard" replace />;
  }

  const [transactions, setTransactions] = useState([]);
  const [stats, setStats] = useState({
    total_today: 0,
    total_amount: 0,
    success_rate: 0,
    distribution: {}
  });
  
  const [loading, setLoading] = useState(true);
  const [statsLoading, setStatsLoading] = useState(true);
  
  // Filtres
  const [paymentType, setPaymentType] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [page, setPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [selectedTx, setSelectedTx] = useState(null); // Pour le drawer
  
  const pageSize = 20;

  const handleDownloadReceipt = async (tx) => {
    try {
      const res = await axiosClient.get(`/api/transactions/${tx.id}/receipt/`, {
        responseType: 'blob',
      });
      const blob = new Blob([res.data], { type: 'application/pdf' });
      const downloadUrl = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = downloadUrl;
      link.setAttribute('download', `recu_${tx.receipt_number || tx.reference}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(downloadUrl);
      toast({
        title: 'Reçu téléchargé',
        description: `Le reçu de la transaction ${tx.reference} a été téléchargé avec succès.`,
        className: 'bg-green-50 border-green-200 text-green-900',
      });
    } catch (err) {
      toast({
        title: 'Erreur',
        description: 'Impossible de télécharger le reçu de paiement.',
        variant: 'destructive',
      });
    }
  };

  // Récupérer les stats
  const fetchStats = useCallback(async () => {
    setStatsLoading(true);
    try {
      const data = await getTransactionStats();
      if (data) {
        setStats(data);
      }
    } catch (error) {
      console.error("Erreur de chargement des statistiques", error);
    } finally {
      setStatsLoading(false);
    }
  }, []);

  // Récupérer les transactions
  const fetchTransactions = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, page_size: pageSize };
      if (paymentType) params.payment_type = paymentType;
      if (statusFilter) params.status = statusFilter;
      if (dateFrom) params.date_from = dateFrom;
      if (dateTo) params.date_to = dateTo;
      if (searchQuery) params.search = searchQuery; // Optionnel recherche par ref ou payeur

      const data = await getTransactions(params);
      if (data) {
        setTransactions(data.results || []);
        setTotalCount(data.count || 0);
      }
    } catch (error) {
      toast({
        title: 'Erreur',
        description: 'Impossible de charger la liste des transactions.',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  }, [page, paymentType, statusFilter, dateFrom, dateTo, searchQuery]);

  // Chargement initial
  useEffect(() => {
    fetchStats();
    fetchTransactions();
  }, [fetchStats, fetchTransactions]);

  // --- NOUVEAU : Connexion Temps Réel (WebSockets) ---
  useEffect(() => {
    // Construction de l'URL WebSocket à partir de l'URL de l'API
    const baseUrl = import.meta.env.VITE_API_URL || 'http://127.0.0.1:8000/api';
    const wsUrl = baseUrl.replace('http', 'ws').replace('/api', '/ws/dashboard/');
      
    const ws = new WebSocket(wsUrl);

    ws.onopen = () => console.log('🔗 Connecté au serveur Temps Réel (Transactions)');

    ws.onmessage = (event) => {
      const parsed = JSON.parse(event.data);
      if (parsed.message === 'new_transaction') {
        // Notification toast visuelle
        toast({
          title: 'Nouvelle Transaction ! 💸',
          description: `Un paiement de ${parsed.data.amount} FCFA a été validé.`,
          variant: 'default',
          className: 'bg-green-50 border-green-200 text-green-900',
        });
        // Rafraîchir les données silencieusement
        fetchStats();
        fetchTransactions();
      }
    };

    ws.onclose = () => console.log('❌ Déconnecté du serveur Temps Réel');

    // Nettoyage à la fermeture de la page
    return () => ws.close();
  }, [fetchStats, fetchTransactions]);

  // Refresh automatique toutes les 60 secondes
  useEffect(() => {
    const interval = setInterval(() => {
      fetchStats();
      fetchTransactions();
      toast({
        title: 'Mise à jour',
        description: 'Les données des transactions ont été rafraîchies.',
        duration: 3000,
      });
    }, 60000);
    
    return () => clearInterval(interval);
  }, [fetchStats, fetchTransactions]);

  const handleResetFilters = () => {
    setPaymentType('');
    setStatusFilter('');
    setDateFrom('');
    setDateTo('');
    setSearchQuery('');
    setPage(1);
  };

  // Export CSV
  const handleExportCSV = () => {
    if (transactions.length === 0) {
      toast({
        title: 'Export impossible',
        description: 'Aucune donnée à exporter.',
        variant: 'destructive',
      });
      return;
    }

    const headers = ['Référence', 'Montant (XOF)', 'Devise', 'Type de paiement', 'Statut', 'Service', 'Payeur (Nom)', 'Payeur (ID)', 'Date'];
    
    const rows = transactions.map(tx => [
      tx.reference,
      tx.amount,
      tx.currency,
      PAYMENT_TYPE_LABELS[tx.payment_type] || tx.payment_type,
      STATUS_BADGES[tx.status]?.label || tx.status,
      `"${tx.service_label.replace(/"/g, '""')}"`,
      `"${tx.payer_name.replace(/"/g, '""')}"`,
      tx.payer_id,
      new Date(tx.created_at).toLocaleString('fr-FR'),
    ]);

    const csvContent = [
      headers.join(','),
      ...rows.map(e => e.join(','))
    ].join('\n');

    // Téléchargement
    const blob = new Blob(['\uFEFF' + csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `transactions_export_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    toast({
      title: 'Export réussi',
      description: 'Le fichier CSV a été généré et téléchargé.',
    });
  };

  const formatDate = (dateStr) => {
    if (!dateStr) return '—';
    return new Date(dateStr).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const totalPages = Math.ceil(totalCount / pageSize);

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-secondary">Suivi des Transactions</h1>
          <p className="text-sm text-text-400 mt-1">
            Visualisation et audit des transactions financières de l'état civil
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button 
            onClick={() => { fetchStats(); fetchTransactions(); }}
            variant="outline" 
            size="sm" 
            className="gap-2 focus:ring-[#1D4ED8] focus:border-[#1D4ED8]"
          >
            <Clock className="h-4 w-4 text-text-400" />
            Actualiser
          </Button>
          {role === 'super_admin' && (
            <Button 
              onClick={handleExportCSV}
              className="gap-2 bg-[#1D4ED8] hover:bg-[#1D4ED8]/90 text-white rounded-lg focus:ring-[#1D4ED8]"
            >
              <Download className="h-4 w-4" />
              Exporter CSV
            </Button>
          )}
        </div>
      </div>

      {/* Cartes métriques */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="border border-border-subtle shadow-[0_4px_12px_rgba(15,23,42,0.02)]">
          <CardContent className="p-6">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-xs font-semibold text-text-400 uppercase tracking-wider">Transactions / jour</p>
                {statsLoading ? (
                  <Skeleton className="h-10 w-24 mt-2" />
                ) : (
                  <h3 className="text-3xl font-bold text-secondary mt-1">{stats.total_today}</h3>
                )}
              </div>
              <div className="p-3 bg-[#1D4ED8]/10 text-[#1D4ED8] rounded-xl">
                <Activity className="h-6 w-6" />
              </div>
            </div>
            <p className="text-xs text-text-400 mt-3 font-medium">Nombre de règlements initiés aujourd'hui</p>
          </CardContent>
        </Card>

        <Card className="border border-border-subtle shadow-[0_4px_12px_rgba(15,23,42,0.02)]">
          <CardContent className="p-6">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-xs font-semibold text-text-400 uppercase tracking-wider">Montant total XOF</p>
                {statsLoading ? (
                  <Skeleton className="h-10 w-32 mt-2" />
                ) : (
                  <h3 className="text-3xl font-bold text-secondary mt-1">
                    {stats.total_amount.toLocaleString('fr-FR')} XOF
                  </h3>
                )}
              </div>
              <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl dark:bg-emerald-950/20">
                <span className="text-xl font-bold">F</span>
              </div>
            </div>
            <p className="text-xs text-text-400 mt-3 font-medium">Transactions encaissées avec succès</p>
          </CardContent>
        </Card>

        <Card className="border border-border-subtle shadow-[0_4px_12px_rgba(15,23,42,0.02)]">
          <CardContent className="p-6">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-xs font-semibold text-text-400 uppercase tracking-wider">Taux de succès %</p>
                {statsLoading ? (
                  <Skeleton className="h-10 w-24 mt-2" />
                ) : (
                  <h3 className="text-3xl font-bold text-secondary mt-1">{stats.success_rate} %</h3>
                )}
              </div>
              <div className="p-3 bg-[#1D4ED8]/10 text-[#1D4ED8] rounded-xl">
                <TrendingUp className="h-6 w-6" />
              </div>
            </div>
            <p className="text-xs text-text-400 mt-3 font-medium">Rapport règlements validés / refusés</p>
          </CardContent>
        </Card>

        <Card className="border border-border-subtle shadow-[0_4px_12px_rgba(15,23,42,0.02)]">
          <CardContent className="p-6">
            <div className="flex justify-between items-start">
              <div className="w-full">
                <p className="text-xs font-semibold text-text-400 uppercase tracking-wider mb-2">Répartition par type</p>
                {statsLoading ? (
                  <Skeleton className="h-12 w-full mt-2" />
                ) : (
                  <div className="space-y-1.5 max-h-[70px] overflow-y-auto pr-1">
                    {Object.entries(stats.distribution).length > 0 ? (
                      Object.entries(stats.distribution).map(([type, count]) => {
                        const typeLabelsMap = {
                          card: 'Carte',
                          wave: 'Wave',
                          orange_money: 'Orange Money',
                          free_money: 'Free Money',
                          transfer: 'Virement',
                          agency: 'Agence',
                          cash: 'Espèces'
                        };
                        return (
                          <div key={type} className="flex justify-between text-xs font-medium">
                            <span className="text-text-400">{typeLabelsMap[type] || type}</span>
                            <span className="text-secondary font-semibold">{count}</span>
                          </div>
                        );
                      })
                    ) : (
                      <p className="text-xs text-text-400">Aucune donnée</p>
                    )}
                  </div>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Barre de filtres */}
      <Card className="p-4 border border-border-subtle shadow-[0_4px_12px_rgba(15,23,42,0.01)]">
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative flex-1 min-w-[240px]">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-text-400" />
            <Input
              placeholder="Rechercher par référence, payeur..."
              value={searchQuery}
              onChange={(e) => { setSearchQuery(e.target.value); setPage(1); }}
              className="pl-9 focus-visible:border-[#1D4ED8] focus-visible:ring-[#1D4ED8]/25"
            />
          </div>

          {/* Type de paiement grouped drop-down */}
          <select
            value={paymentType}
            onChange={(e) => { setPaymentType(e.target.value); setPage(1); }}
            className="h-10 px-3 py-2 text-sm bg-layer-2 border border-border-strong rounded-md text-text-100 placeholder:text-text-400 focus-visible:outline-none focus-visible:border-[#1D4ED8] focus-visible:ring-2 focus-visible:ring-[#1D4ED8]/20"
          >
            <option value="">Tous les types de paiement</option>
            <optgroup label="Mobile Money">
              <option value="wave">Wave</option>
              <option value="orange_money">Orange Money</option>
              <option value="free_money">Free Money</option>
            </optgroup>
            <optgroup label="Autres">
              <option value="card">Carte bancaire</option>
              <option value="transfer">Virement bancaire</option>
              <option value="agency">Paiement en agence</option>
              <option value="cash">Espèces</option>
            </optgroup>
          </select>

          {/* Statut Dropdown */}
          <select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
            className="h-10 px-3 py-2 text-sm bg-layer-2 border border-border-strong rounded-md text-text-100 placeholder:text-text-400 focus-visible:outline-none focus-visible:border-[#1D4ED8] focus-visible:ring-2 focus-visible:ring-[#1D4ED8]/20"
          >
            <option value="">Tous les statuts</option>
            <option value="pending">En attente</option>
            <option value="success">Validé</option>
            <option value="failed">Échoué</option>
            <option value="refunded">Remboursé</option>
          </select>

          {/* Date range inputs */}
          <div className="flex items-center gap-2">
            <Input
              type="date"
              value={dateFrom}
              onChange={(e) => { setDateFrom(e.target.value); setPage(1); }}
              className="w-[140px] focus-visible:border-[#1D4ED8]"
            />
            <span className="text-text-400 text-sm">au</span>
            <Input
              type="date"
              value={dateTo}
              onChange={(e) => { setDateTo(e.target.value); setPage(1); }}
              className="w-[140px] focus-visible:border-[#1D4ED8]"
            />
          </div>

          <Button 
            variant="outline" 
            size="sm" 
            onClick={handleResetFilters} 
            className="gap-2 focus:ring-[#1D4ED8]"
          >
            <RotateCcw className="h-4 w-4" />
            Réinitialiser
          </Button>
        </div>
      </Card>

      {/* Tableau des transactions */}
      <Card className="table-container border border-border-subtle shadow-[0_4px_12px_rgba(15,23,42,0.02)]">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-border-subtle bg-layer-2">
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Référence</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Service</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Montant (XOF)</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Type</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Statut</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Payeur</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider">Date</th>
                <th className="px-4 py-3 text-right text-xs font-semibold text-text-400 uppercase tracking-wider">Action</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i} className="border-b border-border-subtle">
                    {[...Array(8)].map((_, j) => (
                      <td key={j} className="px-4 py-4">
                        <Skeleton className="h-5 w-full" />
                      </td>
                    ))}
                  </tr>
                ))
              ) : transactions.length > 0 ? (
                transactions.map((tx) => {
                  const badge = STATUS_BADGES[tx.status] || STATUS_BADGES.pending;
                  const typeLabelsShort = {
                    card: 'Carte',
                    wave: 'Wave',
                    orange_money: 'Orange Money',
                    free_money: 'Free Money',
                    transfer: 'Virement',
                    agency: 'Agence',
                    cash: 'Espèces'
                  };
                  return (
                    <tr key={tx.id} className="border-b border-border-subtle hover:bg-layer-2 transition-colors">
                      <td className="px-4 py-3">
                        <div className="flex flex-col">
                          <span className="text-sm font-semibold text-secondary font-mono">{tx.reference}</span>
                          {tx.receipt_number && (
                            <span className="text-[10px] text-text-400 font-mono">Reçu: {tx.receipt_number}</span>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <span className="text-sm text-text-300 font-medium block max-w-[200px] truncate" title={tx.service_label}>
                          {tx.service_label}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <span className="text-sm font-bold text-secondary">
                          {parseFloat(tx.amount).toLocaleString('fr-FR')} {tx.currency}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <span className="text-xs text-text-400 font-medium">{typeLabelsShort[tx.payment_type] || tx.payment_type}</span>
                      </td>
                      <td className="px-4 py-3">
                        <Badge className={`${badge.className} text-xs font-semibold px-2 py-0.5 rounded-full`}>
                          {badge.label}
                        </Badge>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex flex-col">
                          <span className="text-sm font-semibold text-secondary">{tx.payer_name}</span>
                          <span className="text-[10px] text-text-400 font-mono">{tx.payer_id}</span>
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <span className="text-xs text-text-400 font-medium">{formatDate(tx.created_at)}</span>
                      </td>
                      <td className="px-4 py-3 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          {tx.receipt_number && (
                            <Button 
                              onClick={() => handleDownloadReceipt(tx)}
                              variant="ghost" 
                              size="sm" 
                              className="text-emerald-600 hover:text-emerald-600 hover:bg-emerald-50 font-bold focus:ring-emerald-500"
                              title="Télécharger le reçu PDF"
                            >
                              <FileText className="h-4 w-4" />
                            </Button>
                          )}
                          <Button 
                            onClick={() => setSelectedTx(tx)}
                            variant="ghost" 
                            size="sm" 
                            className="text-[#1D4ED8] hover:text-[#1D4ED8] hover:bg-[#1D4ED8]/10 font-bold focus:ring-[#1D4ED8]"
                          >
                            <Eye className="h-4 w-4 mr-1.5" />
                            Voir
                          </Button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={8} className="px-4 py-12 text-center text-text-400 font-medium">
                    Aucune transaction trouvée pour ces filtres
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-border-subtle">
            <p className="text-sm text-text-400">
              Page {page} sur {totalPages}
            </p>
            <div className="flex items-center gap-2">
              <Button 
                variant="outline" 
                size="sm" 
                disabled={page <= 1} 
                onClick={() => setPage(page - 1)}
                className="focus:ring-[#1D4ED8]"
              >
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <Button 
                variant="outline" 
                size="sm" 
                disabled={page >= totalPages} 
                onClick={() => setPage(page + 1)}
                className="focus:ring-[#1D4ED8]"
              >
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        )}
      </Card>

      {/* Drawer détails transaction (Lecture Seule) */}
      {selectedTx && (
        <div className="fixed inset-0 z-50 overflow-hidden flex justify-end">
          {/* Backdrop avec flou */}
          <div 
            className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity" 
            onClick={() => setSelectedTx(null)} 
          />
          {/* Container Drawer */}
          <div className="relative w-screen max-w-md bg-layer-1 shadow-2xl border-l border-border-strong flex flex-col h-full z-10 animate-slide-in">
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-border-subtle">
              <div>
                <h3 className="text-lg font-bold text-secondary">Détails de la Transaction</h3>
                <span className="text-xs text-text-400 font-mono">{selectedTx.reference}</span>
              </div>
              <button 
                onClick={() => setSelectedTx(null)}
                className="p-1 rounded-lg text-text-400 hover:bg-layer-3 dark:hover:bg-slate-800 hover:text-text-300 transition-all focus:outline-none"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Content (Lecture Seule) */}
            <div className="flex-1 overflow-y-auto p-6 space-y-6">
              {/* Statut Badge big */}
              <div className="flex flex-col items-center p-4 bg-layer-2 dark:bg-slate-950/40 rounded-2xl border border-border-subtle/80">
                <span className="text-sm font-semibold text-text-400 mb-1">Montant payé</span>
                <span className="text-2xl font-bold text-secondary">{parseFloat(selectedTx.amount).toLocaleString('fr-FR')} {selectedTx.currency}</span>
                <Badge className={`mt-3 ${STATUS_BADGES[selectedTx.status]?.className} text-xs px-3 py-1 font-bold rounded-full`}>
                  {STATUS_BADGES[selectedTx.status]?.label || selectedTx.status}
                </Badge>
              </div>

              {/* Détails List */}
              <div className="space-y-4">
                <div className="border-b border-border-subtle pb-3">
                  <span className="text-xs font-semibold text-text-400 uppercase tracking-wider block">Service</span>
                  <span className="text-sm font-bold text-secondary block mt-1">{selectedTx.service_label}</span>
                </div>

                <div className="border-b border-border-subtle pb-3">
                  <span className="text-xs font-semibold text-text-400 uppercase tracking-wider block">Type de paiement</span>
                  <span className="text-sm font-semibold text-text-300 block mt-1">{PAYMENT_TYPE_LABELS[selectedTx.payment_type] || selectedTx.payment_type}</span>
                </div>

                <div className="border-b border-border-subtle pb-3">
                  <span className="text-xs font-semibold text-text-400 uppercase tracking-wider block">Identité du payeur</span>
                  <span className="text-sm font-semibold text-secondary block mt-1">{selectedTx.payer_name}</span>
                  <span className="text-xs text-text-400 font-mono block mt-0.5">ID: {selectedTx.payer_id}</span>
                </div>

                <div className="border-b border-border-subtle pb-3">
                  <span className="text-xs font-semibold text-text-400 uppercase tracking-wider block">Date de transaction</span>
                  <span className="text-sm font-semibold text-text-300 block mt-1">{formatDate(selectedTx.created_at)}</span>
                </div>

                {selectedTx.receipt_number && (
                  <div className="border-b border-border-subtle pb-3">
                    <span className="text-xs font-semibold text-text-400 uppercase tracking-wider block">Numéro de reçu</span>
                    <span className="text-sm font-bold text-text-300 block mt-1">{selectedTx.receipt_number}</span>
                  </div>
                )}

                {selectedTx.comment && (
                  <div className="border-b border-border-subtle pb-3">
                    <span className="text-xs font-semibold text-text-400 uppercase tracking-wider block">Commentaire</span>
                    <span className="text-sm font-semibold text-text-300 block mt-1">{selectedTx.comment}</span>
                  </div>
                )}

                {selectedTx.treasury_transfers && selectedTx.treasury_transfers.length > 0 && (
                  <div>
                    <span className="text-xs font-semibold text-text-400 uppercase tracking-wider block mb-2">Versements Trésor Public</span>
                    <div className="space-y-3">
                      {selectedTx.treasury_transfers.map((transfer) => (
                        <div key={transfer.id} className="p-3 bg-emerald-50 dark:bg-emerald-950/20 border border-emerald-100 dark:border-emerald-900/50 rounded-xl">
                          <div className="flex justify-between text-xs font-semibold text-emerald-800 dark:text-emerald-300">
                            <span>Réf Trésor: {transfer.transfer_reference}</span>
                            <span>{new Date(transfer.transferred_at).toLocaleDateString('fr-FR')}</span>
                          </div>
                          <p className="text-[10px] text-emerald-600 dark:text-emerald-400/80 mt-1">
                            Validé par: {transfer.validated_by}
                          </p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Footer */}
            <div className="p-4 border-t border-border-subtle bg-layer-2/60 flex items-center justify-between gap-2">
              {selectedTx.receipt_number ? (
                <Button 
                  onClick={() => handleDownloadReceipt(selectedTx)}
                  className="bg-emerald-600 text-white hover:bg-emerald-600/90 px-4 gap-2 focus:ring-emerald-500"
                >
                  <FileText className="h-4 w-4" />
                  Reçu PDF
                </Button>
              ) : (
                <span className="text-[11px] text-text-400 italic">Consultation uniquement</span>
              )}
              <Button 
                onClick={() => setSelectedTx(null)}
                className="bg-[#1D4ED8] text-white hover:bg-[#1D4ED8]/90 px-4 focus:ring-[#1D4ED8]"
              >
                Fermer
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
