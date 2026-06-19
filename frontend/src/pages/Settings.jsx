// src/pages/Settings.jsx
import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { toast } from '@/components/ui/use-toast';
import { Shield, User, Building2, Moon, Sun, KeyRound, Save, Loader2 } from 'lucide-react';

import AvatarUpload from '@/components/settings/AvatarUpload';
import FormulaireProfilEdit from '@/components/settings/FormulaireProfilEdit';
import IndicateurForceMotDePasse from '@/components/settings/IndicateurForceMotDePasse';
import SessionsActives from '@/components/settings/SessionsActives';

export default function Settings() {
  const { user, role } = useAuth();
  const [theme, setTheme] = useState(() => localStorage.getItem('theme') || 'light');
  const [lang, setLang] = useState('fr');
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isSavingPref, setIsSavingPref] = useState(false);
  const [isSavingPass, setIsSavingPass] = useState(false);

  // Synchroniser le thème avec la bascule globale
  useEffect(() => {
    const handleThemeChange = () => {
      setTheme(localStorage.getItem('theme') || 'light');
    };
    window.addEventListener('theme-change', handleThemeChange);
    return () => window.removeEventListener('theme-change', handleThemeChange);
  }, []);

  const getRoleLabel = (r) => {
    const labels = {
      super_admin: 'Super Administrateur',
      civil_admin: 'Administrateur Civil',
      agent: 'Agent de saisie',
    };
    return labels[r] || r;
  };

  const handleSavePreferences = async (e) => {
    e.preventDefault();
    setIsSavingPref(true);

    // Enregistrer localement et appliquer la classe
    localStorage.setItem('theme', theme);
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    window.dispatchEvent(new Event('theme-change'));

    setTimeout(() => {
      setIsSavingPref(false);
      toast({
        title: 'Préférences enregistrées',
        description: `Vos préférences d'affichage (${theme === 'dark' ? 'Mode Sombre' : 'Mode Clair'}) ont été mises à jour.`,
        variant: 'success',
      });
    }, 800);
  };

  const handleUpdatePassword = async (e) => {
    e.preventDefault();
    if (!currentPassword || !newPassword || !confirmPassword) {
      toast({
        title: 'Erreur',
        description: 'Veuillez remplir tous les champs de mot de passe.',
        variant: 'destructive',
      });
      return;
    }
    if (newPassword !== confirmPassword) {
      toast({
        title: 'Erreur',
        description: 'Les nouveaux mots de passe ne correspondent pas.',
        variant: 'destructive',
      });
      return;
    }
    if (newPassword.length < 8) {
      toast({
        title: 'Erreur',
        description: 'Le nouveau mot de passe doit faire au moins 8 caractères.',
        variant: 'destructive',
      });
      return;
    }

    setIsSavingPass(true);
    // Simulation API
    setTimeout(() => {
      setIsSavingPass(false);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
      toast({
        title: 'Mot de passe modifié',
        description: 'Votre mot de passe a été modifié avec succès.',
        variant: 'success',
      });
    }, 1200);
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-secondary">Paramètres</h1>
        <p className="text-sm text-text-400 mt-1">
          Gérez votre profil, vos préférences et la sécurité de votre compte
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Colonne 1 : Infos Profil */}
        <div className="lg:col-span-1 space-y-6">
          <Card className="border-border-subtle shadow-sm overflow-hidden">
            <CardHeader className="gradient-primary text-white pb-6">
              <div className="flex items-center gap-4">
                <AvatarUpload user={user} />
                <div className="flex-1">
                  <CardTitle className="text-lg font-bold">{user?.full_name || 'Utilisateur'}</CardTitle>
                  <CardDescription className="text-white/80 text-xs mt-1">
                    {getRoleLabel(role)}
                  </CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="pt-6 space-y-4">
              <div className="space-y-1">
                <span className="text-xs text-text-400 font-medium uppercase tracking-wider">Adresse email</span>
                <p className="text-sm font-semibold text-secondary flex items-center gap-2">
                  <User className="h-4 w-4 text-text-400" />
                  {user?.email || '—'}
                </p>
              </div>

              {user?.commune && (
                <div className="space-y-1 pt-2 border-t border-border-subtle">
                  <span className="text-xs text-text-400 font-medium uppercase tracking-wider">Commune assignée</span>
                  <p className="text-sm font-semibold text-secondary flex items-center gap-2">
                    <Building2 className="h-4 w-4 text-text-400" />
                    {user.commune.name || 'Dakar Plateau'}
                  </p>
                </div>
              )}

              <div className="space-y-1 pt-2 border-t border-border-subtle">
                <span className="text-xs text-text-400 font-medium uppercase tracking-wider">Statut du compte</span>
                <p className="text-sm font-semibold text-success flex items-center gap-2">
                  <Shield className="h-4 w-4 text-success" />
                  Actif & Vérifié
                </p>
              </div>

              <FormulaireProfilEdit user={user} onProfileUpdated={() => window.location.reload()} />
            </CardContent>
          </Card>
        </div>

        {/* Colonne 2 & 3 : Formulaires de configuration */}
        <div className="lg:col-span-2 space-y-6">
          {/* Préférences générales */}
          <Card className="border-border-subtle shadow-sm">
            <CardHeader>
              <CardTitle className="text-lg font-semibold text-secondary flex items-center gap-2">
                <Moon className="h-5 w-5 text-primary" />
                Préférences d'affichage
              </CardTitle>
              <CardDescription>
                Personnalisez votre interface et la langue d'utilisation
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSavePreferences} className="space-y-5">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="theme">Thème de l'interface</Label>
                    <Select value={theme} onValueChange={setTheme}>
                      <SelectTrigger id="theme">
                        <SelectValue placeholder="Sélectionner" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="light">
                          <span className="flex items-center gap-2">
                            <Sun className="h-4 w-4 text-amber-500" />
                            Clair (Sénégal Acte)
                          </span>
                        </SelectItem>
                        <SelectItem value="dark">
                          <span className="flex items-center gap-2">
                            <Moon className="h-4 w-4 text-indigo-500" />
                            Sombre (Premium Dark)
                          </span>
                        </SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="lang">Langue par défaut</Label>
                    <Select value={lang} onValueChange={setLang}>
                      <SelectTrigger id="lang">
                        <SelectValue placeholder="Sélectionner" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="fr">Français</SelectItem>
                        <SelectItem value="wo">Wolof</SelectItem>
                        <SelectItem value="en">English</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="flex justify-end pt-2">
                  <Button type="submit" disabled={isSavingPref} style={{ backgroundColor: '#1D4ED8' }} className="gap-2 text-white hover:bg-blue-800">
                    <Save className="h-4 w-4" />
                    Enregistrer les préférences
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>

          {/* Mot de passe & Sécurité */}
          <Card className="border-border-subtle shadow-sm">
            <CardHeader>
              <CardTitle className="text-lg font-semibold text-secondary flex items-center gap-2">
                <KeyRound className="h-5 w-5 text-primary" />
                Sécurité du compte
              </CardTitle>
              <CardDescription>
                Mettez à jour votre mot de passe pour sécuriser vos accès administratifs
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleUpdatePassword} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="current-pass">Mot de passe actuel</Label>
                  <Input
                    id="current-pass"
                    type="password"
                    placeholder="••••••••"
                    value={currentPassword}
                    onChange={(e) => setCurrentPassword(e.target.value)}
                  />
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="new-pass">Nouveau mot de passe</Label>
                    <Input
                      id="new-pass"
                      type="password"
                      placeholder="••••••••"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                    />
                    <IndicateurForceMotDePasse password={newPassword} />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="confirm-pass">Confirmer le nouveau mot de passe</Label>
                    <Input
                      id="confirm-pass"
                      type="password"
                      placeholder="••••••••"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                    />
                    {confirmPassword && newPassword !== confirmPassword && (
                      <p className="text-xs text-[#EF4444] mt-1">Les mots de passe ne correspondent pas.</p>
                    )}
                  </div>
                </div>

                <div className="flex justify-end pt-2">
                  <Button 
                    type="submit" 
                    disabled={isSavingPass || (newPassword !== confirmPassword) || newPassword.length < 8} 
                    style={{ backgroundColor: '#1D4ED8' }} 
                    className="gap-2 text-white hover:bg-blue-800"
                  >
                    {isSavingPass && <Loader2 className="h-4 w-4 animate-spin" />}
                    Modifier le mot de passe
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>

          {/* Sessions Actives */}
          <SessionsActives />
        </div>
      </div>
    </div>
  );
}
