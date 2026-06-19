// =============================================================================
// FormulaireAutorisationConstruire.jsx
// Formulaire de création de demande d'autorisation de construire pour le Guichet Rapide.
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

// ─── Composant Principal ─────────────────────────────────────────────────────
export default function FormulaireAutorisationConstruire({ citoyenId, citoyen: citoyenProp, paymentData, onSuccess, onCancel }) {
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);

  // ─── États pour le chargement du citoyen ────────────────────────────────
  const [loadingCitoyen, setLoadingCitoyen] = useState(false);
  const [errorCitoyen, setErrorCitoyen] = useState(null);
  const [champsPreremplis, setChampsPreremplis] = useState([]);

  // État du formulaire — champs textuels
  const [formData, setFormData] = useState({
    nom_complet: '',
    numero_cni: '',
    telephone: '',
    adresse: '',
    localisation_terrain: '',
    quartier_village: '',
    superficie: '',
    reference_cadastrale: ''
  });

  // État du formulaire — pièces jointes (fichiers images)
  const [fichiers, setFichiers] = useState({
    acte_administratif: null,
    acte_vente_enregistre: null,
    plan_construction: null,
    plan_cadastral: null,
    photocopie_identite: null,
    demande_bail: null,
    demande_maire: null,
    fiche_renseignements: null,
    devis_descriptif: null,
    plan_fosse_septique: null,
    taxe_urbanisme: null,
    taxe_communale: null
  });

  // État des erreurs de validation par champ
  const [erreurs, setErreurs] = useState({});

  // Confirmation dossier physique
  const [dossierPhysiqueComplet, setDossierPhysiqueComplet] = useState(false);

  // ─── Préremplissage depuis un objet citoyen ──────────────────────────────
  const prefillDepuisCitoyen = (c) => {
    const nomComplet = c.nom_complet || `${c.prenom || ''} ${c.nom || ''}`.trim();
    const adresseParts = [c.adresse, c.quartier, c.commune?.name].filter(Boolean);
    const adresse = adresseParts.join(', ');
    const nouveauxChamps = [];

    setFormData(prev => {
      const updated = { ...prev };
      if (nomComplet) { updated.nom_complet = nomComplet; nouveauxChamps.push('nom_complet'); }
      if (c.numero_cni) { updated.numero_cni = c.numero_cni; nouveauxChamps.push('numero_cni'); }
      if (c.telephone) { updated.telephone = c.telephone; nouveauxChamps.push('telephone'); }
      if (adresse) { updated.adresse = adresse; nouveauxChamps.push('adresse'); }
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

    if (!formData.nom_complet.trim()) nouvellesErreurs.nom_complet = 'Le nom complet est obligatoire';
    if (!formData.numero_cni.trim()) nouvellesErreurs.numero_cni = 'Le numéro CNI est obligatoire';
    if (!formData.telephone.trim()) nouvellesErreurs.telephone = 'Le téléphone est obligatoire';
    if (!formData.localisation_terrain.trim()) nouvellesErreurs.localisation_terrain = 'La localisation du terrain est obligatoire';

    if (!dossierPhysiqueComplet) nouvellesErreurs.dossierPhysiqueComplet = 'Vous devez confirmer la réception du dossier physique complet';

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
      payload.append('type_document', 'autorisation_construire');
      payload.append('motif', 'Guichet Rapide');
      if (paymentData) {
        payload.append('paiement_mode', paymentData.mode || 'Espèces');
        payload.append('montant', paymentData.montant || 0);
      }
      
      // Metadata specific fields
      payload.append('nom_complet_requerant', formData.nom_complet.trim());
      payload.append('numero_cni', formData.numero_cni.trim());
      payload.append('telephone', formData.telephone.trim());
      payload.append('adresse', formData.adresse.trim());
      payload.append('localisation_terrain', formData.localisation_terrain.trim());
      payload.append('quartier_village', formData.quartier_village.trim());
      payload.append('superficie', formData.superficie.trim());
      payload.append('reference_cadastrale', formData.reference_cadastrale.trim());

      Object.keys(fichiers).forEach(key => {
        if (fichiers[key]) {
          payload.append('pieces_jointes', fichiers[key]);
        }
      });

      // Envoi POST vers l'API backend guichet
      const url = citoyenId ? `/api/citoyens/${citoyenId}/guichet/` : '/api/dossiers/';
      const response = await axiosClient.post(url, payload, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });

      toast({
        title: 'Succès',
        description: "La demande d'autorisation de construire a été soumise avec succès.",
        className: 'bg-emerald-50 text-emerald-900 border-emerald-200'
      });

      // Callback de succès vers le composant parent
      if (onSuccess) {
        onSuccess(response.data);
      }
    } catch (error) {
      // Gestion des erreurs API
      let errorMessage = "Erreur lors de l'enregistrement de la demande d'autorisation de construire";
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
      <label className="text-sm font-medium text-text-200">{label}</label>
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
            Demande d'Autorisation de Construire
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

        {/* CNI et Téléphone */}
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Numéro CNI *</label>
          <input
            type="text"
            name="numero_cni"
            value={formData.numero_cni}
            onChange={handleChange}
            className={`w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow ${erreurs.numero_cni ? 'border-red-400' : 'border-border-strong'}`}
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Téléphone *</label>
          <input
            type="text"
            name="telephone"
            value={formData.telephone}
            onChange={handleChange}
            className={`w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow ${erreurs.telephone ? 'border-red-400' : 'border-border-strong'}`}
          />
        </div>

        {/* Localisation et Quartier */}
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Localisation du terrain *</label>
          <input
            type="text"
            name="localisation_terrain"
            value={formData.localisation_terrain}
            onChange={handleChange}
            className={`w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow ${erreurs.localisation_terrain ? 'border-red-400' : 'border-border-strong'}`}
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Quartier / Village</label>
          <input
            type="text"
            name="quartier_village"
            value={formData.quartier_village}
            onChange={handleChange}
            className="w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow border-border-strong"
          />
        </div>

        {/* Superficie et Réf. Cadastrale */}
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Superficie (m²)</label>
          <input
            type="text"
            name="superficie"
            value={formData.superficie}
            onChange={handleChange}
            className="w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow border-border-strong"
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Référence cadastrale</label>
          <input
            type="text"
            name="reference_cadastrale"
            value={formData.reference_cadastrale}
            onChange={handleChange}
            className="w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow border-border-strong"
          />
        </div>
      </div>

      {/* Section — Pièces jointes */}
      <div className="space-y-1 mt-2">
        <h4 className="text-sm font-semibold text-text-300 uppercase tracking-wider flex items-center justify-between">
          <span>Pièces justificatives (Optionnel sur l'interface)</span>
          <span className="text-xs text-amber-600 bg-amber-100 px-2 py-1 rounded-full normal-case">
            NB : À déposer physiquement en sept (7) exemplaires
          </span>
        </h4>
        <div className="h-px bg-border-subtle" />
      </div>

      {/* Checkbox obligatoire pour confirmer la réception physique */}
      <div className="bg-amber-50/50 border border-amber-200 p-4 rounded-lg flex items-start gap-3">
        <div className="flex items-center h-5">
          <input
            id="dossier-physique"
            type="checkbox"
            checked={dossierPhysiqueComplet}
            onChange={(e) => {
              setDossierPhysiqueComplet(e.target.checked);
              if (erreurs.dossierPhysiqueComplet) {
                setErreurs(prev => ({ ...prev, dossierPhysiqueComplet: null }));
              }
            }}
            className="w-4 h-4 text-emerald-600 bg-layer-1 border-border-strong rounded focus:ring-emerald-500 focus:ring-2"
          />
        </div>
        <div className="flex-1">
          <label htmlFor="dossier-physique" className="text-sm font-medium text-amber-900 cursor-pointer">
            J'atteste avoir reçu le dossier physique complet en sept (7) exemplaires. *
          </label>
          <p className="text-xs text-amber-700/80 mt-1">
            Cochez cette case pour confirmer la réception. Les uploads numériques ci-dessous sont facultatifs.
          </p>
          {erreurs.dossierPhysiqueComplet && (
            <p className="text-xs text-red-500 flex items-center gap-1 mt-1">
              <AlertCircle className="h-3 w-3" /> {erreurs.dossierPhysiqueComplet}
            </p>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <FileUploadField name="acte_administratif" label="Acte administratif" description="Charger le document" />
        <FileUploadField name="acte_vente_enregistre" label="Acte de vente enregistré" description="Charger le document" />
        <FileUploadField name="plan_construction" label="Plan de construction" description="Charger le plan" />
        <FileUploadField name="plan_cadastral" label="Plan cadastral" description="Charger le plan" />
        <FileUploadField name="photocopie_identite" label="Photocopie de la pièce d'identité" description="Charger la CNI" />
        <FileUploadField name="demande_bail" label="Demande de bail / attestation" description="Charger le document" />
        <FileUploadField name="demande_maire" label="Demande adressée au Maire" description="Charger la demande" />
        <FileUploadField name="fiche_renseignements" label="Fiche de renseignements" description="Charger la fiche" />
        <FileUploadField name="devis_descriptif" label="Devis descriptif du projet" description="Charger le devis" />
        <FileUploadField name="plan_fosse_septique" label="Plan de fosse septique" description="Charger le plan" />
        <FileUploadField name="taxe_urbanisme" label="Taxe d'urbanisme" description="Charger le reçu" />
        <FileUploadField name="taxe_communale" label="Taxe communale" description="Charger le reçu" />
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
