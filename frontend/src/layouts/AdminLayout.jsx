// src/layouts/AdminLayout.jsx
import { useState, useEffect } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { ShieldAlert, WifiOff } from 'lucide-react';
import { getNotifications } from '@/api/notifications';
import { useOnboarding } from '@/hooks/useOnboarding';

import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';

import AdminAssistantFAB from '@/components/ai/AdminAssistantFAB';

export function AdminLayout() {
  const { role } = useAuth();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useOnboarding();

  const fetchNotifs = async () => {
    try {
      const data = await getNotifications();
      const results = data.results || data;
      const count = results.filter((n) => !n.is_read).length;
      setUnreadCount(count);
    } catch (err) {
      console.error("Erreur chargement notifications (AdminLayout):", err);
    }
  };

  useEffect(() => {
    fetchNotifs();
    const interval = setInterval(fetchNotifs, 120000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return (
    <div className="h-screen bg-layer-0 flex overflow-hidden">
      <Sidebar open={sidebarOpen} setOpen={setSidebarOpen} unreadCount={unreadCount} />

      {/* Main content */}
      <div className="flex-1 flex flex-col h-full overflow-hidden lg:pl-[260px]">
        <Header setSidebarOpen={setSidebarOpen} unreadCount={unreadCount} />

        {/* Page content */}
        <main className="flex-1 min-h-0 overflow-y-auto overflow-x-hidden p-6 relative">
          {!isOnline && (
            <div className="mb-4 flex items-center gap-3 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-sm text-red-700 dark:text-red-400 animate-enter">
              <WifiOff className="h-4 w-4 flex-shrink-0" />
              <span>Connexion perdue — vos modifications ne sont pas sauvegardées.</span>
            </div>
          )}
          <Outlet context={{ refreshNotifications: fetchNotifs }} />
        </main>
      </div>
      
      {/* Assistant IA Administrateur */}
      {(location.pathname === '/dashboard' || location.pathname.startsWith('/dossiers')) && (
        <AdminAssistantFAB />
      )}
    </div>
  );
}
