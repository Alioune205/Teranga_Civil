import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { processGuichetRapide, downloadPdfWithAuth } from '@/services/citoyenApi';
import { useToast } from '@/components/ui/use-toast';
import { Loader2, ArrowRight, ArrowLeft, Check, Zap, Download, Printer, Search, Users } from 'lucide-react';
// ─── Formulaires spécialisés pour Résidence et Mariage (Tâche 9 — DEV 1B) ───
import FormulaireResidence from './FormulaireResidence';
import FormulaireMariage from './FormulaireMariage';
import FormulaireRegularisation from './FormulaireRegularisation';
import FormulaireAutorisationConstruire from './FormulaireAutorisationConstruire';
import FormulaireMutationParcelle from './FormulaireMutationParcelle';

const DOCUMENT_TYPES = [
  { id: 'birth_certificate', label: 'Extrait de naissance', price: 1000 },
  { id: 'marriage_certificate', label: 'Acte de mariage', price: 2500 },
  { id: 'death_certificate', label: 'Acte de décès', price: 1000 },
  { id: 'residence_certificate', label: 'Certificat résidence', price: 1500 },
  { id: 'regularisation', label: 'Régularisation Foncier', price: 1000 },
  { id: 'autorisation_construire', label: 'Autorisation de construire', price: 1000 },
  { id: 'mutation_parcelle', label: 'Mutation de parcelle', price: 'Variable' },
  { id: 'other', label: 'Autre document', price: 2000 },
];

// Types de documents nécessitant un formulaire dédié avec pièces jointes
const TYPES_FORMULAIRE_DEDIE = ['residence_certificate', 'marriage_certificate', 'regularisation', 'autorisation_construire', 'mutation_parcelle'];

const PAYMENT_MODES = [
  'Espèces', 'Wave', 'Orange Money', 'Free Money', 'Exonéré'
];

