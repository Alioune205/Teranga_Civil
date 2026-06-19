import React, { useState } from 'react';
import { X, Building2, UserPlus, CheckCircle, Copy, Loader2 } from 'lucide-react';
import api from '@/api/axiosClient';
import { useToast } from '@/components/ui/use-toast';

export default function WizardNouvelleMairie({ isOpen, onClose, onSuccess }) {
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const { toast } = useToast();

  const [formData, setFormData] = useState({
    name: '',
    region: '',
    department: '',
    address: '',
    phone: '',
    admin_general: { first_name: '', last_name: '', email: '' },
    admin_rh: { first_name: '', last_name: '', email: '' },
  });

  const regions = [
    'Dakar', 'Thiès', 'Diourbel', 'Fatick', 'Kaffrine', 'Kaolack', 'Kédougou', 
    'Kolda', 'Louga', 'Matam', 'Saint-Louis', 'Sédhiou', 'Tambacounda', 'Ziguinchor'
  ];

  if (!isOpen) return null;

  const handleNext = () => {
    if (step === 1) {
      if (!formData.name || !formData.region || !formData.department) {
        toast({ title: "Erreur", description: "Veuillez remplir les champs obligatoires (Nom, Région, Département).", variant: "destructive" });
        return;
      }
      setStep(2);
    } else if (step === 2) {
      if (!formData.admin_general.email || !formData.admin_general.last_name || !formData.admin_rh.email || !formData.admin_rh.last_name) {
        toast({ title: "Erreur", description: "Veuillez remplir les noms et emails des administrateurs.", variant: "destructive" });
        return;
      }
      handleSubmit();
    }
  };

  const handleSubmit = async () => {
    setLoading(true);
    try {
      const res = await api.post('/api/dashboard/superadmin/communes/manage/', formData);
      setResult(res.data);
      setStep(3);
      if (onSuccess) onSuccess();
    } catch (error) {
      toast({ 
        title: "Erreur de création", 
        description: error.response?.data?.error || "Une erreur est survenue.", 
        variant: "destructive" 
      });
    } finally {
      setLoading(false);
    }
  };

  const copyCredentials = () => {
    if (!result) return;
    const text = result.credentials.map(c => `Rôle: ${c.role_label}\nEmail: ${c.email}\nMot de passe: ${c.temp_password}`).join('\n\n');
    navigator.clipboard.writeText(`--- IDENTIFIANTS MAIRIE: ${result.commune.name} ---\n\n${text}`);
    toast({ title: "Copié", description: "Les identifiants ont été copiés dans le presse-papier." });
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
        <div className="p-6 border-b flex justify-between items-center bg-layer-2">
          <div>
            <h2 className="text-xl font-bold text-text-200">Nouvelle Mairie</h2>
            <p className="text-sm text-text-400">Étape {step} sur 2</p>
          </div>
          {step !== 3 && (
            <button onClick={onClose} className="text-text-400 hover:text-text-200 bg-white p-2 rounded-full shadow-sm">
              <X className="w-5 h-5" />
            </button>
          )}
        </div>

        <div className="p-6 overflow-y-auto">
          {step === 1 && (
            <div className="space-y-4">
              <div className="flex items-center gap-3 mb-6">
                <div className="bg-primary/10 p-3 rounded-xl text-primary"><Building2 className="w-6 h-6" /></div>
                <h3 className="font-bold text-lg text-text-200">Informations de la Commune</h3>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-200 mb-1">Nom de la commune *</label>
                <input type="text" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} className="w-full border rounded-lg p-2" placeholder="Ex: Dakar Plateau" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-text-200 mb-1">Région *</label>
                  <select value={formData.region} onChange={e => setFormData({...formData, region: e.target.value})} className="w-full border rounded-lg p-2">
                    <option value="">Sélectionner...</option>
                    {regions.map(r => <option key={r} value={r}>{r}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-text-200 mb-1">Département *</label>
                  <input type="text" value={formData.department} onChange={e => setFormData({...formData, department: e.target.value})} className="w-full border rounded-lg p-2" placeholder="Département" />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-text-200 mb-1">Téléphone</label>
                  <input type="text" value={formData.phone} onChange={e => setFormData({...formData, phone: e.target.value})} className="w-full border rounded-lg p-2" placeholder="+221 ..." />
                </div>
                <div>
                  <label className="block text-sm font-medium text-text-200 mb-1">Adresse</label>
                  <input type="text" value={formData.address} onChange={e => setFormData({...formData, address: e.target.value})} className="w-full border rounded-lg p-2" placeholder="Adresse complète" />
                </div>
              </div>
            </div>
          )}

          {step === 2 && (
            <div className="space-y-6">
              <div className="flex items-center gap-3 mb-2">
                <div className="bg-emerald-100 p-3 rounded-xl text-emerald-600"><UserPlus className="w-6 h-6" /></div>
                <h3 className="font-bold text-lg text-text-200">Création des Administrateurs</h3>
              </div>

              {/* Admin General */}
              <div className="bg-layer-2 p-4 rounded-xl border border-border-strong">
                <h4 className="font-bold text-text-200 mb-3 text-sm">Administrateur Général (Superviseur)</h4>
                <div className="grid grid-cols-2 gap-3 mb-3">
                  <input type="text" placeholder="Prénom" value={formData.admin_general.first_name} onChange={e => setFormData({...formData, admin_general: {...formData.admin_general, first_name: e.target.value}})} className="border rounded-lg p-2 text-sm" />
                  <input type="text" placeholder="Nom *" value={formData.admin_general.last_name} onChange={e => setFormData({...formData, admin_general: {...formData.admin_general, last_name: e.target.value}})} className="border rounded-lg p-2 text-sm" />
                </div>
                <input type="email" placeholder="Email de connexion *" value={formData.admin_general.email} onChange={e => setFormData({...formData, admin_general: {...formData.admin_general, email: e.target.value}})} className="w-full border rounded-lg p-2 text-sm" />
              </div>

              {/* Admin RH */}
              <div className="bg-layer-2 p-4 rounded-xl border border-border-strong">
                <h4 className="font-bold text-text-200 mb-3 text-sm">Administrateur RH (Civil)</h4>
                <div className="grid grid-cols-2 gap-3 mb-3">
                  <input type="text" placeholder="Prénom" value={formData.admin_rh.first_name} onChange={e => setFormData({...formData, admin_rh: {...formData.admin_rh, first_name: e.target.value}})} className="border rounded-lg p-2 text-sm" />
                  <input type="text" placeholder="Nom *" value={formData.admin_rh.last_name} onChange={e => setFormData({...formData, admin_rh: {...formData.admin_rh, last_name: e.target.value}})} className="border rounded-lg p-2 text-sm" />
                </div>
                <input type="email" placeholder="Email de connexion *" value={formData.admin_rh.email} onChange={e => setFormData({...formData, admin_rh: {...formData.admin_rh, email: e.target.value}})} className="w-full border rounded-lg p-2 text-sm" />
              </div>
            </div>
          )}

          {step === 3 && result && (
            <div className="text-center py-6">
              <CheckCircle className="w-16 h-16 text-emerald-500 mx-auto mb-4" />
              <h3 className="text-2xl font-bold text-text-200 mb-2">Mairie créée avec succès !</h3>
              <p className="text-text-400 mb-6">Commune de {result.commune.name}</p>

              <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 text-left mb-6">
                <p className="text-amber-800 text-sm font-medium mb-3">
                  ⚠️ Sauvegardez ces identifiants temporaires, ils ne seront plus jamais affichés. Les utilisateurs devront changer leur mot de passe à la première connexion.
                </p>
                <div className="space-y-3">
                  {result.credentials.map((cred, idx) => (
                    <div key={idx} className="bg-white p-3 rounded-lg border border-amber-100 flex justify-between items-center">
                      <div>
                        <div className="text-xs font-bold text-text-400 uppercase">{cred.role_label}</div>
                        <div className="font-medium text-text-200">{cred.email}</div>
                      </div>
                      <div className="font-mono bg-layer-3 px-3 py-1 rounded text-primary font-bold tracking-wider">
                        {cred.temp_password}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="flex gap-4 justify-center">
                <button onClick={copyCredentials} className="flex items-center gap-2 px-6 py-2 bg-slate-800 text-white rounded-lg font-medium hover:bg-slate-700">
                  <Copy className="w-4 h-4" /> Copier tout
                </button>
                <button onClick={onClose} className="px-6 py-2 bg-emerald-500 text-white rounded-lg font-medium hover:bg-emerald-600">
                  Terminer
                </button>
              </div>
            </div>
          )}
        </div>

        {step < 3 && (
          <div className="p-4 border-t bg-layer-2 flex justify-end gap-3">
            <button onClick={onClose} className="px-4 py-2 text-text-300 hover:bg-border-strong rounded-lg font-medium">Annuler</button>
            <button onClick={handleNext} disabled={loading} className="px-6 py-2 bg-primary text-white rounded-lg font-medium hover:bg-primary/90 flex items-center gap-2">
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              {step === 1 ? 'Suivant' : 'Créer la Mairie'}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
