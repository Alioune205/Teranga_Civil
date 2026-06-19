// src/pages/Notifications.jsx
import { useState, useEffect, useMemo } from 'react';
import { useNavigate, useOutletContext } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Bell, CheckCheck, ExternalLink, Clock } from 'lucide-react';
import { toast } from '@/components/ui/use-toast';

import { getNotifications, markAsRead, markAllAsRead as apiMarkAllAsRead } from '@/api/notifications';

function getTimeAgo(dateStr) {
  const now = new Date();
  const date = new Date(dateStr);
  const diff = now - date;
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (minutes < 1) return "À l'instant";
  if (minutes < 60) return `Il y a ${minutes} min`;
  if (hours < 24) return `Il y a ${hours}h`;
  if (days === 1) return 'Hier';
  if (days < 7) return `Il y a ${days} jours`;
  return date.toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' });
}

function getDateGroup(dateStr) {
  const now = new Date();
  const date = new Date(dateStr);
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const yesterday = new Date(today.getTime() - 86400000);
  const weekStart = new Date(today.getTime() - 7 * 86400000);

  if (date >= today) return "Aujourd'hui";
  if (date >= yesterday) return 'Hier';
  if (date >= weekStart) return 'Cette semaine';
  return 'Plus ancien';
}

export default function Notifications() {
  const navigate = useNavigate();
  const { refreshNotifications } = useOutletContext() || {};
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchNotifs = async () => {
      try {
        const data = await getNotifications({ page_size: 100 });
        setNotifications(data.results || data);
      } catch (err) {
        console.error("Erreur chargement notifications:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchNotifs();
  }, []);

  const unreadCount = notifications.filter((n) => !n.is_read).length;

  // Grouper par date
  const grouped = useMemo(() => {
    const groups = {};
    const order = ["Aujourd'hui", 'Hier', 'Cette semaine', 'Plus ancien'];

    notifications.forEach((notif) => {
      const group = getDateGroup(notif.created_at);
      if (!groups[group]) groups[group] = [];
      groups[group].push(notif);
    });

    // Trier chaque groupe par date décroissante
    Object.keys(groups).forEach((key) => {
      groups[key].sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    });

    return order.filter((g) => groups[g]?.length > 0).map((g) => ({
      label: g,
      items: groups[g],
    }));
  }, [notifications]);

  const markAllAsRead = async () => {
    try {
      await apiMarkAllAsRead();
      setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })));
      refreshNotifications?.();
      toast({
        title: 'Notifications lues',
        description: 'Toutes les notifications ont été marquées comme lues.',
        variant: 'success',
      });
    } catch (err) {
      toast({ title: 'Erreur', description: 'Impossible de marquer comme lu.', variant: 'destructive' });
    }
  };

  const handleClick = async (notif) => {
    if (!notif.is_read) {
      try {
        await markAsRead(notif.id);
        setNotifications((prev) =>
          prev.map((n) => (n.id === notif.id ? { ...n, is_read: true } : n))
        );
        refreshNotifications?.();
      } catch (err) {
        console.error("Erreur mark as read:", err);
      }
    }

    // Naviguer vers le dossier
    if (notif.related_dossier_id) {
      navigate(`/dossiers/${notif.related_dossier_id}`);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-secondary">Notifications</h1>
          <p className="text-sm text-text-400 mt-1">
            {unreadCount > 0
              ? `${unreadCount} notification${unreadCount > 1 ? 's' : ''} non lue${unreadCount > 1 ? 's' : ''}`
              : 'Toutes les notifications sont lues'}
          </p>
        </div>
        {unreadCount > 0 && (
          <Button variant="outline" onClick={markAllAsRead} className="gap-2">
            <CheckCheck className="h-4 w-4" />
            Tout marquer comme lu
          </Button>
        )}
      </div>

      {grouped.length > 0 ? (
        <div className="space-y-6">
          {grouped.map((group) => (
            <div key={group.label}>
              <h3 className="text-sm font-semibold text-text-400 uppercase tracking-wider mb-3">
                {group.label}
              </h3>
              <div className="space-y-2">
                {group.items.map((notif) => (
                  <Card
                    key={notif.id}
                    className={`p-4 border cursor-pointer transition-all duration-200 hover:shadow-md hover:border-primary/20 ${
                      notif.is_read
                        ? 'bg-white border-border-subtle'
                        : 'bg-[#EFF6FF] border-primary/20'
                    }`}
                    onClick={() => handleClick(notif)}
                  >
                    <div className="flex items-start gap-4">
                      <div
                        className={`p-2 rounded-lg flex-shrink-0 ${
                          notif.is_read ? 'bg-layer-3' : 'bg-primary/10'
                        }`}
                      >
                        <Bell
                          className={`h-4 w-4 ${
                            notif.is_read ? 'text-text-400' : 'text-primary'
                          }`}
                        />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <h4
                            className={`text-sm font-medium ${
                              notif.is_read ? 'text-text-300' : 'text-secondary'
                            }`}
                          >
                            {notif.title}
                          </h4>
                          {!notif.is_read && (
                            <div className="w-2 h-2 rounded-full bg-primary flex-shrink-0" />
                          )}
                        </div>
                        <p className="text-sm text-text-400 mt-0.5">{notif.body}</p>
                        <div className="flex items-center gap-2 mt-2">
                          <Clock className="h-3 w-3 text-text-400" />
                          <span className="text-xs text-text-400">
                            {getTimeAgo(notif.created_at)}
                          </span>
                        </div>
                      </div>
                      <ExternalLink className="h-4 w-4 text-slate-300 flex-shrink-0 mt-1" />
                    </div>
                  </Card>
                ))}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <Card className="p-12 text-center border-border-subtle">
          <Bell className="h-12 w-12 text-slate-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-text-400">Aucune notification</h3>
          <p className="text-sm text-text-400 mt-1">
            Vous serez notifié des nouvelles activités ici.
          </p>
        </Card>
      )}
    </div>
  );
}
