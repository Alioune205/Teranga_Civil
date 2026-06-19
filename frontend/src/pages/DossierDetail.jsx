// src/pages/DossierDetail.jsx
import { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { getDossier, patchDossier, reviewDossier, approveDossier, rejectDossier, completeDossier, downloadPdf } from '@/api/dossiers';
import { StatusBadge } from '@/components/StatusBadge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { toast } from '@/components/ui/use-toast';
import SecureImage from '@/components/ui/SecureImage';
import { clearSecureImageCache } from '@/hooks/useSecureImage';
import { useAuth } from '@/hooks/useAuth';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  ArrowLeft,
  User,
  Building2,
  Calendar,
  FileText,
  Loader2,
  CheckCircle,
  XCircle,
  PlayCircle,
  FileDown,
  ExternalLink,
  Check,
  X,
  Clock,
  Flag,
  Edit,
} from 'lucide-react';

const WORKFLOW_STEPS = [
  { key: 'draft', label: 'Brouillon', icon: FileText },
  { key: 'submitted', label: 'Soumis', icon: Clock },
  { key: 'in_review', label: 'En vérification', icon: PlayCircle },
  { key: 'approved_or_rejected', label: 'Approuvé/Rejeté', icon: CheckCircle },
  { key: 'completed', label: 'Terminé', icon: Flag },
];

const STATUS_ORDER = ['draft', 'submitted', 'in_review', 'validated', 'generated', 'approved', 'delivered', 'completed', 'rejected'];

function getStepStatus(stepKey, currentStatus) {
  const currentIndex = STATUS_ORDER.indexOf(currentStatus);
  
  if (stepKey === 'approved_or_rejected') {
    if (currentStatus === 'rejected') return 'rejected';
    if (['validated', 'generated', 'approved'].includes(currentStatus)) return 'passed';
    if (currentIndex >= STATUS_ORDER.indexOf('approved') && currentStatus !== 'rejected') return 'passed';
    return 'future';
  }
  
  const stepMapping = {
    draft: 0,
    submitted: 1,
    in_review: 2,
    completed: 8,
  };
  
  const stepIndex = stepMapping[stepKey];
  if (stepIndex === undefined) return 'future';
  
  if (stepKey === 'completed') {
    return ['delivered', 'completed'].includes(currentStatus) ? 'passed' : 'future';
  }
  
  if (stepIndex < currentIndex) return 'passed';
  if (stepIndex === currentIndex) return 'active';
  return 'future';
}

