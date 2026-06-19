// src/pages/Dossiers.jsx
import { useState, useEffect, useMemo, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { useDossiers } from '@/hooks/useDossiers';
import { getDossiers, patchDossier, assignDossier, approveDossier, rejectDossier, downloadPdf, downloadCopieLitterale } from '@/api/dossiers';
import { getCommuneList } from '@/api/communes';
import { getUserList } from '@/api/users';
import { attributionApi } from '@/services/attributionApi';
import { TYPE_DOSSIER_LABELS, STATUT_LABELS } from '@/utils/labels';
import { parseApiError } from '@/utils/parseApiError';
import { StatusBadge } from '@/components/StatusBadge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import PaymentModal from '@/components/payments/PaymentModal';
import { PdfSuccessModal } from '@/components/PdfSuccessModal';
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
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  useReactTable,
  getCoreRowModel,
  flexRender,
} from '@tanstack/react-table';
import {
  Search,
  RotateCcw,
  MoreHorizontal,
  Eye,
  UserPlus,
  CheckCircle,
  XCircle,
  FileDown,
  ChevronLeft,
  ChevronRight,
  Loader2,
  CreditCard,
} from 'lucide-react';

const STATUS_OPTIONS = [
  { value: '', label: 'Tous les statuts' },
  { value: 'submitted', label: 'Soumis' },
  { value: 'in_review', label: 'En vérification' },
  { value: 'approved', label: 'Approuvé' },
  { value: 'rejected', label: 'Rejeté' },
  { value: 'completed', label: 'Terminé' },
];

const TYPE_OPTIONS = [
  { value: '', label: 'Tous les types' },
  { value: 'birth_certificate', label: 'Acte de naissance' },
  { value: 'marriage_certificate', label: 'Acte de mariage' },
  { value: 'death_certificate', label: 'Acte de décès' },
  { value: 'residence_certificate', label: 'Certificat de résidence' },
  { value: 'regularisation', label: 'Régularisation' },
  { value: 'other', label: 'Autre' },
];

