// src/components/layout/ProfileDropdown.jsx
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Settings, Bell, LogOut } from 'lucide-react';

export function ProfileDropdown({ unreadCount }) {
  const { user, role, logout } = useAuth();
  const navigate = useNavigate();

  const getRoleLabel = (r) => {
    const labels = {
      super_admin: 'Super Administrateur',
      civil_admin: 'Administrateur Civil',
      agent: 'Agent',
    };
    return labels[r] || r;
  };

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button className="hidden sm:flex items-center gap-3 pl-4 border-l border-border-strong hover:bg-layer-2 transition-colors py-1 px-2 rounded-lg focus:outline-none">
          <div className="text-right">
            <p className="text-sm font-medium text-text-100">
              {user?.full_name || 'Utilisateur'}
            </p>
            <p className="text-xs text-text-400">
              {getRoleLabel(role)}
            </p>
          </div>
          <div className="w-9 h-9 rounded-full bg-amber-dim border-[1.5px] border-amber flex items-center justify-center shadow-md overflow-hidden">
            {user?.avatar ? (
              <img src={user.avatar} alt="Avatar" className="w-full h-full object-cover" />
            ) : (
              <span className="text-amber font-semibold text-sm">
                {user?.full_name?.charAt(0) || 'U'}
              </span>
            )}
          </div>
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <DropdownMenuLabel>Mon Compte</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem onClick={() => navigate('/settings')} className="cursor-pointer">
          <Settings className="mr-2 h-4 w-4" />
          Paramètres
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => navigate('/notifications')} className="cursor-pointer justify-between">
          <div className="flex items-center">
            <Bell className="mr-2 h-4 w-4" />
            Notifications
          </div>
          {unreadCount > 0 && (
            <span className="flex h-5 w-5 items-center justify-center rounded-full bg-error text-[10px] font-bold text-white">
              {unreadCount}
            </span>
          )}
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem onClick={handleLogout} className="cursor-pointer text-[#EF4444] focus:bg-[#EF4444]/10 focus:text-[#EF4444]">
          <LogOut className="mr-2 h-4 w-4" />
          Déconnexion
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
