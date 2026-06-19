import { useState, useEffect } from 'react';

export function useTheme() {
  const [isDark, setIsDark] = useState(() => {
    const saved = localStorage.getItem('teranga-theme');
    if (saved) return saved === 'dark';
    // Respect préférence système si première visite
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  });

  useEffect(() => {
    const root = document.documentElement;
    if (isDark) {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
    localStorage.setItem('teranga-theme', isDark ? 'dark' : 'light');
    // Dispatch event pour synchroniser Settings.jsx
    window.dispatchEvent(new Event('theme-change'));
  }, [isDark]);

  const toggle = () => setIsDark(prev => !prev);

  return { isDark, toggle };
}
