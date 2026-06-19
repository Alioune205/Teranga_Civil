// src/App.jsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from '@/context/AuthContext.jsx';
import { PrivateRoute } from '@/components/PrivateRoute.jsx';
import { RoleRoute } from '@/components/RoleRoute.jsx';
import { AdminLayout } from '@/layouts/AdminLayout.jsx';
import { Toaster } from '@/components/ui/toaster.jsx';

// Pages
import Login from '@/pages/Login.jsx';
import Dashboard from '@/pages/Dashboard.jsx';
import DashboardAttribution from '@/pages/DashboardAttribution.jsx';
import CentreSupervision from '@/components/attribution/CentreSupervision.jsx';
import Dossiers from '@/pages/Dossiers.jsx';
import DossierDetail from '@/pages/DossierDetail.jsx';
import CitoyenRepertoire from '@/pages/CitoyenRepertoire.jsx';
import Communes from '@/pages/Communes.jsx';
import Agents from '@/pages/Agents.jsx';
import AuditLogs from '@/pages/AuditLogs.jsx';
import NdiogoyeLogs from '@/pages/NdiogoyeLogs.jsx';
import Notifications from '@/pages/Notifications.jsx';
import Settings from '@/pages/Settings.jsx';
import Transactions from '@/pages/Transactions.jsx';
import Appointments from '@/pages/Appointments.jsx';

import SuperOverview from '@/pages/admin/super/SuperOverview.jsx';
import SuperPerformance from '@/pages/admin/super/SuperPerformance.jsx';
import SuperStatistics from '@/pages/admin/super/SuperStatistics.jsx';
import SuperAuditLog from '@/pages/admin/super/SuperAuditLog.jsx';
import SuperUserManagement from '@/pages/admin/super/SuperUserManagement.jsx';
import SuperSettings from '@/pages/admin/super/SuperSettings.jsx';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Route publique */}
          <Route path="/login" element={<Login />} />

          {/* Redirect racine */}
          <Route path="/" element={<Navigate to="/dashboard" replace />} />

          {/* Routes protégées */}
          <Route element={<PrivateRoute />}>
            <Route element={<AdminLayout />}>
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/attribution" element={<DashboardAttribution />} />
              <Route path="/dossiers" element={<Dossiers />} />
              <Route path="/dossiers/:id" element={<DossierDetail />} />
              <Route path="/citoyens" element={<CitoyenRepertoire />} />
              <Route path="/notifications" element={<Notifications />} />
              <Route path="/settings" element={<Settings />} />
              <Route path="/rendez-vous" element={<Appointments />} />

              {/* Réservé Admin Civil, Super Admin, et Superviseur */}
              <Route element={<RoleRoute allowedRoles={['civil_admin', 'super_admin', 'civil_admin_supervisor']} />}>
                <Route path="/agents" element={<Agents />} />
              </Route>

              <Route element={<RoleRoute allowedRoles={['super_admin', 'civil_admin_supervisor']} />}>
                <Route path="/audit-logs" element={<AuditLogs />} />
              </Route>

              {/* Réservé Super Admin, Superviseur et Administrateur Civil */}
              <Route element={<RoleRoute allowedRoles={['super_admin', 'civil_admin_supervisor', 'civil_admin']} />}>
                <Route path="/dispatching" element={<DashboardAttribution />} />
                <Route path="/supervision-ia" element={<DashboardAttribution />} />
              </Route>

              {/* Réservé Super Admin pur */}
              <Route element={<RoleRoute allowedRoles={['super_admin']} />}>
                <Route path="/super/overview" element={<SuperOverview />} />
                <Route path="/super/performance" element={<SuperPerformance />} />
                <Route path="/super/statistics" element={<SuperStatistics />} />
                <Route path="/super/audit" element={<SuperAuditLog />} />
                <Route path="/super/parametres" element={<SuperSettings />} />
                
                <Route path="/communes" element={<Communes />} />
                <Route path="/ai-logs" element={<NdiogoyeLogs />} />
              </Route>
              
              <Route element={<RoleRoute allowedRoles={['super_admin', 'civil_admin_supervisor']} />}>
                <Route path="/admin/transactions" element={<Transactions />} />
              </Route>
            </Route>
          </Route>

          {/* Fallback */}
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>

        {/* Toast global */}
        <Toaster />
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
