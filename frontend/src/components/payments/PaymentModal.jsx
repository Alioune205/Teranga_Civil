import { useState } from 'react';
import axiosClient from '@/api/axiosClient';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { toast } from '@/components/ui/use-toast';
import { X, CreditCard, Wallet, Landmark, Coins, FileText, Loader2 } from 'lucide-react';

const PAYMENT_MODES = [
  { value: 'cash', label: 'Espèces', icon: Coins, color: 'text-emerald-500 bg-emerald-50' },
  { value: 'wave', label: 'Wave', icon: Wallet, color: 'text-sky-500 bg-sky-50' },
  { value: 'orange_money', label: 'Orange Money', icon: Wallet, color: 'text-orange-500 bg-orange-50' },
  { value: 'free_money', label: 'Free Money', icon: Wallet, color: 'text-red-500 bg-red-50' },
  { value: 'card', label: 'Carte bancaire', icon: CreditCard, color: 'text-indigo-500 bg-indigo-50' },
];

export default function PaymentModal({ isOpen, onClose, dossier, onSuccess }) {
  if (!isOpen || !dossier) return null;

  // Montant par défaut à 500 XOF
  const [amount, setAmount] = useState(500);
  const [paymentType, setPaymentType] = useState('cash');
  const [transactionReference, setTransactionReference] = useState('');
  const [comment, setComment] = useState('');
  const [loading, setLoading] = useState(false);

  const isMobilePayment = ['wave', 'orange_money', 'free_money'].includes(paymentType);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (isMobilePayment && !transactionReference.trim()) {
      toast({
        title: 'Erreur de saisie',
        description: 'La référence de transaction est obligatoire pour les paiements mobiles.',
        variant: 'destructive',
      });
      return;
    }

    setLoading(true);
    try {
      // 1. Enregistrer le paiement
      const res = await axiosClient.post('/api/guichet/register/', {
        dossier_id: dossier.id,
        amount: parseFloat(amount),
        payment_type: paymentType,
        transaction_reference: isMobilePayment ? transactionReference : '',
        comment: comment,
      });

      const paymentData = res.data?.data || res.data;

      toast({
        title: 'Paiement validé ! 💸',
        description: `Le paiement d'un montant de ${amount} XOF a été enregistré.`,
        className: 'bg-green-50 border-green-200 text-green-900',
      });

      // 2. Télécharger automatiquement le reçu PDF
      try {
        const receiptRes = await axiosClient.get(`/api/transactions/${paymentData.transaction_id}/receipt/`, {
          responseType: 'blob',
        });
        const blob = new Blob([receiptRes.data], { type: 'application/pdf' });
        const downloadUrl = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = downloadUrl;
        link.setAttribute('download', `recu_${paymentData.receipt_number}.pdf`);
        document.body.appendChild(link);
        link.click();
        link.remove();
        window.URL.revokeObjectURL(downloadUrl);
      } catch (pdfErr) {
        console.error('Erreur lors du téléchargement du reçu PDF', pdfErr);
        toast({
          title: 'Téléchargement impossible',
          description: 'Le paiement est validé mais le reçu PDF n\'a pas pu être téléchargé.',
          variant: 'warning',
        });
      }

      if (onSuccess) onSuccess();
      onClose();
    } catch (err) {
      console.error(err);
      toast({
        title: 'Erreur',
        description: err.response?.data?.message || 'Une erreur est survenue lors de la validation du paiement.',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const getDossierTypeLabel = (type) => {
    const types = {
      birth_certificate: 'Acte de naissance',
      marriage_certificate: 'Acte de mariage',
      death_certificate: 'Acte de décès',
      residence_certificate: 'Certificat de résidence',
    };
    return types[type] || 'Document administratif';
  };

  const citizenName = dossier.citizen_name || (dossier.citoyen_guichet ? `${dossier.citoyen_guichet.prenom} ${dossier.citoyen_guichet.nom}` : 'Citoyen');

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center p-4">
      {/* Backdrop */}
      <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity" onClick={onClose} />

      {/* Modal Content */}
      <div className="relative bg-layer-1 w-full max-w-lg rounded-2xl shadow-xl border border-border-strong overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-border-subtle">
          <div className="flex items-center gap-2.5">
            <div className="p-2 bg-[#1D4ED8]/10 text-[#1D4ED8] rounded-xl">
              <CreditCard className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-text-100">Enregistrer un paiement</h3>
              <p className="text-xs text-text-400">Guichet communal d'état civil</p>
            </div>
          </div>
          <button 
            onClick={onClose}
            className="p-1.5 rounded-lg text-text-400 hover:bg-layer-3 dark:hover:bg-slate-900 transition-colors focus:outline-none"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          
          {/* Infos dossier (Lecture seule) */}
          <div className="bg-layer-2 p-4 rounded-xl border border-border-subtle/60 space-y-2">
            <div className="flex justify-between text-xs">
              <span className="text-text-400 font-medium">Citoyen</span>
              <span className="font-semibold text-text-200">{citizenName}</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-text-400 font-medium">Demande</span>
              <span className="font-semibold text-text-200 font-mono">{dossier.reference}</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-text-400 font-medium">Service</span>
              <span className="font-semibold text-text-200">{getDossierTypeLabel(dossier.type)}</span>
            </div>
          </div>

          {/* Montant */}
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-text-400 uppercase tracking-wider block">Montant à payer (XOF)</label>
            <Input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="focus-visible:ring-[#1D4ED8] font-bold text-base"
              min="0"
              required
            />
          </div>

          {/* Mode de paiement */}
          <div className="space-y-2">
            <label className="text-xs font-semibold text-text-400 uppercase tracking-wider block">Mode de paiement</label>
            <div className="grid grid-cols-2 gap-2">
              {PAYMENT_MODES.map((mode) => {
                const Icon = mode.icon;
                const isSelected = paymentType === mode.value;
                return (
                  <button
                    key={mode.value}
                    type="button"
                    onClick={() => {
                      setPaymentType(mode.value);
                      if (!['wave', 'orange_money', 'free_money'].includes(mode.value)) {
                        setTransactionReference('');
                      }
                    }}
                    className={`flex items-center gap-2.5 p-3 rounded-xl border text-sm font-medium transition-all text-left focus:outline-none ${
                      isSelected 
                        ? 'border-[#1D4ED8] bg-[#1D4ED8]/5 text-[#1D4ED8] ring-2 ring-[#1D4ED8]/10' 
                        : 'border-border-strong text-text-300 hover:bg-layer-2 dark:hover:bg-slate-900'
                    }`}
                  >
                    <div className={`p-1.5 rounded-lg ${mode.color}`}>
                      <Icon className="h-4 w-4" />
                    </div>
                    {mode.label}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Référence de transaction (Mobile) */}
          {isMobilePayment && (
            <div className="space-y-1.5 animate-in slide-in-from-top-2 duration-150">
              <label className="text-xs font-semibold text-[#1D4ED8] uppercase tracking-wider block">Référence de transaction opérateur</label>
              <Input
                type="text"
                placeholder="Ex: OM_TX_98765 ou WAVE_REF..."
                value={transactionReference}
                onChange={(e) => setTransactionReference(e.target.value)}
                className="focus-visible:ring-[#1D4ED8] font-semibold"
                required
              />
              <p className="text-[10px] text-text-400">Obligatoire pour le suivi du paiement mobile.</p>
            </div>
          )}

          {/* Commentaire */}
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-text-400 uppercase tracking-wider block">Commentaire (Optionnel)</label>
            <textarea
              placeholder="Notes additionnelles sur le paiement..."
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              className="w-full min-h-[60px] p-3 text-sm bg-layer-2 border border-border-strong rounded-md text-text-100 placeholder:text-text-400 focus-visible:outline-none focus-visible:border-[#1D4ED8] focus-visible:ring-2 focus-visible:ring-[#1D4ED8]/20"
            />
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end gap-2 pt-2">
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
              disabled={loading}
              className="px-5 focus:ring-[#1D4ED8]"
            >
              Annuler
            </Button>
            <Button
              type="submit"
              disabled={loading}
              className="bg-[#1D4ED8] hover:bg-[#1D4ED8]/90 text-white font-semibold px-6 gap-2 focus:ring-[#1D4ED8]"
            >
              {loading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Validation...
                </>
              ) : (
                <>
                  <FileText className="h-4 w-4" />
                  Valider & reçu PDF
                </>
              )}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
