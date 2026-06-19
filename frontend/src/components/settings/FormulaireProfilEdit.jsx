import { useState, useEffect } from 'react';
import { toast } from '@/components/ui/use-toast';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Loader2 } from 'lucide-react';
import axiosClient from '@/api/axiosClient';
import { getCommuneList } from '@/api/communes';

export default function FormulaireProfilEdit({ user, onProfileUpdated }) {
  const [loading, setLoading] = useState(false);
  const [communes, setCommunes] = useState([]);
  const [formData, setFormData] = useState({
    first_name: user?.first_name || '',
    last_name: user?.last_name || '',
    phone: user?.phone || '',
    commune: (user?.commune && typeof user.commune === 'object') ? String(user.commune.id) : (user?.commune ? String(user.commune) : '')
  });

  useEffect(() => {
    getCommuneList()
      .then((res) => setCommunes(Array.isArray(res) ? res : res.results || []))
      .catch((err) => console.error('Error loading communes:', err));
  }, []);

  const handleChange = (field, value) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const getRoleLabel = (r) => {
    const labels = {
      super_admin: 'Super Administrateur',
      civil_admin: 'Administrateur Civil',
      agent: 'Agent de saisie',
    };
    return labels[r] || r || 'Utilisateur';
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.first_name || !formData.last_name) {
      toast({ title: 'Erreur', description: 'Le prénom et le nom sont obligatoires.', variant: 'destructive' });
      return;
    }

    if (formData.phone && !/^\+221[0-9]{9}$/.test(formData.phone)) {
      toast({ title: 'Erreur', description: 'Le téléphone doit être au format +221XXXXXXXXX.', variant: 'destructive' });
      return;
    }

    setLoading(true);
    try {
      const payload = {
        first_name: formData.first_name,
        last_name: formData.last_name,
        phone: formData.phone,
      };
      if (formData.commune) {
        payload.commune_id = formData.commune; // Or depending on API, maybe commune: formData.commune
      }

      await axiosClient.patch('/api/users/me/', payload);
      toast({ title: 'Succès', description: 'Votre profil a été mis à jour.', variant: 'success' });
      if (onProfileUpdated) onProfileUpdated();
    } catch (error) {
      console.error(error);
      toast({ title: 'Erreur', description: 'Échec de la mise à jour du profil.', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4 pt-4 border-t border-border-subtle mt-4">
      <div className="space-y-2">
        <Label htmlFor="first_name">Prénom <span className="text-[#EF4444]">*</span></Label>
        <Input 
          id="first_name" 
          value={formData.first_name} 
          onChange={(e) => handleChange('first_name', e.target.value)} 
          required 
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="last_name">Nom <span className="text-[#EF4444]">*</span></Label>
        <Input 
          id="last_name" 
          value={formData.last_name} 
          onChange={(e) => handleChange('last_name', e.target.value)} 
          required 
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="phone">Téléphone</Label>
        <Input 
          id="phone" 
          placeholder="+221770000000" 
          value={formData.phone} 
          onChange={(e) => handleChange('phone', e.target.value)} 
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="commune">Commune rattachée</Label>
        <Select disabled value={formData.commune} onValueChange={(val) => handleChange('commune', val)}>
          <SelectTrigger id="commune" className="bg-layer-2 cursor-not-allowed text-text-400">
            <SelectValue placeholder="Sélectionner une commune" />
          </SelectTrigger>
          <SelectContent>
            {communes.map((c) => (
              <SelectItem key={c.id} value={String(c.id)}>{c.name}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="space-y-2">
        <Label htmlFor="role">Rôle</Label>
        <Input 
          id="role" 
          value={getRoleLabel(user?.role)} 
          disabled 
          className="bg-layer-2 cursor-not-allowed text-text-400" 
        />
      </div>

      <Button 
        type="submit" 
        disabled={loading} 
        style={{ backgroundColor: '#1D4ED8' }} 
        className="w-full text-white hover:bg-blue-800"
      >
        {loading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
        Mettre à jour le profil
      </Button>
    </form>
  );
}