export default function DossierDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { role } = useAuth();
  const [dossier, setDossier] = useState(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [rejectDialogOpen, setRejectDialogOpen] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');
  const [selectedDocument, setSelectedDocument] = useState(null);
  const [verificationChecks, setVerificationChecks] = useState({
    cni_recto: false,
    attestation_delegue: false,
    constat_medecin: false,
    cni_defunt: false,
    cni_temoin1: false,
    cni_temoin2: false,
    cni_epoux: false,
    cni_epouse: false,
    cni_temoins: false,
  });
  
  const [editMetadataOpen, setEditMetadataOpen] = useState(false);
  const [metadataForm, setMetadataForm] = useState({
    prenoms_enfant: '',
    nom_enfant: '',
    date_naissance_personne: '',
    heure_naissance: '',
    lieu_naissance: '',
    sexe: '',
    prenom_pere: '',
    prenom_mere: '',
    nom_mere: '',
    annee_registre: '',
    numero_registre: '',
    // Mariage
    nom_epoux: '',
    nom_epouse: '',
    annee_marriage: '',
    registre_marriage: '',
    // Décès
    nom_defunt: '',
    date_deces: '',
    nom_declarant: '',
    lien_parente: '',
    registre: ''
  });

  const isApprovalDisabled = () => {
    if (!dossier) return true;
    if (dossier.type === 'residence_certificate') {
      return !verificationChecks.cni_recto || !verificationChecks.attestation_delegue;
    }
    if (dossier.type === 'death_certificate') {
      if (!verificationChecks.constat_medecin || !verificationChecks.cni_defunt) return true;
      if (dossier.metadata?.deces_domicile) {
        if (!verificationChecks.cni_temoin1 || !verificationChecks.cni_temoin2) return true;
      }
      return false;
    }
    if (dossier.type === 'marriage_certificate') {
      return !verificationChecks.cni_epoux || !verificationChecks.cni_epouse || !verificationChecks.cni_temoins;
    }
    return false;
  };

  useEffect(() => {
    fetchDossier();
    return () => {
      clearSecureImageCache();
    };
  }, [id]);

  const fetchDossier = async () => {
    setLoading(true);
    try {
      const data = await getDossier(id);
      setDossier(data);
    } catch (error) {
      toast({ title: 'Erreur', description: 'Impossible de charger le dossier.', variant: 'destructive' });
      navigate('/dossiers');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (newStatus) => {
    try {
      setActionLoading(true);
      if (newStatus === 'in_review') await reviewDossier(dossier.id);
      if (newStatus === 'approved') await approveDossier(dossier.id);
      if (newStatus === 'completed') await completeDossier(dossier.id);
      await fetchDossier();
      toast({ title: 'Succès', description: 'Statut mis à jour.', variant: 'success' });
    } catch (err) {
      toast({ title: 'Erreur', description: "Impossible de modifier le statut.", variant: 'destructive' });
    } finally {
      setActionLoading(false);
    }
  };

  const handleDownloadPdf = async () => {
    try {
      setActionLoading(true);
      const blob = await downloadPdf(dossier.id);
      const url = window.URL.createObjectURL(new Blob([blob]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Certificat_${dossier.reference}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.parentNode.removeChild(link);
      toast({
        title: 'PDF téléchargé',
        description: `Le certificat ${dossier.reference} a été téléchargé avec succès.`,
        variant: 'success',
      });
    } catch (err) {
      toast({
        title: 'Erreur',
        description: 'Impossible de télécharger le PDF. Il se peut qu\'il ne soit pas encore généré.',
        variant: 'destructive',
      });
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (rejectionReason.length < 20) return;
    setActionLoading(true);
    try {
      await rejectDossier(id, rejectionReason);
      toast({ title: 'Dossier rejeté', description: 'Le dossier a été rejeté.', variant: 'success' });
      setRejectDialogOpen(false);
      setRejectionReason('');
      fetchDossier();
    } catch (error) {
      toast({ title: 'Erreur', description: 'Impossible de rejeter le dossier.', variant: 'destructive' });
    } finally {
      setActionLoading(false);
    }
  };

  const handleOpenEdit = () => {
    setMetadataForm({
      prenoms_enfant: dossier.metadata?.prenoms_enfant || '',
      nom_enfant: dossier.metadata?.nom_enfant || dossier.metadata?.nom || '',
      date_naissance_personne: dossier.metadata?.date_naissance_personne || dossier.metadata?.date_naissance || '',
      heure_naissance: dossier.metadata?.heure_naissance || '',
      lieu_naissance: dossier.metadata?.lieu_naissance || '',
      sexe: dossier.metadata?.sexe || '',
      prenom_pere: dossier.metadata?.prenom_pere || '',
      prenom_mere: dossier.metadata?.prenom_mere || '',
      nom_mere: dossier.metadata?.nom_mere || '',
      annee_registre: dossier.metadata?.annee_registre || '',
      numero_registre: dossier.metadata?.numero_registre || dossier.metadata?.registre || ''
    });
    setEditMetadataOpen(true);
  };

  const handleSaveMetadata = async () => {
    try {
      setActionLoading(true);
      await patchDossier(id, { metadata: { ...dossier.metadata, ...metadataForm } });
      toast({
        title: "Succès",
        description: "Les informations ont été mises à jour.",
        variant: "success"
      });
      setEditMetadataOpen(false);
      fetchDossier();
    } catch (error) {
      console.error('Erreur save metadata', error);
      
      // Handle the specific business error for death certificate > 1 year
      const errorData = error.response?.data;
      if (errorData && (errorData.date_deces || errorData.non_field_errors)) {
        const errorMsg = errorData.date_deces?.[0] || errorData.non_field_errors?.[0];
        if (errorMsg && errorMsg.includes('1 an')) {
          toast({
            title: "Délai dépassé",
            description: "Le décès remonte à plus d'un an. Un jugement supplétif est requis. Veuillez rejeter le dossier.",
            variant: "destructive"
          });
          return;
        }
      }

      toast({
        title: "Erreur",
        description: "Impossible de mettre à jour le dossier.",
        variant: "destructive"
      });
    } finally {
      setActionLoading(false);
    }
  };

  const formatDate = (dateStr) => {
    if (!dateStr) return '—';
    return new Date(dateStr).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (loading) {
    return (
      <div className="space-y-6 animate-enter">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-20 w-full" />
        <div className="grid grid-cols-2 gap-6">
          <Skeleton className="h-64" />
          <Skeleton className="h-64" />
        </div>
      </div>
    );
  }

  if (!dossier) return null;

  return (
    <div className="space-y-6 animate-enter">
      {/* Breadcrumb + En-tête */}
      <div>
        <div className="flex items-center gap-2 text-sm text-text-400 mb-4">
          <Link to="/dossiers" className="hover:text-primary transition-colors">
            Dossiers
          </Link>
          <span>/</span>
          <span className="text-secondary font-medium">{dossier.reference}</span>
        </div>

        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div className="flex items-center gap-4">
            <Button variant="outline" size="icon" onClick={() => navigate('/dossiers')}>
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
              <div className="flex items-center gap-3">
                <h1 className="text-2xl font-bold text-secondary">{dossier.reference}</h1>
                <StatusBadge status={dossier.status} />
              </div>
              <p className="text-sm text-text-400 mt-1">{dossier.type_display}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Timeline horizontale */}
      <Card className="border-border-subtle p-6">
        <div className="flex items-center justify-between">
          {WORKFLOW_STEPS.map((step, index) => {
            const stepStatus = getStepStatus(step.key, dossier.status);
            const StepIcon = step.icon;

            return (
              <div key={step.key} className="flex items-center flex-1">
                <div className="flex flex-col items-center gap-2 relative">
                  <div
                    className={`w-10 h-10 rounded-full flex items-center justify-center border-2 transition-all duration-300 ${
                      stepStatus === 'active'
                        ? 'bg-primary border-primary text-white shadow-lg shadow-primary/30'
                        : stepStatus === 'passed'
                        ? 'bg-success border-success text-white'
                        : stepStatus === 'rejected'
                        ? 'bg-danger border-danger text-white'
                        : 'bg-white border-border-strong text-text-400'
                    }`}
                  >
                    {stepStatus === 'passed' ? (
                      <Check className="h-5 w-5" />
                    ) : stepStatus === 'rejected' ? (
                      <X className="h-5 w-5" />
                    ) : (
                      <StepIcon className="h-5 w-5" />
                    )}
                  </div>
                  <span
                    className={`text-xs font-medium text-center whitespace-nowrap ${
                      stepStatus === 'active'
                        ? 'text-primary'
                        : stepStatus === 'passed'
                        ? 'text-success'
                        : stepStatus === 'rejected'
                        ? 'text-danger'
                        : 'text-text-400'
                    }`}
                  >
                    {step.label}
                  </span>
                </div>
                {index < WORKFLOW_STEPS.length - 1 && (
                  <div
                    className={`flex-1 h-0.5 mx-2 mt-[-20px] ${
                      stepStatus === 'passed' || stepStatus === 'active'
                        ? 'bg-success'
                        : stepStatus === 'rejected'
                        ? 'bg-danger'
                        : 'bg-border-strong'
                    }`}
                  />
                )}
              </div>
            );
          })}
        </div>
      </Card>

      {/* Deux colonnes d'infos */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Colonne gauche */}
        <div className="space-y-6">
          {/* Citoyen */}
          <Card className="border-border-subtle">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-semibold text-secondary flex items-center gap-2">
                <User className="h-4 w-4 text-primary" />
                Citoyen
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <InfoRow label="Nom complet" value={dossier.citizen?.full_name} />
              <InfoRow label="Email" value={dossier.citizen?.email} />
              <InfoRow label="Téléphone" value={dossier.citizen?.phone} />
            </CardContent>
          </Card>

          {/* Commune */}
          <Card className="border-border-subtle">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-semibold text-secondary flex items-center gap-2">
                <Building2 className="h-4 w-4 text-primary" />
                Commune
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <InfoRow label="Commune" value={dossier.commune?.name} />
              <InfoRow label="Région" value={dossier.commune?.region} />
            </CardContent>
          </Card>

          {/* Informations du Certificat */}
          <Card className="border-border-subtle">
            <CardHeader className="pb-3 flex flex-row items-center justify-between">
              <CardTitle className="text-base font-semibold text-secondary flex items-center gap-2">
                <FileText className="h-4 w-4 text-primary" />
                Informations du Certificat
              </CardTitle>
              {dossier.status === 'in_review' && role !== 'super_admin' && (
                <Button variant="outline" size="sm" onClick={handleOpenEdit} className="h-8 gap-1">
                  <Edit className="h-3.5 w-3.5" /> Éditer
                </Button>
              )}
            </CardHeader>
            <CardContent className="space-y-3">
              {dossier.type === 'marriage_certificate' ? (
                <>
                  <div className="mb-2">
                    <p className="text-xs font-semibold text-primary mb-1 uppercase">Époux</p>
                    <InfoRow label="Nom de l'époux" value={dossier.metadata?.nom_epoux} />
                  </div>
                  <div className="mb-2">
                    <p className="text-xs font-semibold text-primary mb-1 uppercase mt-3">Épouse</p>
                    <InfoRow label="Nom de l'épouse" value={dossier.metadata?.nom_epouse} />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-primary mb-1 uppercase mt-3">Registre</p>
                    <InfoRow label="Année" value={dossier.metadata?.annee_marriage} />
                    <InfoRow label="Numéro" value={dossier.metadata?.registre_marriage} />
                  </div>
                </>
              ) : dossier.type === 'death_certificate' ? (
                <>
                  <div className="mb-2">
                    <p className="text-xs font-semibold text-primary mb-1 uppercase">Défunt</p>
                    <InfoRow label="Nom du défunt" value={dossier.metadata?.nom_defunt} />
                    <InfoRow label="Date du décès" value={dossier.metadata?.date_deces} />
                  </div>
                  <div className="mb-2">
                    <p className="text-xs font-semibold text-primary mb-1 uppercase mt-3">Déclarant</p>
                    <InfoRow label="Nom du déclarant" value={dossier.metadata?.nom_declarant} />
                    <InfoRow label="Lien de parenté" value={dossier.metadata?.lien_parente} />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-primary mb-1 uppercase mt-3">Registre</p>
                    <InfoRow label="Numéro" value={dossier.metadata?.registre} />
                  </div>
                </>
              ) : (
                <>
                  <div className="mb-2">
                    <p className="text-xs font-semibold text-primary mb-1 uppercase">L'enfant</p>
                    <InfoRow label="Prénoms" value={dossier.metadata?.prenoms_enfant} />
                    <InfoRow label="Nom" value={dossier.metadata?.nom_enfant || dossier.metadata?.nom} />
                    <InfoRow label="Né(e) le" value={dossier.metadata?.date_naissance_personne || dossier.metadata?.date_naissance} />
                    <InfoRow label="Heure" value={dossier.metadata?.heure_naissance} />
                    <InfoRow label="Lieu" value={dossier.metadata?.lieu_naissance} />
                    <InfoRow label="Sexe" value={dossier.metadata?.sexe} />
                  </div>
                  <div className="mb-2">
                    <p className="text-xs font-semibold text-primary mb-1 uppercase mt-3">Parents</p>
                    <InfoRow label="Prénom du père" value={dossier.metadata?.prenom_pere} />
                    <InfoRow label="Prénoms de la mère" value={dossier.metadata?.prenom_mere} />
                    <InfoRow label="Nom de la mère" value={dossier.metadata?.nom_mere} />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-primary mb-1 uppercase mt-3">Registre</p>
                    <InfoRow label="Année" value={dossier.metadata?.annee_registre} />
                    <InfoRow label="Numéro" value={dossier.metadata?.numero_registre || dossier.metadata?.registre} />
                  </div>
                </>
              )}
            </CardContent>
          </Card>

          {/* Agent assigné */}
          <Card className="border-border-subtle">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-semibold text-secondary flex items-center gap-2">
                <User className="h-4 w-4 text-primary" />
                Agent assigné
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {dossier.assigned_agent ? (
                <>
                  <InfoRow label="Nom" value={dossier.assigned_agent.full_name} />
                  <InfoRow label="Email" value={dossier.assigned_agent.email} />
                </>
              ) : (
                <p className="text-sm text-text-400 italic">Aucun agent assigné</p>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Colonne droite */}
        <div className="space-y-6">
          {/* Dates */}
          <Card className="border-border-subtle">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-semibold text-secondary flex items-center gap-2">
                <Calendar className="h-4 w-4 text-primary" />
                Chronologie
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <InfoRow label="Créé le" value={formatDate(dossier.created_at)} />
              <InfoRow label="Soumis le" value={formatDate(dossier.submitted_at)} />
              <InfoRow label="Terminé le" value={formatDate(dossier.completed_at)} />
            </CardContent>
          </Card>

          {/* Notes internes */}
          <Card className="border-border-subtle">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-semibold text-secondary flex items-center gap-2">
                <FileText className="h-4 w-4 text-primary" />
                Notes internes
              </CardTitle>
            </CardHeader>
            <CardContent>
              {dossier.notes ? (
                <p className="text-sm text-text-300 whitespace-pre-wrap">{dossier.notes}</p>
              ) : (
                <p className="text-sm text-text-400 italic">Aucune note</p>
              )}
              {dossier.rejection_reason && (
                <div className="mt-4 p-3 bg-danger/5 border border-danger/20 rounded-lg">
                  <p className="text-xs font-semibold text-danger mb-1">Motif de rejet</p>
                  <p className="text-sm text-text-200">{dossier.rejection_reason}</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Documents joints */}
      {(dossier.status !== 'in_review' || role === 'super_admin') && dossier.documents && dossier.documents.length > 0 && (
        <Card className="border-border-subtle">
          <CardHeader className="pb-3">
            <CardTitle className="text-base font-semibold text-secondary">
              Documents joints ({dossier.documents.length})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {dossier.documents.map((doc) => (
                <div
                  key={doc.id}
                  className="border border-border-subtle rounded-lg p-4 hover:bg-layer-2 transition-colors group"
                >
                  {doc.file_type === 'image' && (
                    <div 
                      className="aspect-video bg-layer-3 rounded-md mb-3 overflow-hidden cursor-pointer relative group"
                      onClick={() => setSelectedDocument(doc)}
                    >
                      <SecureImage
                        src={`/api/documents/${doc.id}/download/`}
                        alt={doc.original_filename}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                      <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 flex items-center justify-center transition-all">
                         <div className="bg-black/50 text-white rounded-full p-2 opacity-0 group-hover:opacity-100 transition-opacity">
                            <span className="text-xs font-semibold px-2">Agrandir</span>
                         </div>
                      </div>
                    </div>
                  )}
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-secondary">{doc.original_filename}</p>
                      <p className="text-xs text-text-400 mt-0.5">
                        {doc.created_at
                          ? new Date(doc.created_at).toLocaleDateString('fr-FR')
                          : ''}
                      </p>
                    </div>
                    <a
                      href={`/api/documents/${doc.id}/download/`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-2 rounded-lg text-primary hover:bg-primary/10 transition-colors"
                    >
                      <ExternalLink className="h-4 w-4" />
                    </a>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Checkboxes de conformité (visible uniquement en review) */}
      {dossier.status === 'in_review' && role !== 'super_admin' && (
        <Card className="border-border-subtle bg-primary/5 border-primary/20">
          <CardHeader className="pb-3">
            <CardTitle className="text-base font-semibold text-primary flex items-center gap-2">
              <CheckCircle className="h-5 w-5" />
              Vérification des pièces
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              {/* Colonne Documents joints */}
              <div className="space-y-4">
                <h3 className="font-semibold text-sm text-secondary border-b border-primary/10 pb-2">Documents envoyés par le citoyen</h3>
                {dossier.documents && dossier.documents.length > 0 ? (
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {dossier.documents.map((doc) => (
                      <div
                        key={doc.id}
                        className="border border-border-subtle bg-white rounded-lg p-3 hover:bg-layer-2 transition-colors group shadow-sm"
                      >
                        {doc.file_type === 'image' && (
                          <div 
                            className="aspect-video bg-layer-3 rounded-md mb-3 overflow-hidden cursor-pointer relative group"
                            onClick={() => setSelectedDocument(doc)}
                          >
                            <SecureImage
                              src={`/api/documents/${doc.id}/download/`}
                              alt={doc.original_filename}
                              className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                            />
                            <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 flex items-center justify-center transition-all">
                               <div className="bg-black/50 text-white rounded-full p-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                  <span className="text-xs font-semibold px-2">Agrandir</span>
                               </div>
                            </div>
                          </div>
                        )}
                        <div className="flex items-center justify-between">
                          <div className="overflow-hidden">
                            <p className="text-sm font-medium text-secondary truncate" title={doc.original_filename}>{doc.original_filename}</p>
                            <p className="text-xs text-text-400 mt-0.5">
                              {doc.created_at
                                ? new Date(doc.created_at).toLocaleDateString('fr-FR')
                                : ''}
                            </p>
                          </div>
                          <a
                            href={`/api/documents/${doc.id}/download/`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="p-1.5 rounded-lg text-primary hover:bg-primary/10 transition-colors ml-2 shrink-0"
                          >
                            <ExternalLink className="h-4 w-4" />
                          </a>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-text-400 italic">Aucun document joint.</p>
                )}
              </div>

              {/* Colonne Checkboxes */}
              <div className="space-y-4">
                <h3 className="font-semibold text-sm text-secondary border-b border-primary/10 pb-2">Checklist de conformité</h3>
                <div className="space-y-3">
              {dossier.type === 'residence_certificate' && (
                <>
                  <label className="flex items-center gap-3 p-2 rounded hover:bg-primary/10 cursor-pointer transition-colors">
                    <input type="checkbox" className="w-5 h-5 rounded border-primary/50 text-primary focus:ring-primary" checked={verificationChecks.cni_recto} onChange={(e) => setVerificationChecks({...verificationChecks, cni_recto: e.target.checked})} />
                    <span className="text-sm font-medium text-text-200">La pièce d'identité (CNI) du demandeur est valide et lisible.</span>
                  </label>
                  <label className="flex items-center gap-3 p-2 rounded hover:bg-primary/10 cursor-pointer transition-colors">
                    <input type="checkbox" className="w-5 h-5 rounded border-primary/50 text-primary focus:ring-primary" checked={verificationChecks.attestation_delegue} onChange={(e) => setVerificationChecks({...verificationChecks, attestation_delegue: e.target.checked})} />
                    <span className="text-sm font-medium text-text-200">L'attestation du délégué de quartier est présente et signée.</span>
                  </label>
                </>
              )}

              {dossier.type === 'death_certificate' && (
                <>
                  <label className="flex items-center gap-3 p-2 rounded hover:bg-primary/10 cursor-pointer transition-colors">
                    <input type="checkbox" className="w-5 h-5 rounded border-primary/50 text-primary focus:ring-primary" checked={verificationChecks.constat_medecin} onChange={(e) => setVerificationChecks({...verificationChecks, constat_medecin: e.target.checked})} />
                    <span className="text-sm font-medium text-text-200">Le constat de décès (médecin/chef de village) est valide.</span>
                  </label>
                  <label className="flex items-center gap-3 p-2 rounded hover:bg-primary/10 cursor-pointer transition-colors">
                    <input type="checkbox" className="w-5 h-5 rounded border-primary/50 text-primary focus:ring-primary" checked={verificationChecks.cni_defunt} onChange={(e) => setVerificationChecks({...verificationChecks, cni_defunt: e.target.checked})} />
                    <span className="text-sm font-medium text-text-200">La CNI du défunt est présente.</span>
                  </label>
                  
                  {dossier.metadata?.deces_domicile && (
                    <div className="pl-6 border-l-2 border-primary/30 mt-2 space-y-2">
                      <p className="text-xs text-text-400 font-semibold mb-1">Décès à domicile (2 témoins requis)</p>
                      <label className="flex items-center gap-3 p-2 rounded hover:bg-primary/10 cursor-pointer transition-colors">
                        <input type="checkbox" className="w-5 h-5 rounded border-primary/50 text-primary focus:ring-primary" checked={verificationChecks.cni_temoin1} onChange={(e) => setVerificationChecks({...verificationChecks, cni_temoin1: e.target.checked})} />
                        <span className="text-sm font-medium text-text-200">La CNI du Témoin 1 est valide.</span>
                      </label>
                      <label className="flex items-center gap-3 p-2 rounded hover:bg-primary/10 cursor-pointer transition-colors">
                        <input type="checkbox" className="w-5 h-5 rounded border-primary/50 text-primary focus:ring-primary" checked={verificationChecks.cni_temoin2} onChange={(e) => setVerificationChecks({...verificationChecks, cni_temoin2: e.target.checked})} />
                        <span className="text-sm font-medium text-text-200">La CNI du Témoin 2 est valide.</span>
                      </label>
                    </div>
                  )}
                </>
              )}

              {dossier.type === 'marriage_certificate' && (
                <>
                  <label className="flex items-center gap-3 p-2 rounded hover:bg-primary/10 cursor-pointer transition-colors">
                    <input type="checkbox" className="w-5 h-5 rounded border-primary/50 text-primary focus:ring-primary" checked={verificationChecks.cni_epoux} onChange={(e) => setVerificationChecks({...verificationChecks, cni_epoux: e.target.checked})} />
                    <span className="text-sm font-medium text-text-200">La CNI de l'époux est valide.</span>
                  </label>
                  <label className="flex items-center gap-3 p-2 rounded hover:bg-primary/10 cursor-pointer transition-colors">
                    <input type="checkbox" className="w-5 h-5 rounded border-primary/50 text-primary focus:ring-primary" checked={verificationChecks.cni_epouse} onChange={(e) => setVerificationChecks({...verificationChecks, cni_epouse: e.target.checked})} />
                    <span className="text-sm font-medium text-text-200">La CNI de l'épouse est valide.</span>
                  </label>
                  <label className="flex items-center gap-3 p-2 rounded hover:bg-primary/10 cursor-pointer transition-colors">
                    <input type="checkbox" className="w-5 h-5 rounded border-primary/50 text-primary focus:ring-primary" checked={verificationChecks.cni_temoins} onChange={(e) => setVerificationChecks({...verificationChecks, cni_temoins: e.target.checked})} />
                    <span className="text-sm font-medium text-text-200">Les pièces d'identité des témoins sont valides.</span>
                  </label>
                </>
              )}
            </div>
          </div>
        </div>
      </CardContent>
        </Card>
      )}

      {/* Zone d'actions sticky en bas */}
      {!['super_admin', 'civil_admin_supervisor'].includes(role) && (dossier.status === 'submitted' ||
        dossier.status === 'in_review' ||
        dossier.status === 'approved' ||
        dossier.status === 'validated' ||
        dossier.status === 'generated') && (
        <div className="sticky bottom-0 bg-white border-t border-border-subtle shadow-lg rounded-t-xl p-4 -mx-6 -mb-6">
          <div className="flex items-center justify-end gap-3 max-w-7xl mx-auto">
            {dossier.status === 'submitted' && (
              <>
                <Button
                  onClick={() => handleStatusChange('in_review')}
                  disabled={actionLoading}
                  className="gap-2"
                >
                  {actionLoading ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <PlayCircle className="h-4 w-4" />
                  )}
                  Prendre en charge
                </Button>
                <Button
                  variant="destructive"
                  onClick={() => setRejectDialogOpen(true)}
                  disabled={actionLoading}
                  className="gap-2"
                >
                  <XCircle className="h-4 w-4" />
                  Rejeter
                </Button>
              </>
            )}

            {dossier.status === 'in_review' && (
              <>
                <Button
                  variant="success"
                  onClick={() => handleStatusChange('approved')}
                  disabled={actionLoading || isApprovalDisabled()}
                  className="gap-2 bg-success hover:bg-success/90 text-white disabled:opacity-50"
                  title={isApprovalDisabled() ? "Veuillez cocher toutes les pièces conformes" : ""}
                >
                  {actionLoading ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <CheckCircle className="h-4 w-4" />
                  )}
                  Approuver
                </Button>
                <Button
                  variant="destructive"
                  onClick={() => setRejectDialogOpen(true)}
                  disabled={actionLoading}
                  className="gap-2"
                >
                  <XCircle className="h-4 w-4" />
                  Rejeter
                </Button>
              </>
            )}

            {['approved', 'validated', 'generated'].includes(dossier.status) && (
              <>
                <Button
                  onClick={() => handleStatusChange('completed')}
                  disabled={actionLoading}
                  className="gap-2"
                >
                  {actionLoading ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <Flag className="h-4 w-4" />
                  )}
                  Marquer terminé
                </Button>
                <Button 
                  onClick={handleDownloadPdf}
                  disabled={actionLoading} 
                  variant="outline" 
                  title="Télécharger le certificat au format PDF" 
                  className="gap-2"
                >
                  <FileDown className="h-4 w-4" /> PDF
                </Button>
              </>
            )}
          </div>
        </div>
      )}

      {/* Dialog de rejet */}
      <Dialog open={rejectDialogOpen} onOpenChange={setRejectDialogOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-danger">Confirmer le rejet</DialogTitle>
            <DialogDescription>
              Cette action est irréversible. Veuillez indiquer le motif du rejet.
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
              {rejectionReason.length >= 20 && <span className="text-success ml-2">✓</span>}
            </p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setRejectDialogOpen(false)}>
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

      {/* Dialog d'édition des métadonnées */}
      <Dialog open={editMetadataOpen} onOpenChange={setEditMetadataOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Éditer les informations du certificat</DialogTitle>
            <DialogDescription>
              Remplissez les informations extraites depuis l'image ou le registre physique.
            </DialogDescription>
          </DialogHeader>
          
          <div className="grid grid-cols-2 gap-4 py-4">
            {dossier.type === 'marriage_certificate' ? (
              <>
                <div className="col-span-2 text-sm font-semibold text-primary uppercase border-b pb-1">Les Époux</div>
                <div className="space-y-2">
                  <Label htmlFor="nom_epoux">Nom de l'époux</Label>
                  <Input 
                    id="nom_epoux" 
                    value={metadataForm.nom_epoux}
                    onChange={(e) => setMetadataForm({...metadataForm, nom_epoux: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="nom_epouse">Nom de l'épouse</Label>
                  <Input 
                    id="nom_epouse" 
                    value={metadataForm.nom_epouse}
                    onChange={(e) => setMetadataForm({...metadataForm, nom_epouse: e.target.value})}
                  />
                </div>
                <div className="col-span-2 text-sm font-semibold text-primary uppercase border-b pb-1 mt-2">Le Registre</div>
                <div className="space-y-2">
                  <Label htmlFor="annee_marriage">Année du registre</Label>
                  <Input 
                    id="annee_marriage" 
                    placeholder="ex: 2026"
                    value={metadataForm.annee_marriage}
                    onChange={(e) => setMetadataForm({...metadataForm, annee_marriage: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="registre_marriage">Numéro de registre</Label>
                  <Input 
                    id="registre_marriage" 
                    value={metadataForm.registre_marriage}
                    onChange={(e) => setMetadataForm({...metadataForm, registre_marriage: e.target.value})}
                  />
                </div>
              </>
            ) : dossier.type === 'death_certificate' ? (
              <>
                <div className="col-span-2 text-sm font-semibold text-primary uppercase border-b pb-1">Le Défunt</div>
                <div className="space-y-2">
                  <Label htmlFor="nom_defunt">Nom du défunt</Label>
                  <Input 
                    id="nom_defunt" 
                    value={metadataForm.nom_defunt}
                    onChange={(e) => setMetadataForm({...metadataForm, nom_defunt: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="date_deces">Date de décès</Label>
                  <Input 
                    id="date_deces" 
                    type="date"
                    value={metadataForm.date_deces}
                    onChange={(e) => setMetadataForm({...metadataForm, date_deces: e.target.value})}
                  />
                </div>
                <div className="col-span-2 text-sm font-semibold text-primary uppercase border-b pb-1 mt-2">Le Déclarant</div>
                <div className="space-y-2">
                  <Label htmlFor="nom_declarant">Nom du déclarant</Label>
                  <Input 
                    id="nom_declarant" 
                    value={metadataForm.nom_declarant}
                    onChange={(e) => setMetadataForm({...metadataForm, nom_declarant: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lien_parente">Lien de parenté</Label>
                  <Input 
                    id="lien_parente" 
                    value={metadataForm.lien_parente}
                    onChange={(e) => setMetadataForm({...metadataForm, lien_parente: e.target.value})}
                  />
                </div>
                <div className="col-span-2 text-sm font-semibold text-primary uppercase border-b pb-1 mt-2">Le Registre</div>
                <div className="space-y-2">
                  <Label htmlFor="registre">Numéro de registre</Label>
                  <Input 
                    id="registre" 
                    value={metadataForm.registre}
                    onChange={(e) => setMetadataForm({...metadataForm, registre: e.target.value})}
                  />
                </div>
              </>
            ) : (
              <>
                <div className="col-span-2 text-sm font-semibold text-primary uppercase border-b pb-1">L'enfant</div>
                <div className="space-y-2">
                  <Label htmlFor="prenoms_enfant">Prénoms</Label>
                  <Input 
                    id="prenoms_enfant" 
                    value={metadataForm.prenoms_enfant}
                    onChange={(e) => setMetadataForm({...metadataForm, prenoms_enfant: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="nom_enfant">Nom</Label>
                  <Input 
                    id="nom_enfant" 
                    value={metadataForm.nom_enfant}
                    onChange={(e) => setMetadataForm({...metadataForm, nom_enfant: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="date_naissance_personne">Date de naissance</Label>
                  <Input 
                    id="date_naissance_personne" 
                    type="date"
                    value={metadataForm.date_naissance_personne}
                    onChange={(e) => setMetadataForm({...metadataForm, date_naissance_personne: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="heure_naissance">Heure de naissance</Label>
                  <Input 
                    id="heure_naissance" 
                    placeholder="ex: 14h30"
                    value={metadataForm.heure_naissance}
                    onChange={(e) => setMetadataForm({...metadataForm, heure_naissance: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lieu_naissance">Lieu de naissance</Label>
                  <Input 
                    id="lieu_naissance" 
                    value={metadataForm.lieu_naissance}
                    onChange={(e) => setMetadataForm({...metadataForm, lieu_naissance: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="sexe">Sexe</Label>
                  <Input 
                    id="sexe" 
                    placeholder="M ou F"
                    value={metadataForm.sexe}
                    onChange={(e) => setMetadataForm({...metadataForm, sexe: e.target.value})}
                  />
                </div>

                <div className="col-span-2 text-sm font-semibold text-primary uppercase border-b pb-1 mt-2">Les Parents</div>
                <div className="col-span-2 space-y-2">
                  <Label htmlFor="prenom_pere">Prénom du père</Label>
                  <Input 
                    id="prenom_pere" 
                    value={metadataForm.prenom_pere}
                    onChange={(e) => setMetadataForm({...metadataForm, prenom_pere: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="prenom_mere">Prénoms de la mère</Label>
                  <Input 
                    id="prenom_mere" 
                    value={metadataForm.prenom_mere}
                    onChange={(e) => setMetadataForm({...metadataForm, prenom_mere: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="nom_mere">Nom de la mère</Label>
                  <Input 
                    id="nom_mere" 
                    value={metadataForm.nom_mere}
                    onChange={(e) => setMetadataForm({...metadataForm, nom_mere: e.target.value})}
                  />
                </div>

                <div className="col-span-2 text-sm font-semibold text-primary uppercase border-b pb-1 mt-2">Le Registre</div>
                <div className="space-y-2">
                  <Label htmlFor="annee_registre">Année du registre</Label>
                  <Input 
                    id="annee_registre" 
                    placeholder="ex: 2026"
                    value={metadataForm.annee_registre}
                    onChange={(e) => setMetadataForm({...metadataForm, annee_registre: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="numero_registre">Numéro de registre</Label>
                  <Input 
                    id="numero_registre" 
                    value={metadataForm.numero_registre}
                    onChange={(e) => setMetadataForm({...metadataForm, numero_registre: e.target.value})}
                  />
                </div>
              </>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditMetadataOpen(false)}>Annuler</Button>
            <Button onClick={handleSaveMetadata} disabled={actionLoading}>
              {actionLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              Sauvegarder
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Viewer de Document (Lightbox) */}
      {selectedDocument && (
        <Dialog open={!!selectedDocument} onOpenChange={(open) => { if(!open) setSelectedDocument(null); }}>
          <DialogContent className="max-w-5xl w-full h-[90vh] flex flex-col p-2 bg-slate-900 border-none shadow-2xl">
            <DialogHeader className="p-4 bg-slate-900/80 backdrop-blur absolute top-0 left-0 right-0 z-10 flex flex-row items-center justify-between border-b border-slate-700">
              <div>
                <DialogTitle className="text-white text-lg flex items-center gap-2">
                  <FileText className="h-5 w-5 text-primary" />
                  {selectedDocument.name}
                </DialogTitle>
              </div>
            </DialogHeader>
            <div className="flex-1 w-full h-full mt-16 overflow-auto flex items-center justify-center bg-black/50 rounded-lg">
              {selectedDocument.file_type === 'image' ? (
                <SecureImage 
                  src={`/api/documents/${selectedDocument.id}/download/`} 
                  alt={selectedDocument.name}
                  className="max-w-full max-h-full object-contain"
                />
              ) : (
                <div className="text-white flex flex-col items-center">
                  <FileText className="h-16 w-16 mb-4 text-text-400" />
                  <p>Aperçu non disponible pour ce type de fichier.</p>
                  <a 
                    href={`/api/documents/${selectedDocument.id}/download/`} 
                    target="_blank" 
                    rel="noopener noreferrer" 
                    className="mt-4 text-primary hover:underline"
                    onClick={(e) => {
                      // We must fetch it as blob to inject token, then download
                      e.preventDefault();
                      import('@/api/axiosClient').then(module => {
                        const axiosClient = module.default;
                        axiosClient.get(`/api/documents/${selectedDocument.id}/download/`, { responseType: 'blob' })
                          .then(res => {
                            const url = URL.createObjectURL(res.data);
                            const a = document.createElement('a');
                            a.href = url;
                            a.download = selectedDocument.original_filename || selectedDocument.name;
                            a.click();
                            URL.revokeObjectURL(url);
                          });
                      });
                    }}
                  >
                    Télécharger le document sécurisé
                  </a>
                </div>
              )}
            </div>
          </DialogContent>
        </Dialog>
      )}
    </div>
  );
}

// Composant utilitaire pour afficher une ligne d'information
function InfoRow({ label, value }) {
  return (
    <div className="flex items-center justify-between py-1.5 border-b border-border-subtle last:border-0">
      <span className="text-sm text-text-400">{label}</span>
      <span className="text-sm font-medium text-secondary">{value || '—'}</span>
    </div>
  );
}
