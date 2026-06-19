// src/pages/Login.jsx
import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { toast } from '@/components/ui/use-toast';
import { Eye, EyeOff, Loader2, AlertCircle, ChevronLeft, Check, X } from 'lucide-react';
import logo from '@/assets/logo.jpg';
import axiosClient from '@/api/axiosClient';

const MAX_ATTEMPTS = 5;
const LOCKOUT_SECONDS = 30;

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [failedAttempts, setFailedAttempts] = useState(0);
  const [lockoutTimer, setLockoutTimer] = useState(0);
  
  const { login, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  // Forgot password stepper states
  const [viewMode, setViewMode] = useState('login'); // 'login' | 'email' | 'otp' | 'reset'
  const [resetEmail, setResetEmail] = useState('');
  const [otpValues, setOtpValues] = useState(['', '', '', '', '', '']);
  const [resetToken, setResetToken] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showNewPassword, setShowNewPassword] = useState(false);
  
  // Timers
  const [otpExpiry, setOtpExpiry] = useState(600); // 10 minutes (600s)
  const [resendCooldown, setResendCooldown] = useState(0); // 60s

  // Si déjà authentifié, redirect direct
  useEffect(() => {
    if (isAuthenticated) {
      navigate('/dashboard', { replace: true });
    }
  }, [isAuthenticated, navigate]);

  // Lockout countdown
  useEffect(() => {
    if (lockoutTimer <= 0) return;
    const interval = setInterval(() => {
      setLockoutTimer((prev) => {
        if (prev <= 1) {
          clearInterval(interval);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [lockoutTimer]);

  // OTP Expiry Countdown
  useEffect(() => {
    if (viewMode !== 'otp' || otpExpiry <= 0) return;
    const interval = setInterval(() => {
      setOtpExpiry((prev) => prev - 1);
    }, 1000);
    return () => clearInterval(interval);
  }, [viewMode, otpExpiry]);

  // Resend Cooldown Countdown
  useEffect(() => {
    if (resendCooldown <= 0) return;
    const interval = setInterval(() => {
      setResendCooldown((prev) => prev - 1);
    }, 1000);
    return () => clearInterval(interval);
  }, [resendCooldown]);

  const isLocked = lockoutTimer > 0;

  // Soumission login
  const handleSubmit = useCallback(async (e) => {
    e.preventDefault();
    setError(null);

    if (!email || !password) {
      setError('Veuillez remplir tous les champs.');
      return;
    }

    if (isLocked) return;

    setIsLoading(true);

    try {
      await login(email, password);
      toast({
        title: 'Connexion réussie',
        description: 'Bienvenue sur Teranga Civil.',
        variant: 'success',
      });
      navigate('/dashboard', { replace: true });
    } catch (err) {
      const newAttempts = failedAttempts + 1;
      setFailedAttempts(newAttempts);

      if (newAttempts >= MAX_ATTEMPTS) {
        setLockoutTimer(LOCKOUT_SECONDS);
        setFailedAttempts(0);
        setError(`Trop de tentatives. Réessayez dans ${LOCKOUT_SECONDS}s.`);
      } else {
        const message =
          err.response?.status === 401
            ? 'Identifiants incorrects. Vérifiez votre email et mot de passe.'
            : err.response?.data?.detail || 'Erreur de connexion. Veuillez réessayer.';
        setError(message);
      }
    } finally {
      setIsLoading(false);
    }
  }, [email, password, isLocked, failedAttempts, login, navigate]);

  // OTP 1: Demander OTP
  const handleRequestOTP = async (e) => {
    e.preventDefault();
    if (!resetEmail) {
      setError('Veuillez saisir votre adresse email.');
      return;
    }
    setError(null);
    setIsLoading(true);

    try {
      await axiosClient.post('/api/v1/auth/super-admin/otp-request', { email: resetEmail });
      setViewMode('otp');
      setOtpExpiry(600);
      setResendCooldown(60);
      setOtpValues(['', '', '', '', '', '']);
      toast({
        title: 'Code OTP envoyé',
        description: 'Un code de vérification a été envoyé sur votre messagerie.',
      });
    } catch (err) {
      setError(err.response?.data?.message || 'Impossible d\'envoyer le code OTP.');
    } finally {
      setIsLoading(false);
    }
  };

  // OTP 2: Renvoyer OTP
  const handleResendOTP = async () => {
    if (resendCooldown > 0) return;
    setError(null);
    setIsLoading(true);

    try {
      await axiosClient.post('/api/v1/auth/super-admin/otp-request', { email: resetEmail });
      setOtpExpiry(600);
      setResendCooldown(60);
      setOtpValues(['', '', '', '', '', '']);
      toast({
        title: 'Code OTP renvoyé',
        description: 'Un nouveau code a été envoyé sur votre messagerie.',
      });
    } catch (err) {
      setError(err.response?.data?.message || 'Erreur de renvoi.');
    } finally {
      setIsLoading(false);
    }
  };

  // OTP 3: Saisie cases OTP
  const handleOtpChange = (index, value) => {
    if (value && isNaN(Number(value))) return;
    const newOtpValues = [...otpValues];
    newOtpValues[index] = value.slice(-1);
    setOtpValues(newOtpValues);

    // Auto focus next input
    if (value && index < 5) {
      const nextInput = document.getElementById(`otp-${index + 1}`);
      nextInput?.focus();
    }
  };

  const handleOtpKeyDown = (index, e) => {
    if (e.key === 'Backspace' && !otpValues[index] && index > 0) {
      const prevInput = document.getElementById(`otp-${index - 1}`);
      prevInput?.focus();
    }
  };

  const handleVerifyOTP = async (e) => {
    e.preventDefault();
    const otpCode = otpValues.join('');
    if (otpCode.length < 6) {
      setError('Veuillez entrer le code à 6 chiffres.');
      return;
    }
    setError(null);
    setIsLoading(true);

    try {
      const response = await axiosClient.post('/api/v1/auth/super-admin/otp-verify', {
        email: resetEmail,
        code: otpCode
      });
      setResetToken(response.data.reset_token);
      setViewMode('reset');
      setNewPassword('');
      setConfirmPassword('');
      toast({
        title: 'OTP validé',
        description: 'Veuillez saisir votre nouveau mot de passe.',
      });
    } catch (err) {
      setError(err.response?.data?.message || 'Code OTP invalide ou expiré.');
    } finally {
      setIsLoading(false);
    }
  };

  // OTP 4: Modifier mot de passe
  const handleResetPassword = async (e) => {
    e.preventDefault();
    if (newPassword !== confirmPassword) {
      setError('Les mots de passe ne correspondent pas.');
      return;
    }
    
    // validation locale de force
    if (newPassword.length < 12 || !/[A-Z]/.test(newPassword) || !/\d/.test(newPassword) || !/[^a-zA-Z0-9]/.test(newPassword)) {
      setError('Le mot de passe ne respecte pas les critères de sécurité.');
      return;
    }

    setError(null);
    setIsLoading(true);

    try {
      await axiosClient.post('/api/v1/auth/super-admin/reset-password', {
        reset_token: resetToken,
        new_password: newPassword
      });
      toast({
        title: 'Mot de passe mis à jour',
        description: 'Votre mot de passe a été modifié avec succès. Connectez-vous.',
        variant: 'success',
      });
      setViewMode('login');
      setEmail(resetEmail); // prefill login email
    } catch (err) {
      setError(err.response?.data?.message || 'Erreur lors de la modification.');
    } finally {
      setIsLoading(false);
    }
  };

  // Password strength checks
  const pwdChecks = {
    length: newPassword.length >= 12,
    uppercase: /[A-Z]/.test(newPassword),
    number: /\d/.test(newPassword),
    special: /[^a-zA-Z0-9]/.test(newPassword),
  };

  const getStrengthPercent = () => {
    const passed = Object.values(pwdChecks).filter(Boolean).length;
    return passed * 25;
  };

  const getStrengthLabel = () => {
    const passed = Object.values(pwdChecks).filter(Boolean).length;
    if (passed === 0) return 'Très faible';
    if (passed <= 2) return 'Faible';
    if (passed === 3) return 'Moyen';
    return 'Fort';
  };

  const getStrengthColor = () => {
    const passed = Object.values(pwdChecks).filter(Boolean).length;
    if (passed <= 2) return '#EF4444'; // Red
    if (passed === 3) return '#F59E0B'; // Yellow
    return '#10B981'; // Green
  };

  const formatTimer = (sec) => {
    const mins = Math.floor(sec / 60);
    const secs = sec % 60;
    return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
  };

  const inputErrorClass = error && error.includes('Identifiants')
    ? 'border-error ring-1 ring-error-dim'
    : '';

  return (
    <div className="min-h-screen flex items-center justify-center p-4" style={{ backgroundColor: '#F8FAFC' }}>
      <div className="w-full max-w-[480px] relative animate-enter">
        <div 
          className="border"
          style={{ 
            padding: '40px 48px',
            backgroundColor: '#FFFFFF',
            borderRadius: '16px',
            boxShadow: '0 4px 24px rgba(15,23,42,0.08)',
            borderColor: '#E2E8F0'
          }}
        >
          {/* Logo section */}
          <div className="text-center mb-8">
            <div 
              className="inline-flex items-center justify-center mb-4"
              style={{
                backgroundColor: '#FFFFFF',
                borderRadius: '16px',
                boxShadow: '0 4px 12px rgba(15,23,42,0.1)',
                padding: '8px',
                border: '1px solid rgba(15,23,42,0.05)'
              }}
            >
              <img src={logo} alt="Teranga Civil Logo" className="h-20 w-auto object-contain" style={{ borderRadius: '12px' }} />
            </div>
            <h1 
              className="font-display tracking-tight text-2xl"
              style={{
                color: '#0F172A',
                fontWeight: '700'
              }}
            >
              Teranga Civil
            </h1>
            <p 
              className="mt-2 uppercase"
              style={{
                color: '#1D4ED8',
                fontSize: '13px',
                letterSpacing: '0.08em',
                fontWeight: '500'
              }}
            >
              Espace Administration
            </p>
          </div>

          {/* Alert error panel */}
          {error && (
            <div
              className="mb-6 flex items-start gap-3 text-sm animate-enter rounded-md bg-[#EF4444]/10 border-l-4 border-[#EF4444] text-[#EF4444] p-3"
              role="alert"
            >
              <AlertCircle className="h-4 w-4 mt-0.5 flex-shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {viewMode !== 'login' && (() => {
            const STEPS = ['Email', 'Vérification', 'Nouveau mot de passe'];
            const currentStep = viewMode === 'email' ? 0 : viewMode === 'otp' ? 1 : 2;
            return (
              <div className="flex items-center justify-center gap-2 mb-6">
                {STEPS.map((step, i) => (
                  <div key={i} className="flex items-center gap-2">
                    <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold transition-all ${i <= currentStep ? 'bg-[#1D4ED8] text-white' : 'bg-layer-3 text-text-400'}`}>
                      {i < currentStep ? <Check className="h-3 w-3" /> : i + 1}
                    </div>
                    {i < STEPS.length - 1 && (
                      <div className={`h-px w-8 transition-all ${i < currentStep ? 'bg-[#1D4ED8]' : 'bg-border-strong'}`} />
                    )}
                  </div>
                ))}
              </div>
            );
          })()}

          {/* VIEW 1: LOGIN */}
          {viewMode === 'login' && (
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="space-y-2">
                <Label 
                  htmlFor="email" 
                  style={{ color: '#0F172A', fontWeight: '600', fontSize: '13px' }}
                >
                  Adresse email
                </Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="votre.email@teranga.sn"
                  value={email}
                  onChange={(e) => { setEmail(e.target.value); setError(null); }}
                  disabled={isLoading || isLocked}
                  autoComplete="email"
                  className={`h-11 px-4 py-3 bg-[#F1F5F9] border-[#E2E8F0] rounded-[8px] text-[#0F172A] placeholder:text-text-400 focus-visible:border-[#1D4ED8] focus-visible:ring-2 focus-visible:ring-[#1D4ED8]/20 focus-visible:ring-offset-0 ${inputErrorClass}`}
                />
              </div>

              <div className="space-y-2">
                <Label 
                  htmlFor="password" 
                  style={{ color: '#0F172A', fontWeight: '600', fontSize: '13px' }}
                >
                  Mot de passe
                </Label>
                <div className="relative">
                  <Input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => { setPassword(e.target.value); setError(null); }}
                    disabled={isLoading || isLocked}
                    autoComplete="current-password"
                    className={`h-11 px-4 py-3 pr-10 bg-[#F1F5F9] border-[#E2E8F0] rounded-[8px] text-[#0F172A] placeholder:text-text-400 focus-visible:border-[#1D4ED8] focus-visible:ring-2 focus-visible:ring-[#1D4ED8]/20 focus-visible:ring-offset-0 ${inputErrorClass}`}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-text-400 hover:text-text-200 transition-colors focus-visible:outline-2 focus-visible:outline-[#1D4ED8] rounded"
                    tabIndex={-1}
                    aria-label={showPassword ? 'Masquer le mot de passe' : 'Afficher le mot de passe'}
                  >
                    {showPassword ? (
                      <EyeOff className="h-4 w-4" />
                    ) : (
                      <Eye className="h-4 w-4" />
                    )}
                  </button>
                </div>
              </div>

              {/* Forgot password link */}
              <div className="flex justify-end -mt-2">
                <a
                  href="#"
                  onClick={(e) => { e.preventDefault(); setError(null); setViewMode('email'); setResetEmail(email); }}
                  className="text-[13px] font-medium transition-colors focus-visible:outline-2 focus-visible:outline-[#1D4ED8] rounded no-underline hover:underline"
                  style={{ color: '#1D4ED8' }}
                >
                  Mot de passe oublié ?
                </a>
              </div>

              {/* Submit button */}
              <button
                type="submit"
                disabled={isLoading || isLocked}
                className="w-full text-[15px] font-bold transition-all duration-200 focus-visible:outline-2 focus-visible:outline-[#1D4ED8] focus-visible:outline-offset-2 disabled:opacity-50 disabled:cursor-not-allowed hover:-translate-y-[1px] active:translate-y-0 hover:brightness-110 active:brightness-95"
                style={{
                  backgroundColor: '#1D4ED8',
                  color: '#FFFFFF',
                  borderRadius: '10px',
                  height: '52px',
                  boxShadow: '0 4px 12px rgba(29, 78, 216, 0.2)'
                }}
              >
                {isLoading ? (
                  <span className="inline-flex items-center justify-center gap-2">
                    <Loader2 className="h-4 w-4 animate-spin text-[#FFFFFF]" />
                    Connexion...
                  </span>
                ) : (
                  'Se connecter'
                )}
              </button>

              <div className="mt-4 flex items-center justify-center gap-1.5 text-xs text-text-400 font-medium">
                <span className="flex items-center justify-center bg-emerald-100 text-emerald-700 p-0.5 rounded-full">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
                </span>
                Connexion sécurisée SSL — République du Sénégal
              </div>
            </form>
          )}

          {/* VIEW 2: REQUEST OTP (STEP 1) */}
          {viewMode === 'email' && (
            <form onSubmit={handleRequestOTP} className="space-y-6 animate-enter">
              <div className="space-y-2">
                <div className="flex items-center gap-2 text-text-400 hover:text-secondary cursor-pointer" onClick={() => setViewMode('login')}>
                  <ChevronLeft className="h-4 w-4" />
                  <span className="text-xs font-semibold">Retour à la connexion</span>
                </div>
                <h2 className="text-lg font-bold text-secondary mt-2">Mot de passe oublié</h2>
                <p className="text-xs text-text-400">
                  Saisissez votre e-mail de Super Administrateur pour recevoir un code de validation OTP.
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="reset-email" style={{ color: '#0F172A', fontWeight: '600', fontSize: '13px' }}>
                  Adresse email
                </Label>
                <Input
                  id="reset-email"
                  type="email"
                  placeholder="superadmin@teranga.sn"
                  value={resetEmail}
                  onChange={(e) => setResetEmail(e.target.value)}
                  disabled={isLoading}
                  className="h-11 px-4 py-3 bg-[#F1F5F9] border-[#E2E8F0] rounded-[8px] text-[#0F172A]"
                />
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="w-full text-[15px] font-bold transition-all duration-200 focus-visible:outline-2 focus-visible:outline-[#1D4ED8] disabled:opacity-50 hover:-translate-y-[1px] active:translate-y-0"
                style={{
                  backgroundColor: '#1D4ED8',
                  color: '#FFFFFF',
                  borderRadius: '10px',
                  height: '52px',
                }}
              >
                {isLoading ? (
                  <span className="inline-flex items-center justify-center gap-2">
                    <Loader2 className="h-4 w-4 animate-spin text-[#FFFFFF]" />
                    Envoi en cours...
                  </span>
                ) : (
                  'Envoyer le code OTP'
                )}
              </button>
            </form>
          )}

          {/* VIEW 3: OTP VERIFICATION (STEP 2) */}
          {viewMode === 'otp' && (
            <form onSubmit={handleVerifyOTP} className="space-y-6 animate-enter">
              <div className="space-y-2">
                <div className="flex items-center gap-2 text-text-400 hover:text-secondary cursor-pointer" onClick={() => setViewMode('email')}>
                  <ChevronLeft className="h-4 w-4" />
                  <span className="text-xs font-semibold">Changer d'email</span>
                </div>
                <h2 className="text-lg font-bold text-secondary mt-2">Validation de l'identité</h2>
                <p className="text-xs text-text-400">
                  Un code à 6 chiffres a été envoyé à <strong>{resetEmail}</strong>. Saisissez-le ci-dessous.
                </p>
              </div>

              {/* Cases OTP */}
              <div className="flex justify-between gap-2">
                {otpValues.map((val, idx) => (
                  <input
                    key={idx}
                    id={`otp-${idx}`}
                    type="text"
                    maxLength={1}
                    value={val}
                    onChange={(e) => handleOtpChange(idx, e.target.value)}
                    onKeyDown={(e) => handleOtpKeyDown(idx, e)}
                    disabled={isLoading || otpExpiry <= 0}
                    className="w-12 h-14 text-center text-xl font-bold rounded-lg border border-border-strong bg-layer-2 text-secondary focus:border-[#1D4ED8] focus:ring-2 focus:ring-[#1D4ED8]/25 outline-none transition-all"
                  />
                ))}
              </div>

              {/* Countdown & Resend link */}
              <div className="flex justify-between items-center text-xs">
                {otpExpiry > 0 ? (
                  <span className="text-text-400 font-medium flex items-center gap-1.5">
                    Le code expire dans <strong className="text-amber font-mono">{formatTimer(otpExpiry)}</strong>
                  </span>
                ) : (
                  <span className="text-[#EF4444] font-semibold">Le code a expiré</span>
                )}

                {resendCooldown > 0 ? (
                  <span className="text-text-400">Renvoyer dans ({resendCooldown}s)</span>
                ) : (
                  <button
                    type="button"
                    onClick={handleResendOTP}
                    className="text-[#1D4ED8] font-bold hover:underline"
                  >
                    Renvoyer le code
                  </button>
                )}
              </div>

              <button
                type="submit"
                disabled={isLoading || otpExpiry <= 0}
                className="w-full text-[15px] font-bold transition-all duration-200 focus-visible:outline-2 focus-visible:outline-[#1D4ED8] disabled:opacity-50 hover:-translate-y-[1px] active:translate-y-0"
                style={{
                  backgroundColor: '#1D4ED8',
                  color: '#FFFFFF',
                  borderRadius: '10px',
                  height: '52px',
                }}
              >
                {isLoading ? (
                  <span className="inline-flex items-center justify-center gap-2">
                    <Loader2 className="h-4 w-4 animate-spin text-[#FFFFFF]" />
                    Validation...
                  </span>
                ) : (
                  'Valider le code OTP'
                )}
              </button>
            </form>
          )}

          {/* VIEW 4: RESET PASSWORD (STEP 3) */}
          {viewMode === 'reset' && (
            <form onSubmit={handleResetPassword} className="space-y-6 animate-enter">
              <div className="space-y-2">
                <h2 className="text-lg font-bold text-secondary">Nouveau mot de passe</h2>
                <p className="text-xs text-text-400">
                  Définissez votre nouveau mot de passe fort pour le compte super administrateur.
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="new-pwd" style={{ color: '#0F172A', fontWeight: '600', fontSize: '13px' }}>
                  Nouveau mot de passe
                </Label>
                <div className="relative">
                  <Input
                    id="new-pwd"
                    type={showNewPassword ? 'text' : 'password'}
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    disabled={isLoading}
                    className="h-11 px-4 py-3 bg-[#F1F5F9] border-[#E2E8F0] rounded-[8px] text-[#0F172A]"
                  />
                  <button
                    type="button"
                    onClick={() => setShowNewPassword(!showNewPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-text-400 hover:text-text-300 transition-colors"
                  >
                    {showNewPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="confirm-pwd" style={{ color: '#0F172A', fontWeight: '600', fontSize: '13px' }}>
                  Confirmer le mot de passe
                </Label>
                <Input
                  id="confirm-pwd"
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  disabled={isLoading}
                  className="h-11 px-4 py-3 bg-[#F1F5F9] border-[#E2E8F0] rounded-[8px] text-[#0F172A]"
                />
              </div>

              {/* Password strength UI */}
              <div className="space-y-3 p-4 bg-layer-2 rounded-xl border border-border-subtle">
                <div className="flex justify-between items-center text-xs">
                  <span className="text-text-400">Force du mot de passe :</span>
                  <span className="font-bold" style={{ color: getStrengthColor() }}>
                    {getStrengthLabel()}
                  </span>
                </div>
                
                {/* ProgressBar */}
                <div className="w-full bg-border-strong h-1.5 rounded-full overflow-hidden">
                  <div 
                    className="h-full transition-all duration-300"
                    style={{ 
                      width: `${getStrengthPercent()}%`,
                      backgroundColor: getStrengthColor() 
                    }}
                  />
                </div>

                {/* Validation checklist */}
                <div className="grid grid-cols-2 gap-2 text-[10px]">
                  <div className="flex items-center gap-1">
                    {pwdChecks.length ? <Check className="h-3 w-3 text-[#10B981]" /> : <X className="h-3 w-3 text-[#EF4444]" />}
                    <span className={pwdChecks.length ? 'text-[#10B981] font-medium' : 'text-[#EF4444]'}>12+ caractères</span>
                  </div>
                  <div className="flex items-center gap-1">
                    {pwdChecks.uppercase ? <Check className="h-3 w-3 text-[#10B981]" /> : <X className="h-3 w-3 text-[#EF4444]" />}
                    <span className={pwdChecks.uppercase ? 'text-[#10B981] font-medium' : 'text-[#EF4444]'}>1 Majuscule</span>
                  </div>
                  <div className="flex items-center gap-1">
                    {pwdChecks.number ? <Check className="h-3 w-3 text-[#10B981]" /> : <X className="h-3 w-3 text-[#EF4444]" />}
                    <span className={pwdChecks.number ? 'text-[#10B981] font-medium' : 'text-[#EF4444]'}>1 Chiffre</span>
                  </div>
                  <div className="flex items-center gap-1">
                    {pwdChecks.special ? <Check className="h-3 w-3 text-[#10B981]" /> : <X className="h-3 w-3 text-[#EF4444]" />}
                    <span className={pwdChecks.special ? 'text-[#10B981] font-medium' : 'text-[#EF4444]'}>1 Car. spécial</span>
                  </div>
                </div>
              </div>

              <button
                type="submit"
                disabled={isLoading || getStrengthPercent() < 100}
                className="w-full text-[15px] font-bold transition-all duration-200 focus-visible:outline-2 focus-visible:outline-[#1D4ED8] disabled:opacity-50 disabled:cursor-not-allowed hover:-translate-y-[1px] active:translate-y-0"
                style={{
                  backgroundColor: '#1D4ED8',
                  color: '#FFFFFF',
                  borderRadius: '10px',
                  height: '52px',
                }}
              >
                {isLoading ? (
                  <span className="inline-flex items-center justify-center gap-2">
                    <Loader2 className="h-4 w-4 animate-spin text-[#FFFFFF]" />
                    Mise à jour...
                  </span>
                ) : (
                  'Mettre à jour le mot de passe'
                )}
              </button>
            </form>
          )}
        </div>

        <p className="text-center text-xs text-text-500 mt-6 font-medium">
          © 2026 Teranga Civil — République du Sénégal
        </p>
      </div>
    </div>
  );
}
