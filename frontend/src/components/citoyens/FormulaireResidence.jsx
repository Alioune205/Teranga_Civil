// =============================================================================
// FormulaireResidence.jsx — Tâche 9 (DEV 1B — Pathé Fall)
// Formulaire de création de Certificat de Résidence pour le Guichet Rapide.
// Permet à un agent de mairie d'enregistrer une demande pour un citoyen
// venu physiquement au guichet.
// =============================================================================

import { useState, useEffect } from 'react';
import { getCitoyenById } from '@/services/citoyenApi';
import { Button } from '@/components/ui/button';
import { useToast } from '@/components/ui/use-toast';
import axiosClient from '@/api/axiosClient';
import {
  Loader2,
  Check,
  Upload,
  FileImage,
  X,
  Home,
  AlertCircle,
  CheckCircle2,
  UserCheck
} from 'lucide-react';

// ─── Constantes ──────────────────────────────────────────────────────────────
const DUREE_OPTIONS = [
  '6 mois', '1 an', '2 ans', '3 ans', '5 ans', '10 ans', 'Plus de 10 ans'
];

// ─── Composant Principal ─────────────────────────────────────────────────────
export default function FormulaireResidence({ citoyenId, citoyen: citoyenProp, paymentData, onSuccess, onCancel }) {
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);

  // ─── États pour le chargement du citoyen ────────────────────────────────
  const [loadingCitoyen, setLoadingCitoyen] = useState(false);
  const [errorCitoyen, setErrorCitoyen] = useState(null);
  const [champsPreremplis, setChampsPreremplis] = useState([]);

  // État du formulaire — champs textuels
  const [formData, setFormData] = useState({
    nom_complet: '',
    date_naissance: '',
    adresse_residence: '',
    duree_residence: ''
  });

  // État du formulaire — pièces jointes (fichiers images)
  const [fichiers, setFichiers] = useState({
    cni: null,
    attestation_delegue: null
  });

  // État des erreurs de validation par champ
  const [erreurs, setErreurs] = useState({});

  // ─── Préremplissage depuis un objet citoyen ──────────────────────────────
  const prefillDepuisCitoyen = (c) => {
    const nomComplet = c.nom_complet || `${c.prenom || ''} ${c.nom || ''}`.trim();
    const adresseParts = [c.adresse, c.quartier, c.commune?.name].filter(Boolean);
    const adresse = adresseParts.join(', ');
    const nouveauxChamps = [];

    setFormData(prev => {
      const updated = { ...prev };
      if (nomComplet) { updated.nom_complet = nomComplet; nouveauxChamps.push('nom_complet'); }
      if (c.date_naissance) { updated.date_naissance = c.date_naissance; nouveauxChamps.push('date_naissance'); }
      if (adresse) { updated.adresse_residence = adresse; nouveauxChamps.push('adresse_residence'); }
      return updated;
    });
    setChampsPreremplis(nouveauxChamps);
  };

  // ─── useEffect : préremplissage au montage ───────────────────────────────
  useEffect(() => {
    const chargerCitoyen = async () => {
      // 1. Pré-remplissage immédiat depuis la prop (données liste déjà disponibles)
      //    Permet d'afficher nom/date sans attendre le réseau
      if (citoyenProp) {
        prefillDepuisCitoyen(citoyenProp);
      }

      // 2. Toujours appeler le détail API pour obtenir adresse + quartier
      //    (non inclus dans le sérialiseur de liste)
      if (!citoyenId) return;
      setLoadingCitoyen(true);
      setErrorCitoyen(null);
      try {
        const data = await getCitoyenById(citoyenId);
        prefillDepuisCitoyen(data);   // écrase/complète avec les données complètes
      } catch (err) {
        setErrorCitoyen('Impossible de charger les informations du citoyen.');
      } finally {
        setLoadingCitoyen(false);
      }
    };
    chargerCitoyen();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [citoyenId]);

  // ─── Gestion des changements de champs textuels ──────────────────────────
  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    // Effacer l'erreur du champ modifié
    if (erreurs[name]) {
      setErreurs(prev => ({ ...prev, [name]: null }));
    }
  };

  // ─── Gestion des changements de fichiers ─────────────────────────────────
  const handleFileChange = (e) => {
    const { name, files } = e.target;
    if (files && files[0]) {
      setFichiers(prev => ({ ...prev, [name]: files[0] }));
      // Effacer l'erreur du fichier modifié
      if (erreurs[name]) {
        setErreurs(prev => ({ ...prev, [name]: null }));
      }
    }
  };

  // ─── Suppression d'un fichier sélectionné ────────────────────────────────
  const handleRemoveFile = (fieldName) => {
    setFichiers(prev => ({ ...prev, [fieldName]: null }));
    // Réinitialiser l'input file correspondant
    const input = document.getElementById(`file-${fieldName}`);
    if (input) input.value = '';
  };

  // ─── Validation frontend ────────────────────────────────────────────────
  const validerFormulaire = () => {
    const nouvellesErreurs = {};

    if (!formData.nom_complet.trim()) {
      nouvellesErreurs.nom_complet = 'Le nom complet est obligatoire';
    }
    if (!formData.date_naissance) {
      nouvellesErreurs.date_naissance = 'La date de naissance est obligatoire';
    }
    if (!formData.adresse_residence.trim()) {
      nouvellesErreurs.adresse_residence = "L'adresse de résidence est obligatoire";
    }
    if (!formData.duree_residence) {
      nouvellesErreurs.duree_residence = 'La durée de résidence est obligatoire';
    }
    if (!fichiers.cni) {
      nouvellesErreurs.cni = 'La copie de la CNI est obligatoire';
    }
    if (!fichiers.attestation_delegue) {
      nouvellesErreurs.attestation_delegue = "L'attestation du délégué est obligatoire";
    }

    setErreurs(nouvellesErreurs);
    return Object.keys(nouvellesErreurs).length === 0;
  };

  // ─── Soumission du formulaire ────────────────────────────────────────────
  const handleSubmit = async () => {
    if (!validerFormulaire()) {
      toast({
        title: 'Formulaire incomplet',
        description: 'Veuillez remplir tous les champs obligatoires et joindre les pièces requises.',
        variant: 'destructive'
      });
      return;
    }

    setLoading(true);
    try {
      // Construction du FormData pour l'envoi multipart (images + données)
      const payload = new FormData();
      payload.append('type_document', 'residence_certificate');
      payload.append('motif', 'Guichet Rapide');
      if (paymentData) {
        payload.append('paiement_mode', paymentData.mode || 'Espèces');
        payload.append('montant', paymentData.montant || 0);
      }
      
      // Metadata specific fields
      payload.append('nom_complet', formData.nom_complet.trim());
      payload.append('date_naissance', formData.date_naissance);
      payload.append('adresse_residence', formData.adresse_residence.trim());
      payload.append('duree_residence', formData.duree_residence);

      // Pièces jointes individuelles
      payload.append('cni', fichiers.cni);
      payload.append('attestation_delegue', fichiers.attestation_delegue);

      // Tableau pieces_jointes regroupant les 2 images
      payload.append('pieces_jointes', fichiers.cni);
      payload.append('pieces_jointes', fichiers.attestation_delegue);

      // Envoi POST vers l'API backend guichet
      const url = citoyenId ? `/api/citoyens/${citoyenId}/guichet/` : '/api/dossiers/';
      const response = await axiosClient.post(url, payload, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });

      toast({
        title: 'Succès',
        description: 'Le certificat de résidence a été généré avec succès.',
        className: 'bg-emerald-50 text-emerald-900 border-emerald-200'
      });

      // Callback de succès vers le composant parent
      if (onSuccess) {
        onSuccess(response.data);
      }
    } catch (error) {
      // Gestion des erreurs API
      let errorMessage = "Erreur lors de l'enregistrement du certificat de résidence";
      if (error.response?.data) {
        const data = error.response.data;
        if (data.message) {
          errorMessage = data.message;
        } else if (data.detail) {
          errorMessage = data.detail;
        } else if (data.errors && typeof data.errors === 'object') {
          const firstKey = Object.keys(data.errors)[0];
          if (firstKey) {
            errorMessage = `${firstKey}: ${Array.isArray(data.errors[firstKey]) ? data.errors[firstKey][0] : data.errors[firstKey]}`;
          }
        }
      }

      toast({
        title: 'Erreur',
        description: errorMessage,
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  // ─── Composant d'upload de fichier réutilisable ──────────────────────────
  const FileUploadField = ({ name, label, description }) => (
    <div className="space-y-2">
      <label className="text-sm font-medium text-text-200">{label} *</label>
      {fichiers[name] ? (
        // Fichier sélectionné — aperçu
        <div className="flex items-center gap-3 p-3 bg-emerald-50 dark:bg-emerald-900/10 border border-emerald-200 dark:border-emerald-800 rounded-lg">
          <FileImage className="h-5 w-5 text-emerald-600 shrink-0" />
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-emerald-700 dark:text-emerald-400 truncate">
              {fichiers[name].name}
            </p>
            <p className="text-xs text-emerald-600/70 dark:text-emerald-500/70">
              {(fichiers[name].size / 1024).toFixed(1)} Ko
            </p>
          </div>
          <button
            type="button"
            onClick={() => handleRemoveFile(name)}
            className="p-1 rounded-full hover:bg-emerald-200 dark:hover:bg-emerald-800 transition-colors"
          >
            <X className="h-4 w-4 text-emerald-600" />
          </button>
        </div>
      ) : (
        // Aucun fichier — zone de sélection
        <label
          htmlFor={`file-${name}`}
          className={`flex flex-col items-center gap-2 p-4 border-2 border-dashed rounded-lg cursor-pointer transition-all ${erreurs[name]
            ? 'border-red-400 bg-red-50/50 dark:bg-red-900/10'
            : 'border-border-strong hover:border-primary/50 hover:bg-primary/5'
            }`}
        >
          <Upload className={`h-6 w-6 ${erreurs[name] ? 'text-red-400' : 'text-text-400'}`} />
          <span className={`text-sm ${erreurs[name] ? 'text-red-500' : 'text-text-400'}`}>
            {description}
          </span>
          <span className="text-xs text-text-400">Formats acceptés : JPG, PNG, WEBP</span>
        </label>
      )}
      <input
        id={`file-${name}`}
        type="file"
        name={name}
        accept="image/*"
        onChange={handleFileChange}
        className="hidden"
      />
      {/* Message d'erreur */}
      {erreurs[name] && (
        <p className="text-xs text-red-500 flex items-center gap-1 mt-1">
          <AlertCircle className="h-3 w-3" /> {erreurs[name]}
        </p>
      )}
    </div>
  );

  // ─── Rendu JSX ───────────────────────────────────────────────────────────
  return (
    <div className="space-y-6">
      {/* En-tête du formulaire */}
      <div className="flex items-center gap-3 p-4 bg-blue-50 dark:bg-blue-900/10 border border-blue-200 dark:border-blue-800 rounded-xl">
        <div className="h-10 w-10 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center shrink-0">
          {loadingCitoyen
            ? <Loader2 className="h-5 w-5 text-blue-600 animate-spin" />
            : champsPreremplis.length > 0
              ? <UserCheck className="h-5 w-5 text-emerald-600 dark:text-emerald-400" />
              : <Home className="h-5 w-5 text-blue-600 dark:text-blue-400" />
          }
        </div>
        <div className="flex-1">
          <h3 className="font-semibold text-blue-800 dark:text-blue-300 font-jakarta">
            Certificat de Résidence
          </h3>
          {loadingCitoyen ? (
            <p className="text-sm text-blue-600/80 dark:text-blue-400/80 animate-pulse">
              Chargement des informations du citoyen...
            </p>
          ) : champsPreremplis.length > 0 ? (
            <p className="text-sm text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
              <CheckCircle2 className="h-3.5 w-3.5" />
              Informations préremplies depuis le dossier citoyen
            </p>
          ) : (
            <p className="text-sm text-blue-600/80 dark:text-blue-400/80">
              Remplissez les informations du demandeur et joignez les pièces justificatives.
            </p>
          )}
        </div>
      </div>

      {/* Bannière d'erreur de chargement citoyen */}
      {errorCitoyen && (
        <div className="flex items-center gap-2 p-3 bg-amber-50 dark:bg-amber-900/10 border border-amber-200 dark:border-amber-800 rounded-lg text-amber-700 dark:text-amber-400 text-sm">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {errorCitoyen} Veuillez saisir les informations manuellement.
        </div>
      )}

      {/* Section — Informations personnelles */}
      <div className="space-y-1">
        <h4 className="text-sm font-semibold text-text-300 uppercase tracking-wider">
          Informations du demandeur
        </h4>
        <div className="h-px bg-border-subtle" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Nom complet */}
        <div className="space-y-2 md:col-span-2">
          <label className="text-sm font-medium text-text-200">Nom complet *</label>
          <div className="relative">
            <input
              type="text"
              name="nom_complet"
              value={formData.nom_complet}
              onChange={handleChange}
              disabled={loadingCitoyen}
              className={`w-full p-2.5 pr-10 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow disabled:opacity-60 ${
                erreurs.nom_complet ? 'border-red-400' : champsPreremplis.includes('nom_complet') ? 'border-emerald-400' : 'border-border-strong'
              }`}
              placeholder="Ex : Amadou Ndiaye"
            />
            {champsPreremplis.includes('nom_complet') && !erreurs.nom_complet && (
              <CheckCircle2 className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-emerald-500 pointer-events-none" />
            )}
          </div>
          {erreurs.nom_complet && (
            <p className="text-xs text-red-500 flex items-center gap-1">
              <AlertCircle className="h-3 w-3" /> {erreurs.nom_complet}
            </p>
          )}
        </div>

        {/* Date de naissance */}
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Date de naissance *</label>
          <div className="relative">
            <input
              type="date"
              name="date_naissance"
              value={formData.date_naissance}
              onChange={handleChange}
              disabled={loadingCitoyen}
              className={`w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow disabled:opacity-60 ${
                erreurs.date_naissance ? 'border-red-400' : champsPreremplis.includes('date_naissance') ? 'border-emerald-400' : 'border-border-strong'
              }`}
            />
            {champsPreremplis.includes('date_naissance') && !erreurs.date_naissance && (
              <CheckCircle2 className="absolute right-8 top-1/2 -translate-y-1/2 h-4 w-4 text-emerald-500 pointer-events-none" />
            )}
          </div>
          {erreurs.date_naissance && (
            <p className="text-xs text-red-500 flex items-center gap-1">
              <AlertCircle className="h-3 w-3" /> {erreurs.date_naissance}
            </p>
          )}
        </div>

        {/* Durée de résidence */}
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Durée de résidence *</label>
          <select
            name="duree_residence"
            value={formData.duree_residence}
            onChange={handleChange}
            className={`w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow ${erreurs.duree_residence ? 'border-red-400' : 'border-border-strong'
              }`}
          >
            <option value="">Sélectionner la durée</option>
            {DUREE_OPTIONS.map(opt => (
              <option key={opt} value={opt}>{opt}</option>
            ))}
          </select>
          {erreurs.duree_residence && (
            <p className="text-xs text-red-500 flex items-center gap-1">
              <AlertCircle className="h-3 w-3" /> {erreurs.duree_residence}
            </p>
          )}
        </div>

        {/* Adresse de résidence */}
        <div className="space-y-2 md:col-span-2">
          <label className="text-sm font-medium text-text-200">Adresse de résidence *</label>
          <div className="relative">
            <textarea
              name="adresse_residence"
              value={formData.adresse_residence}
              onChange={handleChange}
              disabled={loadingCitoyen}
              rows={2}
              className={`w-full p-2.5 pr-8 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow resize-none disabled:opacity-60 ${
                erreurs.adresse_residence ? 'border-red-400' : champsPreremplis.includes('adresse_residence') ? 'border-emerald-400' : 'border-border-strong'
              }`}
              placeholder="Ex : Quartier Médina, Rue 12 x 15, Dakar"
            />
            {champsPreremplis.includes('adresse_residence') && !erreurs.adresse_residence && (
              <CheckCircle2 className="absolute right-3 top-3 h-4 w-4 text-emerald-500 pointer-events-none" />
            )}
          </div>
          {erreurs.adresse_residence && (
            <p className="text-xs text-red-500 flex items-center gap-1">
              <AlertCircle className="h-3 w-3" /> {erreurs.adresse_residence}
            </p>
          )}
        </div>
      </div>

      {/* Section — Pièces jointes */}
      <div className="space-y-1 mt-2">
        <h4 className="text-sm font-semibold text-text-300 uppercase tracking-wider">
          Pièces justificatives
        </h4>
        <div className="h-px bg-border-subtle" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <FileUploadField
          name="cni"
          label="Carte Nationale d'Identité (CNI)"
          description="Cliquer pour charger la CNI du demandeur"
        />
        <FileUploadField
          name="attestation_delegue"
          label="Attestation du Délégué de quartier"
          description="Cliquer pour charger l'attestation"
        />
      </div>

      {/* Barre d'actions — Annuler / Soumettre */}
      <div className="flex justify-between items-center pt-4 border-t border-border-subtle">
        <Button
          variant="outline"
          onClick={onCancel}
          className="gap-2"
          disabled={loading}
        >
          Annuler
        </Button>

        <Button
          onClick={handleSubmit}
          disabled={loading}
          className="bg-emerald-600 text-white hover:bg-emerald-700 gap-2 shadow-sm"
        >
          {loading ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <Check className="h-4 w-4" />
          )}
          Soumettre la demande
        </Button>
      </div>
    </div>
  );
}