export default function GuichetRapide({ open, onOpenChange, initialCitoyen = null, onOpenNouveauCitoyen }) {
  const { toast } = useToast();
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);

  const [citoyen, setCitoyen] = useState(initialCitoyen);
  // Pour l'étape 1, si le citoyen n'est pas passé en prop, il faudrait implémenter la recherche.
  // Pour la concision de cet exemple, on suppose que l'utilisateur le sélectionnera ou utilisera NouveauCitoyen

  const [formData, setFormData] = useState({
    type_document: '',
    motif: '',
    paiement_mode: 'Espèces',
    montant: 0,
    telephone_paiement: ''
  });

  useEffect(() => {
    if (open) {
      setStep(1);
      setResult(null);
      setCitoyen(initialCitoyen);
      setFormData({
        type_document: '', motif: '', paiement_mode: 'Espèces', montant: 0, telephone_paiement: ''
      });
      if (initialCitoyen) {
        setStep(2); // On passe directement à l'étape 2 si le citoyen est déjà fourni
      }
    }
  }, [open, initialCitoyen]);

  const handleSelectDocument = (doc) => {
    setFormData(prev => ({ ...prev, type_document: doc.id, montant: doc.price }));
  };

  // Vérifie si le type de document sélectionné nécessite un formulaire dédié
  const estFormulaireDedié = TYPES_FORMULAIRE_DEDIE.includes(formData.type_document);

  const handleNext = () => {
    if (step === 1 && !citoyen) {
      toast({ title: "Erreur", description: "Veuillez sélectionner un citoyen", variant: "destructive" });
      return;
    }
    if (step === 2 && !formData.type_document) {
      toast({ title: "Erreur", description: "Veuillez sélectionner un type de document", variant: "destructive" });
      return;
    }
    // Si formulaire dédié sélectionné, aller à l'étape 5 (formulaire spécialisé)
    if (step === 2 && estFormulaireDedié) {
      setStep(5);
      return;
    }
    setStep(s => s + 1);
  };

  // Callback de succès pour les formulaires dédiés (Résidence / Mariage)
  const handleFormulaireDediéSuccess = (result) => {
    setResult(result);
    setStep(4);
    toast({
      title: "Succès",
      description: "La demande a été enregistrée avec succès.",
      className: "bg-emerald-50 text-emerald-900 border-emerald-200"
    });
  };

  const downloadPdfForce = async (pdfUrl, ref) => {
    try {
      const blob = await downloadPdfWithAuth(pdfUrl);
      const url = window.URL.createObjectURL(new Blob([blob], { type: 'application/pdf' }));
      const link = document.createElement('a');
      link.href = url;
      link.target = '_blank';
      link.download = `Certificat_${ref}.pdf`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      setTimeout(() => window.URL.revokeObjectURL(url), 1000);
    } catch (err) {
      console.error("Erreur téléchargement auto:", err);
      toast({
        title: "Erreur",
        description: "Le PDF a été généré mais n'a pas pu s'ouvrir automatiquement. Veuillez utiliser le bouton Télécharger.",
        variant: "destructive"
      });
    }
  };

  const handleSubmit = async () => {
    if (!formData.paiement_mode) {
      toast({ title: "Erreur", description: "Veuillez choisir un mode de paiement", variant: "destructive" });
      return;
    }

    setLoading(true);
    try {
      const res = await processGuichetRapide(citoyen.id, {
        type_document: formData.type_document,
        motif: formData.motif,
        paiement_mode: formData.paiement_mode,
        montant: formData.montant
      });
      setResult(res);
      setStep(4); // Écran de succès
      toast({
        title: "Succès",
        description: "Dossier créé et envoyé au Superviseur pour approbation.",
        className: "bg-emerald-50 text-emerald-900 border-emerald-200"
      });

      // Auto download desactivé car en attente d'approbation
      // if (res.pdf_url) {
      //   downloadPdfForce(res.pdf_url, res.reference);
      // }

    } catch (error) {
      let errorMessage = "Erreur lors du traitement";
      if (error.response?.data) {
        if (error.response.data.message) {
          errorMessage = error.response.data.message;
        } else if (error.response.data.detail) {
          errorMessage = error.response.data.detail;
        }
      }

      toast({
        title: "Erreur",
        description: errorMessage,
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadPdf = async () => {
    if (!result?.pdf_url) return;
    try {
      setLoading(true);
      toast({
        title: "Téléchargement",
        description: "Ouverture du PDF en cours...",
      });
      const blob = await downloadPdfWithAuth(result.pdf_url);
      const url = window.URL.createObjectURL(new Blob([blob], { type: 'application/pdf' }));

      // Utilisation d'un lien <a> pour forcer l'ouverture/téléchargement et éviter le blocage des popups
      const link = document.createElement('a');
      link.href = url;
      link.target = '_blank';
      link.download = `Certificat_${result.reference}.pdf`; // Ceci force le téléchargement
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      // Nettoyage de l'URL pour libérer la mémoire (optionnel, mais recommandé)
      setTimeout(() => window.URL.revokeObjectURL(url), 1000);

    } catch (error) {
      console.error("Erreur téléchargement PDF:", error);
      toast({
        title: "Erreur",
        description: "Impossible d'ouvrir le PDF.",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl bg-layer-1 border-border-strong p-0 overflow-hidden">
        {step !== 4 ? (
          <>
            <DialogHeader className="p-6 border-b border-border-subtle bg-layer-2">
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-full bg-emerald-500/10 flex items-center justify-center">
                  <Zap className="h-5 w-5 text-emerald-500" />
                </div>
                <div>
                  <DialogTitle className="text-xl font-bold text-text-100 font-jakarta">Guichet Rapide</DialogTitle>
                  <p className="text-sm text-text-400 mt-1">
                    {step === 5
                      ? `Formulaire : ${formData.type_document === 'residence_certificate' ? 'Certificat de Résidence' : formData.type_document === 'marriage_certificate' ? 'Extrait de Mariage' : formData.type_document === 'mutation_parcelle' ? 'Mutation de Parcelle' : 'Demande'}`
                      : `Étape ${step} sur 3 : ${step === 1 ? 'Identification' : step === 2 ? 'Document' : 'Paiement'}`
                    }
                  </p>
                </div>
              </div>

              <div className="w-full h-1.5 bg-layer-3 rounded-full mt-4 overflow-hidden">
                <div
                  className="h-full bg-emerald-500 transition-all duration-300 ease-in-out"
                  style={{ width: step === 5 ? '100%' : `${(step / 3) * 100}%` }}
                />
              </div>
            </DialogHeader>

            <div className={`p-6 ${step === 5 ? 'max-h-[70vh] overflow-y-auto' : 'min-h-[300px]'}`}>
              {step === 1 && (
                <div className="space-y-6">
                  {citoyen ? (
                    <div className="p-4 bg-layer-2 border border-border-strong rounded-lg flex items-center gap-4">
                      <div className="w-12 h-12 rounded-full bg-primary flex items-center justify-center text-white font-bold text-lg">
                        {citoyen.prenom.charAt(0)}{citoyen.nom.charAt(0)}
                      </div>
                      <div className="flex-1">
                        <h3 className="font-medium text-text-100">{citoyen.nom_complet}</h3>
                        <p className="text-sm text-text-400">{citoyen.telephone} • {citoyen.commune?.name}</p>
                      </div>
                      <Button variant="outline" size="sm" onClick={() => setCitoyen(null)}>Changer</Button>
                    </div>
                  ) : (
                    <div className="text-center py-8">
                      <p className="text-text-400 mb-4">Pour utiliser le guichet rapide, vous devez identifier le citoyen.</p>
                      {/* Pour l'instant on force à passer par le bouton Nouveau Citoyen si pas de recherche implémentée */}
                      <Button onClick={() => { onOpenChange(false); onOpenNouveauCitoyen(true); }} className="bg-primary text-white">
                        <Users className="h-4 w-4 mr-2" />
                        Créer un nouveau citoyen
                      </Button>
                    </div>
                  )}
                </div>
              )}

              {step === 2 && (
                <div className="space-y-6">
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                    {DOCUMENT_TYPES.map(doc => (
                      <div
                        key={doc.id}
                        onClick={() => handleSelectDocument(doc)}
                        className={`p-4 rounded-xl border-2 cursor-pointer transition-all ${formData.type_document === doc.id
                            ? 'border-primary bg-primary/5 shadow-sm'
                            : 'border-border-strong bg-layer-2 hover:border-primary/50'
                          }`}
                      >
                        <h4 className={`font-medium mb-1 ${formData.type_document === doc.id ? 'text-primary' : 'text-text-100'}`}>
                          {doc.label}
                        </h4>
                        <p className="text-sm text-text-400">{typeof doc.price === 'number' ? doc.price.toLocaleString('fr-FR') + ' FCFA' : doc.price}</p>
                      </div>
                    ))}
                  </div>

                  <div className="space-y-2 mt-6">
                    <label className="text-sm font-medium text-text-200">Motif ou précision (facultatif)</label>
                    <textarea
                      value={formData.motif}
                      onChange={(e) => setFormData(prev => ({ ...prev, motif: e.target.value }))}
                      className="w-full p-3 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none min-h-[80px]"
                      placeholder="Ex: Pour une inscription scolaire..."
                    />
                  </div>
                </div>
              )}

              {step === 3 && (
                <div className="space-y-6">
                  <div className="bg-layer-2 border border-border-strong rounded-lg p-4">
                    <h3 className="text-sm font-semibold text-text-400 uppercase tracking-wider mb-4">Récapitulatif</h3>
                    <div className="space-y-2 text-sm">
                      <div className="flex justify-between">
                        <span className="text-text-300">Citoyen</span>
                        <span className="font-medium text-text-100">{citoyen?.nom_complet}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-text-300">Document</span>
                        <span className="font-medium text-text-100">
                          {DOCUMENT_TYPES.find(d => d.id === formData.type_document)?.label}
                        </span>
                      </div>
                      <div className="border-t border-border-subtle my-2 pt-2 flex justify-between">
                        <span className="text-text-200 font-medium">Montant à payer</span>
                        <span className="font-bold text-lg text-emerald-500">
                          {typeof formData.montant === 'number' ? formData.montant.toLocaleString('fr-FR') + ' FCFA' : formData.montant}
                        </span>
                      </div>
                    </div>
                  </div>

                  {formData.montant > 0 || formData.montant === 'Variable' ? (
                    <div className="space-y-3">
                      <label className="text-sm font-medium text-text-200">Mode de paiement</label>
                      <div className="flex flex-wrap gap-2">
                        {PAYMENT_MODES.map(mode => (
                          <button
                            key={mode}
                            onClick={() => {
                              setFormData(prev => ({
                                ...prev,
                                paiement_mode: mode,
                                montant: mode === 'Exonéré' ? 0 : DOCUMENT_TYPES.find(d => d.id === formData.type_document)?.price || 0
                              }));
                            }}
                            className={`px-4 py-2 rounded-lg border font-medium text-sm transition-colors ${formData.paiement_mode === mode
                                ? 'border-emerald-500 bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400'
                                : 'border-border-strong bg-layer-2 text-text-300 hover:bg-layer-3'
                              }`}
                          >
                            {mode}
                          </button>
                        ))}
                      </div>
                    </div>
                  ) : (
                    <div className="p-3 bg-emerald-50 dark:bg-emerald-900/10 border border-emerald-200 dark:border-emerald-800 rounded-lg text-emerald-700 dark:text-emerald-400 text-sm">
                      Cette démarche est exonérée ou gratuite. Aucun paiement n'est requis.
                    </div>
                  )}
                </div>
              )}

              {/* Étape 5 — Formulaire dédié (Résidence ou Mariage) */}
              {step === 5 && formData.type_document === 'residence_certificate' && (
                <FormulaireResidence
                  citoyenId={citoyen.id}
                  citoyen={citoyen}
                  paymentData={{ mode: formData.paiement_mode, montant: formData.montant }}
                  onSuccess={handleFormulaireDediéSuccess}
                  onCancel={() => setStep(2)}
                />
              )}

              {step === 5 && formData.type_document === 'marriage_certificate' && (
                <FormulaireMariage
                  onSuccess={handleFormulaireDediéSuccess}
                  onCancel={() => setStep(2)}
                />
              )}

              {step === 5 && formData.type_document === 'regularisation' && (
                <FormulaireRegularisation
                  citoyenId={citoyen?.id}
                  citoyen={citoyen}
                  paymentData={{ mode: formData.paiement_mode, montant: formData.montant }}
                  onSuccess={handleFormulaireDediéSuccess}
                  onCancel={() => setStep(2)}
                />
              )}
              {step === 5 && formData.type_document === 'autorisation_construire' && (
                <FormulaireAutorisationConstruire
                  citoyenId={citoyen?.id}
                  citoyen={citoyen}
                  paymentData={{ mode: formData.paiement_mode, montant: formData.montant }}
                  onSuccess={handleFormulaireDediéSuccess}
                  onCancel={() => setStep(2)}
                />
              )}

              {step === 5 && formData.type_document === 'mutation_parcelle' && (
                <FormulaireMutationParcelle
                  citoyenId={citoyen?.id}
                  citoyen={citoyen}
                  paymentData={{ mode: formData.paiement_mode, montant: formData.montant }}
                  onSuccess={handleFormulaireDediéSuccess}
                  onCancel={() => setStep(2)}
                />
              )}
            </div>

            {/* Barre de navigation — masquée à l'étape 5 (le formulaire dédié a sa propre barre) */}
            {step !== 5 && (
              <div className="p-4 border-t border-border-subtle bg-layer-2 flex justify-between">
                {step === 1 ? (
                  <Button variant="ghost" onClick={() => onOpenChange(false)}>Annuler</Button>
                ) : (
                  <Button variant="outline" onClick={() => setStep(s => s - 1)} className="gap-2">
                    <ArrowLeft className="h-4 w-4" /> Précédent
                  </Button>
                )}

                {step < 3 ? (
                  <Button onClick={handleNext} disabled={step === 1 && !citoyen} className="bg-primary text-white hover:bg-primary-hover gap-2">
                    Suivant <ArrowRight className="h-4 w-4" />
                  </Button>
                ) : (
                  <Button onClick={handleSubmit} disabled={loading} className="bg-emerald-600 text-white hover:bg-emerald-700 gap-2">
                    {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
                    Générer et Imprimer
                  </Button>
                )}
              </div>
            )}
          </>
        ) : (
          <div className="p-10 text-center flex flex-col items-center">
            <div className="w-20 h-20 bg-emerald-100 dark:bg-emerald-900/30 rounded-full flex items-center justify-center mb-6">
              <Check className="h-10 w-10 text-emerald-500" />
            </div>

            <h2 className="text-2xl font-bold text-text-100 font-jakarta mb-2">Demande envoyée avec succès !</h2>
            <p className="text-text-400 mb-6">Dossier créé et envoyé au Superviseur pour approbation.</p>

            <div className="bg-layer-2 border border-border-strong rounded-xl p-6 w-full max-w-sm mb-8">
              <p className="text-sm text-text-400 uppercase tracking-wider font-semibold mb-1">Référence</p>
              <p className="text-3xl font-mono font-bold text-text-100">{result?.reference}</p>
            </div>

            <div className="flex flex-col sm:flex-row gap-3 w-full max-w-md">
              {/* Boutons de téléchargement masqués car en attente d'approbation */}
            </div>

            <Button variant="ghost" onClick={() => onOpenChange(false)} className="mt-6 text-text-400">
              Fermer le guichet
            </Button>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
