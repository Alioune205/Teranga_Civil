// src/components/PrivateRoute.jsx
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';

export function PrivateRoute() {
  const { isAuthenticated, loading } = useAuth();

  // Pendant le chargement initial, afficher un spinner
  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin" />
          <p className="text-sm text-text-400 font-medium">Chargement...</p>
        </div>
      </div>
    );
  }

  // Si non authentifié → redirect /login
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  // Sinon → afficher le contenu protégé
  return <Outlet />;
}
