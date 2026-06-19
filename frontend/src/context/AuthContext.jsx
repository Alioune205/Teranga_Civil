// src/context/AuthContext.jsx
import { createContext, useState, useEffect, useCallback } from 'react';
import { loginAPI, logoutAPI } from '@/api/auth';
import { jwtDecode } from 'jwt-decode';
import { clearSecureImageCache } from '@/hooks/useSecureImage';

export const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [role, setRole] = useState(null);
  const [loading, setLoading] = useState(true);

  // Au montage : restaurer la session depuis localStorage
  useEffect(() => {
    try {
      const storedToken = localStorage.getItem('access_token');
      const storedUser = localStorage.getItem('user');

      if (storedToken && storedUser) {
        const parsedUser = JSON.parse(storedUser);
        setToken(storedToken);
        setUser(parsedUser);

        // Extraire le rôle depuis le token JWT ou depuis l'user stocké
        try {
          const decoded = jwtDecode(storedToken);
          setRole(decoded.role || parsedUser.role || 'agent');
        } catch {
          setRole(parsedUser.role || 'agent');
        }
      }
    } catch (error) {
      console.error('Erreur lors de la restauration de la session:', error);
      localStorage.clear();
    } finally {
      setLoading(false);
    }
  }, []);

  const login = useCallback(async (email, password) => {
    const data = await loginAPI(email, password);
    const { access, refresh, user: userData } = data;

    localStorage.setItem('access_token', access);
    localStorage.setItem('refresh_token', refresh);
    localStorage.setItem('user', JSON.stringify(userData));

    setToken(access);
    setUser(userData);

    // Extraire le rôle depuis le JWT
    try {
      const decoded = jwtDecode(access);
      setRole(decoded.role || userData.role || 'agent');
    } catch {
      setRole(userData.role || 'agent');
    }

    return userData;
  }, []);

  const logout = useCallback(async () => {
    try {
      await logoutAPI();
    } catch (error) {
      console.warn('Logout error:', error);
    } finally {
      clearSecureImageCache();
      localStorage.clear();
      setUser(null);
      setToken(null);
      setRole(null);
    }
  }, []);

  const isAuthenticated = !!token && !!user;

  const value = {
    user,
    token,
    role,
    isAuthenticated,
    loading,
    login,
    logout,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}
