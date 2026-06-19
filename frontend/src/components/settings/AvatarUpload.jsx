import { useState, useRef } from 'react';
import { toast } from '@/components/ui/use-toast';
import { Loader2, Camera } from 'lucide-react';
import axiosClient from '@/api/axiosClient';

export default function AvatarUpload({ user }) {
  const [loading, setLoading] = useState(false);
  const [previewUrl, setPreviewUrl] = useState(user?.avatar || null);
  const fileInputRef = useRef(null);

  const getInitials = () => {
    if (!user) return 'U';
    if (user.first_name && user.last_name) {
      return `${user.first_name.charAt(0)}${user.last_name.charAt(0)}`.toUpperCase();
    }
    return (user.full_name?.substring(0, 2) || user.email?.substring(0, 2) || 'U').toUpperCase();
  };

  const handleFileSelect = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    if (!['image/jpeg', 'image/png'].includes(file.type)) {
      toast({ title: 'Erreur', description: 'Seuls les formats JPEG et PNG sont acceptés.', variant: 'destructive' });
      return;
    }

    if (file.size > 2 * 1024 * 1024) {
      toast({ title: 'Erreur', description: 'La taille de l\'image ne doit pas dépasser 2MB.', variant: 'destructive' });
      return;
    }

    // Afficher aperçu immédiat
    const objectUrl = URL.createObjectURL(file);
    setPreviewUrl(objectUrl);
    setLoading(true);

    try {
      const formData = new FormData();
      formData.append('avatar', file);

      await axiosClient.patch('/api/users/me/', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
      toast({ title: 'Succès', description: 'Votre photo de profil a été mise à jour.', variant: 'success' });
    } catch (error) {
      console.error(error);
      toast({ title: 'Erreur', description: 'Échec de la mise à jour de la photo de profil.', variant: 'destructive' });
      // Revenir à l'ancienne image
      setPreviewUrl(user?.avatar || null);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col items-center space-y-3">
      <div 
        className="relative w-24 h-24 rounded-full flex items-center justify-center border-4 border-white shadow-lg overflow-hidden"
        style={{ backgroundColor: previewUrl ? 'transparent' : '#1D4ED8' }}
      >
        {previewUrl ? (
          <img src={previewUrl} alt="Avatar" className="w-full h-full object-cover" />
        ) : (
          <span className="text-white font-bold text-3xl">
            {getInitials()}
          </span>
        )}
        {loading && (
          <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
            <Loader2 className="h-6 w-6 text-white animate-spin" />
          </div>
        )}
      </div>

      <input 
        type="file" 
        accept="image/jpeg, image/png"
        className="hidden" 
        ref={fileInputRef}
        onChange={handleFileSelect}
      />
      
      <button 
        onClick={() => fileInputRef.current?.click()}
        disabled={loading}
        className="text-xs text-text-400 hover:text-[#1D4ED8] flex items-center gap-1 transition-colors bg-layer-3 hover:bg-blue-50 px-3 py-1.5 rounded-full"
      >
        <Camera className="h-3.5 w-3.5" />
        Changer la photo
      </button>
    </div>
  );
}
