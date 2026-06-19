import React from 'react';

export default function IndicateurForceMotDePasse({ password }) {
  if (!password) return null;

  let strength = 'Faible';
  let color = '#EF4444'; // rouge
  let width = '33%';

  const hasLength = password.length >= 8;
  const hasUpperCase = /[A-Z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecial = /[^A-Za-z0-9]/.test(password);

  if (hasLength) {
    if (hasUpperCase && hasNumber && hasSpecial) {
      strength = 'Fort';
      color = '#10B981'; // vert
      width = '100%';
    } else {
      strength = 'Moyen';
      color = '#F59E0B'; // orange
      width = '66%';
    }
  }

  return (
    <div className="space-y-1 mt-2">
      <div className="flex justify-between items-center text-xs">
        <span className="text-text-400">Force du mot de passe :</span>
        <span style={{ color }} className="font-semibold">{strength}</span>
      </div>
      <div className="h-1.5 w-full bg-layer-3 rounded-full overflow-hidden">
        <div 
          className="h-full transition-all duration-300"
          style={{ width, backgroundColor: color }}
        />
      </div>
      <p className="text-[10px] text-text-400">
        Minimum 8 caractères, une majuscule, un chiffre
      </p>
    </div>
  );
}
