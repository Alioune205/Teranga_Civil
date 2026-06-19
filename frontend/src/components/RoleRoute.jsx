// src/components/RoleRoute.jsx
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';

export function RoleRoute({ allowedRoles }) {
  const { role, loading } = useAuth();

  if (loading) {
    return null; // ou un spinner
  }

  if (!allowedRoles.includes(role)) {
    // Si l'utilisateur n'a pas le bon rôle, il est redirigé vers le Dashboard
    return <Navigate to="/dashboard" replace />;
  }

  return <Outlet />;
}
