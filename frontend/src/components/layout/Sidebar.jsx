// src/components/layout/Sidebar.jsx
import { NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import {
  LayoutDashboard,
  Archive,
  Users,
  Building2,
  ScrollText,
  Bell,
  Settings,
  GitBranch,
  CreditCard,
  X,
  PieChart,
  ShieldAlert,
  FileText,
  Calendar
} from 'lucide-react';
import logo from '@/assets/logo.jpg';

export function Sidebar({ open, setOpen, unreadCount }) {
  const { role } = useAuth();
  const location = useLocation();

  const normalSections = [
    {
      title: 'PRINCIPAL',
      items: [
        { name: 'Tableau de bord', href: '/dashboard', icon: LayoutDashboard },
        { name: 'Banque des Demandes', href: '/dossiers', icon: Archive },
        { name: 'Citoyens', href: '/citoyens', icon: Users },
        { name: 'Rendez-vous', href: '/rendez-vous', icon: Calendar },
      ],
    },
    {
      title: 'GESTION',
      items: [
        { name: 'Agents', href: '/agents', icon: Users, roles: ['civil_admin', 'super_admin', 'civil_admin_supervisor'] },
        { name: 'Dispatching IA', href: '/dispatching', icon: GitBranch, roles: ['civil_admin', 'super_admin', 'civil_admin_supervisor'] },
      ],
    },
    {
      title: 'ADMINISTRATION',
      items: [
        { name: "Journal d'audit", href: '/audit-logs', icon: ScrollText, roles: ['super_admin', 'civil_admin_supervisor'] },
        { name: 'Transactions', href: '/admin/transactions', icon: CreditCard, roles: ['super_admin', 'civil_admin_supervisor'] },
      ],
    },
    {
      title: 'SYSTÈME',
      items: [
        { name: 'Notifications', href: '/notifications', icon: Bell },
        { name: 'Paramètres', href: '/settings', icon: Settings },
      ],
    },
  ];

  const superAdminSections = [
    {
      title: 'VUE NATIONALE',
      items: [
        { name: 'Dashboard Global', href: '/super/overview', icon: LayoutDashboard },
        { name: 'Statistiques & Graphiques', href: '/super/statistics', icon: PieChart },
      ]
    },
    {
      title: 'PERFORMANCES',
      items: [
        { name: 'Classement Communes', href: '/super/performance', icon: Building2 },
      ]
    },
    {
      title: 'CONTRÔLE & AUDIT',
      items: [
        { name: 'Sécurité & Audit', href: '/super/audit', icon: ShieldAlert },
        { name: 'Consultation Dossiers', href: '/dossiers', icon: Archive },
        { name: 'Paramètres', href: '/super/parametres', icon: Settings },
      ]
    }
  ];

  const sections = role === 'super_admin' ? superAdminSections : normalSections;

  return (
    <>
      {/* Overlay mobile */}
      {open && (
        <div
          className="fixed inset-0 bg-black/50 z-40 lg:hidden backdrop-blur-sm"
          onClick={() => setOpen(false)}
        />
      )}

      <aside
        className={`fixed inset-y-0 left-0 z-50 w-[260px] flex flex-col transition-transform duration-300 ease-in-out lg:translate-x-0 ${
          open ? 'translate-x-0' : '-translate-x-full'
        }`}
        style={{
          backgroundImage:
            'linear-gradient(180deg, #0D1F3C 0%, #080E1A 100%), url("data:image/svg+xml,%3Csvg viewBox=%220 0 200 200%22 xmlns=%22http://www.w3.org/2000/svg%22%3E%3Cfilter id=%22noiseFilter%22%3E%3CfeTurbulence type=%22fractalNoise%22 baseFrequency=%220.65%22 numOctaves=%223%22 stitchTiles=%22stitch%22/%3E%3C/filter%3E%3Crect width=%22100%25%22 height=%22100%25%22 filter=%22url(%23noiseFilter)%22 opacity=%220.05%22/%3E%3C/svg%3E")',
          borderRight: '1px solid var(--border-subtle)',
        }}
      >
        {/* Logo */}
        <div className="flex items-center justify-between h-16 px-6 border-b border-white/10 shrink-0">
          <div className="flex items-center gap-3">
            <img src={logo} alt="TC Logo" className="w-9 h-9 rounded-lg object-contain bg-layer-0 shadow-lg" />
            <div>
              <h1 className="text-[#F0F4FF] font-bold text-lg tracking-tight leading-none">TERANGA</h1>
              <span className="text-amber/80 text-[10px] font-semibold tracking-[0.2em] uppercase">Civil</span>
            </div>
          </div>
          <button
            onClick={() => setOpen(false)}
            className="lg:hidden text-[#8B9FC2] hover:text-[#F0F4FF] transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-3 py-4 overflow-y-auto" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {sections.map((section, idx) => {
            const visibleItems = section.items.filter((item) => !item.roles || item.roles.includes(role));
            if (visibleItems.length === 0) return null;

            return (
              <div key={idx} className="flex flex-col gap-1">
                <h3
                  className="px-3 mb-1 text-[11px] font-semibold text-[#8B9FC2] uppercase tracking-[0.05em]"
                >
                  {section.title}
                </h3>
                {visibleItems.map((item) => {
                  const isActive =
                    location.pathname === item.href ||
                    (item.href !== '/dashboard' && location.pathname.startsWith(item.href));

                  return (
                    <NavLink
                      key={item.name}
                      to={item.href}
                      onClick={() => setOpen(false)}
                      className={`sidebar-link relative flex items-center gap-3 ${isActive ? 'active' : ''}`}
                    >
                      <item.icon className="h-5 w-5 flex-shrink-0" aria-hidden="true" />
                      <span className="flex-1 whitespace-nowrap overflow-hidden text-ellipsis text-[0.875rem]">{item.name}</span>
                      {item.href === '/notifications' && unreadCount > 0 && (
                        <span
                          className="absolute right-3 top-1/2 -translate-y-1/2 min-w-[20px] h-5 flex items-center justify-center rounded-full bg-error text-[#F0F4FF] text-[11px] font-bold px-1.5 shadow-[0_0_8px_rgba(248,113,113,0.5)] animate-pulse"
                        >
                          {unreadCount}
                        </span>
                      )}
                    </NavLink>
                  );
                })}
              </div>
            );
          })}
        </nav>
      </aside>
    </>
  );
}
