// =============================================================================
// FormulaireMariage.jsx — Tâche 9 (DEV 1B — Pathé Fall)
// Formulaire de création d'Extrait de Mariage pour le Guichet Rapide.
// Permet à un agent de mairie d'enregistrer une demande pour un citoyen
// venu physiquement au guichet.
// =============================================================================

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { useToast } from '@/components/ui/use-toast';
import axiosClient from '@/api/axiosClient';
import {
  Loader2,
  Check,
  Upload,
  FileImage,
  X,
  Heart,
  AlertCircle
} from 'lucide-react';

// ─── Composant Principal ─────────────────────────────────────────────────────
export default function FormulaireMariage({ onSuccess, onCancel }) {
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);

  // État du formulaire — champs textuels
  const [formData, setFormData] = useState({
    nom_epoux: '',
    nom_epouse: '',
    date_mariage: '',
    lieu_mariage: ''
  });

  // État du formulaire — pièces jointes (4 fichiers images)
  const [fichiers, setFichiers] = useState({
    cni_epoux: null,
    cni_epouse: null,
    cni_temoin_1: null,
    cni_temoin_2: null
  });

  // État des erreurs de validation par champ
  const [erreurs, setErreurs] = useState({});

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
    const input = document.getElementById(`file-mariage-${fieldName}`);
    if (input) input.value = '';
  };

  // ─── Validation frontend — tous les champs + les 4 images ────────────────
  const validerFormulaire = () => {
    const nouvellesErreurs = {};

    if (!formData.nom_epoux.trim()) {
      nouvellesErreurs.nom_epoux = "Le nom de l'époux est obligatoire";
    }
    if (!formData.nom_epouse.trim()) {
      nouvellesErreurs.nom_epouse = "Le nom de l'épouse est obligatoire";
    }
    if (!formData.date_mariage) {
      nouvellesErreurs.date_mariage = 'La date du mariage est obligatoire';
    }
    if (!formData.lieu_mariage.trim()) {
      nouvellesErreurs.lieu_mariage = 'Le lieu du mariage est obligatoire';
    }
    if (!fichiers.cni_epoux) {
      nouvellesErreurs.cni_epoux = "La CNI de l'époux est obligatoire";
    }
    if (!fichiers.cni_epouse) {
      nouvellesErreurs.cni_epouse = "La CNI de l'épouse est obligatoire";
    }
    if (!fichiers.cni_temoin_1) {
      nouvellesErreurs.cni_temoin_1 = 'La CNI du témoin 1 est obligatoire';
    }
    if (!fichiers.cni_temoin_2) {
      nouvellesErreurs.cni_temoin_2 = 'La CNI du témoin 2 est obligatoire';
    }

    setErreurs(nouvellesErreurs);
    return Object.keys(nouvellesErreurs).length === 0;
  };

  // ─── Soumission du formulaire ────────────────────────────────────────────
  const handleSubmit = async () => {
    if (!validerFormulaire()) {
      toast({
        title: 'Formulaire incomplet',
        description: 'Veuillez remplir tous les champs obligatoires et joindre les 4 pièces requises.',
        variant: 'destructive'
      });
      return;
    }

    setLoading(true);
    try {
      // Construction du FormData pour l'envoi multipart (images + données)
      const payload = new FormData();
      payload.append('type_acte', 'mariage');
      payload.append('nom_epoux', formData.nom_epoux.trim());
      payload.append('nom_epouse', formData.nom_epouse.trim());
      payload.append('date_mariage', formData.date_mariage);
      payload.append('lieu_mariage', formData.lieu_mariage.trim());

      // Pièces jointes individuelles (nommées)
      payload.append('cni_epoux', fichiers.cni_epoux);
      payload.append('cni_epouse', fichiers.cni_epouse);
      payload.append('cni_temoin_1', fichiers.cni_temoin_1);
      payload.append('cni_temoin_2', fichiers.cni_temoin_2);

      // Tableau pieces_jointes regroupant les 4 images
      payload.append('pieces_jointes', fichiers.cni_epoux);
      payload.append('pieces_jointes', fichiers.cni_epouse);
      payload.append('pieces_jointes', fichiers.cni_temoin_1);
      payload.append('pieces_jointes', fichiers.cni_temoin_2);

      // Envoi POST vers l'API backend
      const response = await axiosClient.post('/api/dossiers/', payload, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });

      toast({
        title: 'Succès',
        description: 'Dossier créé et envoyé au Superviseur pour approbation.',
        className: 'bg-emerald-50 text-emerald-900 border-emerald-200'
      });

      // Callback de succès vers le composant parent
      if (onSuccess) {
        onSuccess(response.data);
      }
    } catch (error) {
      // Gestion des erreurs API
      let errorMessage = "Erreur lors de l'enregistrement de l'extrait de mariage";
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
          htmlFor={`file-mariage-${name}`}
          className={`flex flex-col items-center gap-2 p-3 border-2 border-dashed rounded-lg cursor-pointer transition-all ${erreurs[name]
              ? 'border-red-400 bg-red-50/50 dark:bg-red-900/10'
              : 'border-border-strong hover:border-primary/50 hover:bg-primary/5'
            }`}
        >
          <Upload className={`h-5 w-5 ${erreurs[name] ? 'text-red-400' : 'text-text-400'}`} />
          <span className={`text-xs text-center ${erreurs[name] ? 'text-red-500' : 'text-text-400'}`}>
            {description}
          </span>
        </label>
      )}
      <input
        id={`file-mariage-${name}`}
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
      <div className="flex items-center gap-3 p-4 bg-rose-50 dark:bg-rose-900/10 border border-rose-200 dark:border-rose-800 rounded-xl">
        <div className="h-10 w-10 rounded-full bg-rose-100 dark:bg-rose-900/30 flex items-center justify-center shrink-0">
          <Heart className="h-5 w-5 text-rose-600 dark:text-rose-400" />
        </div>
        <div>
          <h3 className="font-semibold text-rose-800 dark:text-rose-300 font-jakarta">
            Extrait de Mariage
          </h3>
          <p className="text-sm text-rose-600/80 dark:text-rose-400/80">
            Remplissez les informations des époux et joignez les CNI requises.
          </p>
        </div>
      </div>

      {/* Section — Informations des époux */}
      <div className="space-y-1">
        <h4 className="text-sm font-semibold text-text-300 uppercase tracking-wider">
          Informations des époux
        </h4>
        <div className="h-px bg-border-subtle" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Nom de l'époux */}
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Nom complet de l'époux *</label>
          <input
            type="text"
            name="nom_epoux"
            value={formData.nom_epoux}
            onChange={handleChange}
            className={`w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow ${erreurs.nom_epoux ? 'border-red-400' : 'border-border-strong'
              }`}
            placeholder="Ex : Ibrahima Diop"
          />
          {erreurs.nom_epoux && (
            <p className="text-xs text-red-500 flex items-center gap-1">
              <AlertCircle className="h-3 w-3" /> {erreurs.nom_epoux}
            </p>
          )}
        </div>

        {/* Nom de l'épouse */}
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Nom complet de l'épouse *</label>
          <input
            type="text"
            name="nom_epouse"
            value={formData.nom_epouse}
            onChange={handleChange}
            className={`w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow ${erreurs.nom_epouse ? 'border-red-400' : 'border-border-strong'
              }`}
            placeholder="Ex : Fatou Sarr"
          />
          {erreurs.nom_epouse && (
            <p className="text-xs text-red-500 flex items-center gap-1">
              <AlertCircle className="h-3 w-3" /> {erreurs.nom_epouse}
            </p>
          )}
        </div>

        {/* Date du mariage */}
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Date du mariage *</label>
          <input
            type="date"
            name="date_mariage"
            value={formData.date_mariage}
            onChange={handleChange}
            className={`w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow ${erreurs.date_mariage ? 'border-red-400' : 'border-border-strong'
              }`}
          />
          {erreurs.date_mariage && (
            <p className="text-xs text-red-500 flex items-center gap-1">
              <AlertCircle className="h-3 w-3" /> {erreurs.date_mariage}
            </p>
          )}
        </div>

        {/* Lieu du mariage */}
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Lieu du mariage *</label>
          <input
            type="text"
            name="lieu_mariage"
            value={formData.lieu_mariage}
            onChange={handleChange}
            className={`w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-shadow ${erreurs.lieu_mariage ? 'border-red-400' : 'border-border-strong'
              }`}
            placeholder="Ex : Mairie de Dakar Plateau"
          />
          {erreurs.lieu_mariage && (
            <p className="text-xs text-red-500 flex items-center gap-1">
              <AlertCircle className="h-3 w-3" /> {erreurs.lieu_mariage}
            </p>
          )}
        </div>
      </div>

      {/* Section — Pièces jointes (4 CNI) */}
      <div className="space-y-1 mt-2">
        <h4 className="text-sm font-semibold text-text-300 uppercase tracking-wider">
          Pièces justificatives — CNI des parties
        </h4>
        <div className="h-px bg-border-subtle" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <FileUploadField
          name="cni_epoux"
          label="CNI de l'Époux"
          description="Charger la CNI de l'époux"
        />
        <FileUploadField
          name="cni_epouse"
          label="CNI de l'Épouse"
          description="Charger la CNI de l'épouse"
        />
        <FileUploadField
          name="cni_temoin_1"
          label="CNI du Témoin 1"
          description="Charger la CNI du témoin 1"
        />
        <FileUploadField
          name="cni_temoin_2"
          label="CNI du Témoin 2"
          description="Charger la CNI du témoin 2"
        />
      </div>

      {/* Compteur de pièces jointes */}
      <div className="flex items-center gap-2 text-sm text-text-400">
        <FileImage className="h-4 w-4" />
        <span>
          {Object.values(fichiers).filter(Boolean).length} / 4 pièces jointes sélectionnées
        </span>
        {Object.values(fichiers).filter(Boolean).length === 4 && (
          <span className="text-emerald-500 font-medium ml-1">✓ Complet</span>
        )}
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
