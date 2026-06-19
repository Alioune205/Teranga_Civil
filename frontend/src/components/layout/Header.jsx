// src/components/layout/Header.jsx
import { NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { useTheme } from '@/hooks/useTheme';
import { Menu, Sun, Moon, Bell } from 'lucide-react';
import { ProfileDropdown } from './ProfileDropdown';

export function Header({ setSidebarOpen, unreadCount }) {
  const { role } = useAuth();
  const { isDark, toggle } = useTheme();
  const location = useLocation();

  const getCurrentPageTitle = () => {
    const path = location.pathname;
    if (path.startsWith('/dashboard')) return 'Tableau de bord';
    if (path.startsWith('/dossiers/') && path !== '/dossiers') return 'Détail de la demande';
    if (path.startsWith('/dossiers')) return 'Banque des Demandes';
    if (path.startsWith('/citoyens')) return 'Citoyens';
    if (path.startsWith('/agents')) return 'Agents';
    if (path.startsWith('/communes')) return 'Communes';
    if (path.startsWith('/dispatching')) return 'Dispatching IA';
    if (path.startsWith('/audit-logs')) return "Journal d'audit";
    if (path.startsWith('/admin/transactions')) return 'Transactions';
    if (path.startsWith('/notifications')) return 'Notifications';
    if (path.startsWith('/settings')) return 'Paramètres';
    if (path.startsWith('/rendez-vous')) return 'Rendez-vous';
    return 'Dashboard';
  };

  return (
    <header className="sticky top-0 z-30 h-16 bg-layer-1 border-b border-border-strong flex items-center justify-between px-6 shrink-0" style={{ boxShadow: 'var(--shadow-card)' }}>
      <div className="flex items-center gap-4">
        <button
          onClick={() => setSidebarOpen(true)}
          className="lg:hidden p-2 rounded-lg text-text-300 hover:bg-layer-2 transition-colors"
        >
          <Menu className="h-5 w-5" />
        </button>

        <div>
          <h2 className="text-lg font-semibold text-text-100">
            {getCurrentPageTitle()}
          </h2>
        </div>
      </div>

      <div className="flex items-center gap-3">
        <button
          onClick={toggle}
          className="theme-toggle"
          aria-label={isDark ? 'Passer en mode clair' : 'Passer en mode sombre'}
          title={isDark ? 'Mode clair' : 'Mode sombre'}
        >
          {isDark ? <Sun className="h-[18px] w-[18px]" /> : <Moon className="h-[18px] w-[18px]" />}
        </button>

        <NavLink
          to="/notifications"
          className="relative p-2 rounded-lg text-text-300 hover:bg-layer-2 hover:text-text-100 transition-colors focus:outline-none"
          title="Notifications"
        >
          <Bell className="h-5 w-5" />
          {unreadCount > 0 && (
            <span className="absolute top-1.5 right-1.5 flex h-2 w-2 rounded-full bg-red-500 ring-2 ring-layer-1" />
          )}
        </NavLink>

        <ProfileDropdown unreadCount={unreadCount} />
      </div>
    </header>
  );
}
