import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { getCommuneList } from '@/api/communes';
import { createCitoyen } from '@/services/citoyenApi';
import { useToast } from '@/components/ui/use-toast';
import { Loader2, ArrowRight, ArrowLeft, Check, Users } from 'lucide-react';

export default function NouveauCitoyen({ open, onOpenChange, onSuccess }) {
  const { toast } = useToast();
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [communes, setCommunes] = useState([]);
  
  const [formData, setFormData] = useState({
    prenom: '',
    nom: '',
    date_naissance: '',
    lieu_naissance: '',
    sexe: 'M',
    nationalite: 'Sénégalaise',
    telephone: '',
    email: '',
    adresse: '',
    quartier: '',
    commune: '',
    numero_cni: '',
    date_expiration_cni: '',
    numero_passeport: '',
  });

  useEffect(() => {
    if (open) {
      setStep(1);
      setFormData({
        prenom: '', nom: '', date_naissance: '', lieu_naissance: '',
        sexe: 'M', nationalite: 'Sénégalaise', telephone: '', email: '',
        adresse: '', quartier: '', commune: '', numero_cni: '',
        date_expiration_cni: '', numero_passeport: ''
      });
      loadCommunes();
    }
  }, [open]);

  const loadCommunes = async () => {
    try {
      const data = await getCommuneList();
      setCommunes(data.results || data);
    } catch (error) {
      console.error(error);
    }
  };

  const handleChange = (e) => {
    setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleNext = () => {
    if (!formData.prenom || !formData.nom || !formData.date_naissance || !formData.sexe) {
      toast({ title: "Erreur", description: "Veuillez remplir les champs obligatoires (*)", variant: "destructive" });
      return;
    }
    setStep(2);
  };

  const handleSubmit = async () => {
    if (!formData.telephone || !formData.commune) {
      toast({ title: "Erreur", description: "Le téléphone et la commune sont obligatoires.", variant: "destructive" });
      return;
    }
    
    setLoading(true);
    try {
      const payload = { ...formData };
      Object.keys(payload).forEach(key => {
        if (payload[key] === '' || payload[key] === null) {
          delete payload[key];
        }
      });
      
      const res = await createCitoyen(payload);
      toast({
        title: "Succès",
        description: "Citoyen enregistré avec succès",
        className: "bg-emerald-50 text-emerald-900 border-emerald-200"
      });
      onSuccess(res);
      onOpenChange(false);
    } catch (error) {
      let errorMessage = "Une erreur est survenue lors de l'enregistrement";
      if (error.response?.data) {
        const data = error.response.data;
        if (data.errors && typeof data.errors === 'object') {
          const firstKey = Object.keys(data.errors)[0];
          if (firstKey) {
            errorMessage = `${firstKey}: ${Array.isArray(data.errors[firstKey]) ? data.errors[firstKey][0] : data.errors[firstKey]}`;
          }
        } else if (data.message && data.message !== "Requête invalide.") {
          errorMessage = data.message;
        } else if (data.detail) {
          errorMessage = data.detail;
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

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl bg-layer-1 border-border-strong p-0 overflow-hidden">
        <DialogHeader className="p-6 border-b border-border-subtle bg-layer-2">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center">
              <Users className="h-5 w-5 text-primary" />
            </div>
            <div>
              <DialogTitle className="text-xl font-bold text-text-100 font-jakarta">Nouveau Citoyen</DialogTitle>
              <p className="text-sm text-text-400 mt-1">Étape {step} sur 2 : {step === 1 ? 'Identité' : 'Contact & Documents'}</p>
            </div>
          </div>
          
          {/* Progress Bar */}
          <div className="w-full h-1.5 bg-layer-3 rounded-full mt-4 overflow-hidden">
            <div 
              className="h-full bg-primary transition-all duration-300 ease-in-out" 
              style={{ width: step === 1 ? '50%' : '100%' }}
            />
          </div>
        </DialogHeader>

        <div className="p-6">
          {step === 1 ? (
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Prénom *</label>
                <input
                  type="text"
                  name="prenom"
                  value={formData.prenom}
                  onChange={handleChange}
                  className="w-full p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                  placeholder="Ex: Amadou"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Nom *</label>
                <input
                  type="text"
                  name="nom"
                  value={formData.nom}
                  onChange={handleChange}
                  className="w-full p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                  placeholder="Ex: Ndiaye"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Date de naissance *</label>
                <input
                  type="date"
                  name="date_naissance"
                  value={formData.date_naissance}
                  onChange={handleChange}
                  className="w-full p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Lieu de naissance</label>
                <input
                  type="text"
                  name="lieu_naissance"
                  value={formData.lieu_naissance}
                  onChange={handleChange}
                  className="w-full p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                  placeholder="Ex: Dakar"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Sexe *</label>
                <div className="flex gap-4 mt-2">
                  <label className="flex items-center gap-2 cursor-pointer text-text-200">
                    <input type="radio" name="sexe" value="M" checked={formData.sexe === 'M'} onChange={handleChange} className="text-primary focus:ring-primary accent-primary" />
                    Masculin
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer text-text-200">
                    <input type="radio" name="sexe" value="F" checked={formData.sexe === 'F'} onChange={handleChange} className="text-primary focus:ring-primary accent-primary" />
                    Féminin
                  </label>
                </div>
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Nationalité</label>
                <input
                  type="text"
                  name="nationalite"
                  value={formData.nationalite}
                  onChange={handleChange}
                  className="w-full p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                />
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Téléphone *</label>
                <input
                  type="text"
                  name="telephone"
                  value={formData.telephone}
                  onChange={handleChange}
                  className="w-full p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                  placeholder="+221"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Commune *</label>
                <select
                  name="commune"
                  value={formData.commune}
                  onChange={handleChange}
                  className="w-full p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                >
                  <option value="">Sélectionner une commune</option>
                  {communes.map(c => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>
              <div className="space-y-2 col-span-2">
                <label className="text-sm font-medium text-text-200">Adresse / Quartier</label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    name="adresse"
                    value={formData.adresse}
                    onChange={handleChange}
                    className="flex-1 p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                    placeholder="Adresse complète"
                  />
                  <input
                    type="text"
                    name="quartier"
                    value={formData.quartier}
                    onChange={handleChange}
                    className="w-1/3 p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                    placeholder="Quartier"
                  />
                </div>
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Email</label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  className="w-full p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                  placeholder="Optionnel"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Numéro CNI</label>
                <input
                  type="text"
                  name="numero_cni"
                  value={formData.numero_cni}
                  onChange={handleChange}
                  className="w-full p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 font-mono focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                  placeholder="XXXXXXXXXXXXX"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Date expiration CNI</label>
                <input
                  type="date"
                  name="date_expiration_cni"
                  value={formData.date_expiration_cni}
                  onChange={handleChange}
                  className="w-full p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-200">Passeport</label>
                <input
                  type="text"
                  name="numero_passeport"
                  value={formData.numero_passeport}
                  onChange={handleChange}
                  className="w-full p-2 bg-layer-3 border border-border-strong rounded-lg text-text-100 font-mono focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
                  placeholder="Numéro de passeport"
                />
              </div>
            </div>
          )}
        </div>

        <div className="p-4 border-t border-border-subtle bg-layer-2 flex justify-between">
          {step === 1 ? (
            <Button variant="ghost" onClick={() => onOpenChange(false)}>
              Annuler
            </Button>
          ) : (
            <Button variant="outline" onClick={() => setStep(1)} className="gap-2">
              <ArrowLeft className="h-4 w-4" /> Précédent
            </Button>
          )}

          {step === 1 ? (
            <Button onClick={handleNext} className="bg-primary text-white hover:bg-primary-hover gap-2">
              Suivant <ArrowRight className="h-4 w-4" />
            </Button>
          ) : (
            <Button onClick={handleSubmit} disabled={loading} className="bg-emerald-600 text-white hover:bg-emerald-700 gap-2">
              {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
              Enregistrer le citoyen
            </Button>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