const AutoAssignButton = ({ dossier, onAssign }) => {
  const [loading, setLoading] = useState(false);

  const handleAutoAssign = async () => {
    setLoading(true);
    try {
      const recs = await attributionApi.getRecommandation(dossier.id);
      const topAgentId = Array.isArray(recs) ? recs[0]?.agent_id : recs?.recommandations?.[0]?.agent_id;
      if (!topAgentId) throw new Error("Aucune recommandation disponible");
      
      await attributionApi.reattribuerDossier(
        dossier.id, 
        topAgentId, 
        "Auto-assignation depuis la Banque des Demandes"
      );
      toast({ title: 'Succès', description: 'Agent assigné avec succès.', variant: 'success' });
      onAssign();
    } catch (error) {
      console.error("AutoAssign Error:", error);
      toast({ title: 'Erreur', description: parseApiError(error, "Impossible d'assigner l'agent."), variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Button 
      size="sm" 
      onClick={handleAutoAssign} 
      disabled={loading}
      className="h-9 px-4 text-sm bg-primary hover:bg-primary/90 text-white"
    >
      {loading ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : null}
      Assigner
    </Button>
  );
};

export default function Dossiers() {
  const navigate = useNavigate();
  const { role, user } = useAuth();
  const { data, loading, params, updateParams, setPage, refresh } = useDossiers();
  const [communes, setCommunes] = useState([]);
  const [agents, setAgents] = useState([]);
  const [searchValue, setSearchValue] = useState('');
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const [rejectModalOpen, setRejectModalOpen] = useState(false);
  const [selectedDossier, setSelectedDossier] = useState(null);
  const [selectedAgent, setSelectedAgent] = useState('');
  const [rejectionReason, setRejectionReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [agentSearch, setAgentSearch] = useState('');
  const [paymentModalOpen, setPaymentModalOpen] = useState(false);
  const [approveModalOpen, setApproveModalOpen] = useState(false);
  const [dossierToApprove, setDossierToApprove] = useState(null);
  const [pdfLoading, setPdfLoading] = useState(null);
  const [pdfSuccessDossier, setPdfSuccessDossier] = useState(null);

  // Charger les communes
  useEffect(() => {
    getCommuneList()
      .then((res) => setCommunes(Array.isArray(res) ? res : res.results || []))
      .catch((err) => console.error('Error loading communes:', err));
  }, []);

  // Charger les agents pour l'assignation
  useEffect(() => {
    const baseParams = {};
    const userCommuneId = typeof user?.commune === 'object' ? user.commune?.id : user?.commune;
    if (role === 'civil_admin' && userCommuneId) {
      baseParams.commune = userCommuneId;
    }
    
    Promise.all([
      getUserList({ ...baseParams, role: 'verification_agent' }),
      getUserList({ ...baseParams, role: 'reception_agent' })
    ])
      .then(([verifData, receptData]) => {
        const verifList = Array.isArray(verifData) ? verifData : verifData.results || [];
        const receptList = Array.isArray(receptData) ? receptData : receptData.results || [];
        setAgents([...verifList, ...receptList]);
      })
      .catch((err) => {
        console.error('Error loading agents:', err);
        setAgents([]);
      });
  }, [role, user]);

  // Debounce sur la recherche
  useEffect(() => {
    const timer = setTimeout(() => {
      updateParams({ search: searchValue });
    }, 300);
    return () => clearTimeout(timer);
  }, [searchValue, updateParams]);

  // Reset des filtres
  const handleReset = () => {
    setSearchValue('');
    updateParams({ status: '', type: '', commune: '', search: '', page: 1 });
  };

  // --- NOUVEAU : Connexion Temps Réel (WebSockets) ---
  useEffect(() => {
    // Construction de l'URL WebSocket à partir de l'URL de l'API
    const baseUrl = import.meta.env.VITE_API_URL || 'http://127.0.0.1:8000/api';
    const wsUrl = baseUrl.replace('http', 'ws').replace('/api', '/ws/dashboard/');
      
    const ws = new WebSocket(wsUrl);

    ws.onopen = () => console.log('🔗 Connecté au serveur Temps Réel (Banque des Demandes)');

    ws.onmessage = (event) => {
      const parsed = JSON.parse(event.data);
      if (parsed.message === 'new_dossier') {
        // Notification toast visuelle
        toast({
          title: 'Nouvelle demande ! 📄',
          description: `Une nouvelle demande (${parsed.data.reference}) vient d'être soumise.`,
          variant: 'default',
          className: 'bg-blue-50 border-blue-200 text-blue-900',
        });
        // Rafraîchir les données silencieusement
        refresh();
      }
    };

    ws.onclose = () => console.log('❌ Déconnecté du serveur Temps Réel');

    // Nettoyage à la fermeture de la page
    return () => ws.close();
  }, [refresh]);

  // Actions sur un dossier
  const handleApprove = async () => {
    if (!dossierToApprove) return;
    setActionLoading(true);
    try {
      await approveDossier(dossierToApprove.id);
      toast({ title: 'Demande approuvée', description: `${dossierToApprove.reference} a été approuvée.`, variant: 'success' });
      setApproveModalOpen(false);
      setDossierToApprove(null);
      refresh();
    } catch (error) {
      toast({ title: 'Erreur', description: parseApiError(error, 'Impossible d\'approuver la demande.'), variant: 'destructive' });
    } finally {
      setActionLoading(false);
    }
  };

  const handleAssign = async () => {
    if (!selectedAgent || !selectedDossier) return;
    setActionLoading(true);
    try {
      await assignDossier(selectedDossier.id, selectedAgent);
      toast({ title: 'Agent assigné', description: `Agent assigné à la demande ${selectedDossier.reference}.`, variant: 'success' });
      setAssignModalOpen(false);
      setSelectedAgent('');
      setSelectedDossier(null);
      refresh();
    } catch (error) {
      toast({ title: 'Erreur', description: parseApiError(error, 'Impossible d\'assigner l\'agent.'), variant: 'destructive' });
    } finally {
      setActionLoading(false);
    }
  };

  const handleDownloadPdf = async (dossier) => {
    setPdfLoading(dossier.id);
    try {
      const blob = await downloadPdf(dossier.id);
      const url = window.URL.createObjectURL(new Blob([blob]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Certificat_${dossier.reference}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      setPdfSuccessDossier(dossier);
    } catch (err) {
      console.error(err);
      toast({
        title: 'Erreur',
        description: parseApiError(err, 'Impossible de télécharger le PDF.'),
        variant: 'destructive',
      });
    } finally {
      setPdfLoading(null);
    }
  };

  const handleDownloadCopieLitterale = async (dossier) => {
    setPdfLoading(`copie_${dossier.id}`);
    try {
      const blob = await downloadCopieLitterale(dossier.id);
      const url = window.URL.createObjectURL(new Blob([blob]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Copie_Litterale_${dossier.reference}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      setPdfSuccessDossier(dossier);
    } catch (err) {
      console.error(err);
      toast({
        title: 'Erreur',
        description: parseApiError(err, 'Impossible de télécharger la copie littérale.'),
        variant: 'destructive',
      });
    } finally {
      setPdfLoading(null);
    }
  };

  const handleReject = async () => {
    if (!rejectionReason || rejectionReason.length < 20 || !selectedDossier) return;
    setActionLoading(true);
    try {
      await rejectDossier(selectedDossier.id, rejectionReason);
      toast({ title: 'Demande rejetée', description: `${selectedDossier.reference} a été rejetée.`, variant: 'success' });
      setRejectModalOpen(false);
      setRejectionReason('');
      setSelectedDossier(null);
      refresh();
    } catch (error) {
      toast({ title: 'Erreur', description: 'Impossible de rejeter la demande.', variant: 'destructive' });
    } finally {
      setActionLoading(false);
    }
  };

  // Colonnes TanStack Table
  const columns = useMemo(() => {
    const baseCols = [
      {
        accessorKey: 'reference',
        header: 'Référence',
        cell: ({ row }) => (
          <button
            onClick={() => navigate(`/dossiers/${row.original.id}`)}
            className="text-primary font-medium hover:underline"
          >
            {row.original.reference}
          </button>
        ),
      },
      {
        accessorKey: 'type_display',
        header: 'Type',
        cell: ({ row }) => (
          <span className="text-sm text-text-300">{TYPE_DOSSIER_LABELS[row.original.type] || row.original.type_display}</span>
        ),
      },
      {
        accessorKey: 'status',
        header: 'Statut',
        cell: ({ row }) => (
          <span className="text-sm font-medium">
            {STATUT_LABELS[row.original.status] || <StatusBadge status={row.original.status} />}
          </span>
        ),
      },
      {
        accessorKey: 'citizen',
        header: 'Citoyen',
        cell: ({ row }) => (
          <span className="text-sm text-text-200 font-medium">
            {row.original.citizen?.full_name || '—'}
          </span>
        ),
      },
      {
        accessorKey: 'commune',
        header: 'Commune',
        cell: ({ row }) => (
          <span className="text-sm text-text-300">{row.original.commune?.name || '—'}</span>
        ),
      },
      {
        accessorKey: 'assigned_agent',
        header: 'Agent',
        cell: ({ row }) => {
          if (row.original.assigned_agent) {
            return (
              <span className="text-sm text-text-300">
                {row.original.assigned_agent.full_name || row.original.assigned_agent.email}
              </span>
            );
          }
          return ['super_admin', 'civil_admin'].includes(role) ? (
            <AutoAssignButton dossier={row.original} onAssign={refresh} />
          ) : (
            <span className="text-sm text-text-400 italic">Non assigné</span>
          );
        },
      },
      {
        accessorKey: 'created_at',
        header: 'Date',
        cell: ({ row }) => (
          <span className="text-sm text-text-400">
            {row.original.created_at
              ? new Date(row.original.created_at).toLocaleDateString('fr-FR', {
                  day: '2-digit',
                  month: 'short',
                  year: 'numeric',
                })
              : '—'}
          </span>
        ),
      },
      {
        id: 'actions',
        header: '',
        cell: ({ row }) => {
          const dossier = row.original;
          return (
            <div className="flex items-center gap-2 justify-end">
              {['agent', 'verification_agent', 'approval_agent', 'civil_admin'].includes(role) && ['submitted', 'in_review'].includes(dossier.status) && (
                <Button 
                  size="sm" 
                  onClick={() => navigate(`/dossiers/${dossier.id}`)}
                  className="h-9 text-sm bg-primary hover:bg-primary/90 text-white"
                >
                  Traiter
                </Button>
              )}
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="icon" className="h-8 w-8">
                    <MoreHorizontal className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-48">
                  <DropdownMenuItem onClick={() => navigate(`/dossiers/${dossier.id}`)}>
                  <Eye className="h-4 w-4 mr-2" /> Voir
                </DropdownMenuItem>
                {['super_admin', 'civil_admin'].includes(role) && (
                  <DropdownMenuItem
                    onClick={() => {
                      setSelectedDossier(dossier);
                      setAssignModalOpen(true);
                    }}
                  >
                    <UserPlus className="h-4 w-4 mr-2" /> Assigner agent
                  </DropdownMenuItem>
                )}
                {['reception_agent', 'civil_admin', 'super_admin'].includes(role) && dossier.status === 'draft' && (
                  <DropdownMenuItem
                    onClick={() => {
                      setSelectedDossier(dossier);
                      setPaymentModalOpen(true);
                    }}
                  >
                    <CreditCard className="h-4 w-4 mr-2 text-primary" /> Enregistrer un paiement
                  </DropdownMenuItem>
                )}
                <DropdownMenuSeparator />
                {['super_admin', 'civil_admin', 'agent'].includes(role) && dossier.status === 'in_review' && (
                  <DropdownMenuItem onClick={() => {
                    setDossierToApprove(dossier);
                    setApproveModalOpen(true);
                  }}>
                    <CheckCircle className="h-4 w-4 mr-2 text-success" /> Valider
                  </DropdownMenuItem>
                )}
                {['super_admin', 'civil_admin', 'agent'].includes(role) && (dossier.status === 'submitted' || dossier.status === 'in_review') && (
                  <DropdownMenuItem
                    onClick={() => {
                      setSelectedDossier(dossier);
                      setRejectModalOpen(true);
                    }}
                    className="text-danger"
                  >
                    <XCircle className="h-4 w-4 mr-2" /> Rejeter
                  </DropdownMenuItem>
                )}
                <DropdownMenuSeparator />
                {!['approved', 'completed'].includes(dossier.status) && (
                  <DropdownMenuItem 
                    disabled
                    title={"Le PDF n'est pas encore généré"}
                  >
                    <FileDown className="h-4 w-4 mr-2" />
                    PDF
                  </DropdownMenuItem>
                )}
                {dossier.type === 'birth_certificate' && !['approved', 'completed'].includes(dossier.status) && (
                  <DropdownMenuItem 
                    disabled
                    title={"La copie littérale n'est pas encore générée"}
                  >
                    <FileDown className="h-4 w-4 mr-2" />
                    Copie Littérale
                  </DropdownMenuItem>
                )}
              </DropdownMenuContent>
              </DropdownMenu>

              {['approved', 'completed'].includes(dossier.status) && (
                <>
                  <Button 
                    variant="outline" 
                    size="sm" 
                    onClick={() => handleDownloadPdf(dossier)}
                    disabled={pdfLoading === dossier.id}
                    title="Télécharger le PDF"
                    className="h-8 text-xs gap-2"
                  >
                    {pdfLoading === dossier.id ? <Loader2 className="h-4 w-4 animate-spin" /> : <FileDown className="h-4 w-4" />}
                    PDF
                  </Button>
                  
                  {dossier.type === 'birth_certificate' && (
                    <Button 
                      variant="outline" 
                      size="sm" 
                      onClick={() => handleDownloadCopieLitterale(dossier)}
                      disabled={pdfLoading === `copie_${dossier.id}`}
                      title="Télécharger la Copie Littérale"
                      className="h-8 text-xs gap-2"
                    >
                      {pdfLoading === `copie_${dossier.id}` ? <Loader2 className="h-4 w-4 animate-spin" /> : <FileDown className="h-4 w-4" />}
                      Copie
                    </Button>
                  )}
                </>
              )}
            </div>
          );
        },
      },
    ];

    if (['agent', 'verification_agent', 'reception_agent'].includes(role)) {
      return baseCols.filter(c => c.accessorKey !== 'commune');
    }
    return baseCols;
  }, [navigate, refresh, role, pdfLoading]);

  const table = useReactTable({
    data: data.results || [],
    columns,
    getCoreRowModel: getCoreRowModel(),
    manualPagination: true,
    pageCount: Math.ceil((data.count || 0) / 20),
  });

  const totalPages = Math.ceil((data.count || 0) / 20);
  const currentPage = params.page || 1;

  // Filtrer les agents pour le modal
  const filteredAgents = agents.filter(
    (a) => {
      const matchSearch = a.full_name?.toLowerCase().includes(agentSearch.toLowerCase()) ||
                          a.email?.toLowerCase().includes(agentSearch.toLowerCase());
      const agentCommuneId = typeof a.commune === 'object' ? a.commune?.id : a.commune;
      const dossierCommuneId = typeof selectedDossier?.commune === 'object' ? selectedDossier?.commune?.id : selectedDossier?.commune;
      const matchCommune = !selectedDossier || agentCommuneId === dossierCommuneId;
      return matchSearch && matchCommune;
    }
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-secondary">Banque des Demandes</h1>
        <p className="text-sm text-text-400 mt-1">
          {data.count || 0} demande{(data.count || 0) > 1 ? 's' : ''} enregistrée{(data.count || 0) > 1 ? 's' : ''}
        </p>
      </div>

      {/* Barre de filtres */}
      <Card className="p-4 border-border-subtle">
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative flex-1 min-w-[200px]">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-text-400" />
            <Input
              placeholder="Rechercher par référence..."
              value={searchValue}
              onChange={(e) => setSearchValue(e.target.value)}
              className="pl-9"
            />
          </div>
          <Select
            value={params.status || ''}
            onValueChange={(val) => updateParams({ status: val })}
          >
            <SelectTrigger className="w-[180px]">
              <SelectValue placeholder="Tous les statuts" />
            </SelectTrigger>
            <SelectContent>
              {STATUS_OPTIONS.map((opt) => (
                <SelectItem key={opt.value || 'all-status'} value={opt.value || 'all'}>
                  {opt.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select
            value={params.type || ''}
            onValueChange={(val) => updateParams({ type: val })}
          >
            <SelectTrigger className="w-[200px]">
              <SelectValue placeholder="Tous les types" />
            </SelectTrigger>
            <SelectContent>
              {TYPE_OPTIONS.map((opt) => (
                <SelectItem key={opt.value || 'all-type'} value={opt.value || 'all'}>
                  {opt.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {role !== 'civil_admin' && (
            <Select
              value={params.commune || ''}
              onValueChange={(val) => updateParams({ commune: val })}
            >
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Toutes communes" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Toutes communes</SelectItem>
                {communes.map((c) => (
                  <SelectItem key={c.id} value={String(c.id)}>
                    {c.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}
          <Button variant="outline" size="sm" onClick={handleReset} className="gap-2">
            <RotateCcw className="h-4 w-4" />
            Réinitialiser
          </Button>
        </div>
      </Card>

      {/* Table */}
      <Card className="table-container">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-border-subtle bg-layer-2">
                {table.getHeaderGroups().map((headerGroup) =>
                  headerGroup.headers.map((header) => (
                    <th
                      key={header.id}
                      className="px-4 py-3 text-left text-xs font-semibold text-text-400 uppercase tracking-wider"
                    >
                      {header.isPlaceholder
                        ? null
                        : flexRender(header.column.columnDef.header, header.getContext())}
                    </th>
                  ))
                )}
              </tr>
            </thead>
            <tbody className="animate-in fade-in duration-300">
              {loading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i} className="border-b border-border-subtle">
                    {columns.map((_, j) => (
                      <td key={j} className="px-4 py-3">
                        <Skeleton className="h-5 w-full" />
                      </td>
                    ))}
                  </tr>
                ))
              ) : table.getRowModel().rows.length > 0 ? (
                table.getRowModel().rows.map((row) => (
                  <tr
                    key={row.id}
                    className="border-b border-border-subtle hover:bg-layer-2 transition-colors"
                  >
                    {row.getVisibleCells().map((cell) => (
                      <td key={cell.id} className="px-4 py-3">
                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                      </td>
                    ))}
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={columns.length} className="px-4 py-12 text-center text-text-400">
                    Aucune demande trouvée
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
              Page {currentPage} sur {totalPages} — {data.count} résultat{data.count > 1 ? 's' : ''}
            </p>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={currentPage <= 1}
                onClick={() => setPage(currentPage - 1)}
              >
                <ChevronLeft className="h-4 w-4" />
              </Button>
              {[...Array(Math.min(totalPages, 5))].map((_, i) => {
                let pageNum;
                if (totalPages <= 5) {
                  pageNum = i + 1;
                } else if (currentPage <= 3) {
                  pageNum = i + 1;
                } else if (currentPage >= totalPages - 2) {
                  pageNum = totalPages - 4 + i;
                } else {
                  pageNum = currentPage - 2 + i;
                }
                return (
                  <Button
                    key={pageNum}
                    variant={currentPage === pageNum ? 'default' : 'outline'}
                    size="sm"
                    className="w-9"
                    onClick={() => setPage(pageNum)}
                  >
                    {pageNum}
                  </Button>
                );
              })}
              <Button
                variant="outline"
                size="sm"
                disabled={currentPage >= totalPages}
                onClick={() => setPage(currentPage + 1)}
              >
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        )}
      </Card>

      {/* Modal Assignation */}
      <Dialog open={assignModalOpen} onOpenChange={setAssignModalOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Assigner un agent</DialogTitle>
            <DialogDescription>
              Sélectionnez l'agent à assigner à la demande {selectedDossier?.reference}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <Input
              placeholder="Rechercher un agent..."
              value={agentSearch}
              onChange={(e) => setAgentSearch(e.target.value)}
            />
            <div className="max-h-[300px] overflow-y-auto space-y-1">
              {filteredAgents.length > 0 ? (
                filteredAgents.map((agent) => (
                  <button
                    key={agent.id}
                    onClick={() => setSelectedAgent(String(agent.id))}
                    className={`w-full text-left p-3 rounded-lg transition-colors ${
                      selectedAgent === String(agent.id)
                        ? 'bg-primary/10 border border-primary/30'
                        : 'hover:bg-layer-2 border border-transparent'
                    }`}
                  >
                    <p className="text-sm font-medium text-secondary">{agent.full_name}</p>
                    <p className="text-xs text-text-400">{agent.email}</p>
                  </button>
                ))
              ) : (
                <p className="text-sm text-text-400 text-center py-4">Aucun agent trouvé</p>
              )}
            </div>
          </div>
          <DialogFooter className="mt-4 pt-4 border-t">
            <Button variant="outline" onClick={() => setAssignModalOpen(false)}>
              Annuler
            </Button>
            <Button onClick={handleAssign} disabled={!selectedAgent || actionLoading}>
              {actionLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              Confirmer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Rejet */}
      <Dialog open={rejectModalOpen} onOpenChange={setRejectModalOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-danger">Rejeter la demande</DialogTitle>
            <DialogDescription>
              Indiquez le motif du rejet pour la demande {selectedDossier?.reference}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3">
            <textarea
              placeholder="Motif du rejet (minimum 20 caractères)..."
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              className="w-full min-h-[120px] p-3 rounded-lg border border-border-strong text-sm focus:outline-none focus:ring-2 focus:ring-primary resize-none"
            />
            <p className="text-xs text-text-400">
              {rejectionReason.length}/20 caractères minimum
              {rejectionReason.length >= 20 && (
                <span className="text-success ml-2">✓</span>
              )}
            </p>
          </div>
          <DialogFooter className="mt-4 pt-4 border-t">
            <Button variant="outline" onClick={() => setRejectModalOpen(false)}>
              Annuler
            </Button>
            <Button
              variant="destructive"
              onClick={handleReject}
              disabled={rejectionReason.length < 20 || actionLoading}
            >
              {actionLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              Confirmer le rejet
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Approbation */}
      <Dialog open={approveModalOpen} onOpenChange={setApproveModalOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Valider la demande</DialogTitle>
            <DialogDescription>
              Vous allez approuver la demande <strong>{dossierToApprove?.reference}</strong>.
              Cette action générera un acte officiel certifié.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="mt-4 pt-4 border-t">
            <Button variant="outline" onClick={() => setApproveModalOpen(false)}>
              Annuler
            </Button>
            <Button
              onClick={handleApprove}
              disabled={actionLoading}
              className="bg-emerald-600 hover:bg-emerald-700 text-white"
            >
              {actionLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              Confirmer la validation
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Paiement */}
      <PaymentModal
        isOpen={paymentModalOpen}
        onClose={() => {
          setPaymentModalOpen(false);
          setSelectedDossier(null);
        }}
        dossier={selectedDossier}
        onSuccess={refresh}
      />

      {/* Modal Succès PDF */}
      <PdfSuccessModal
        isOpen={!!pdfSuccessDossier}
        onClose={() => setPdfSuccessDossier(null)}
        dossier={pdfSuccessDossier}
        onDownloadAgain={handleDownloadPdf}
      />
    </div>
  );
}
