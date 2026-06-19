// src/hooks/useDossiers.js
import { useState, useEffect, useCallback } from 'react';
import { getDossiers } from '@/api/dossiers';
import { useAuth } from './useAuth';

export function useDossiers(initialParams = {}) {
  const { role, user } = useAuth();
  const [data, setData] = useState({ count: 0, results: [], next: null, previous: null });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [params, setParams] = useState({
    page: 1,
    page_size: 20,
    ...initialParams,
  });

  const fetchDossiers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      // Filtrage automatique par rôle
      const filteredParams = { ...params };
      
      const userCommuneId = typeof user?.commune === 'object' ? user.commune?.id : user?.commune;
      if (role === 'civil_admin' && userCommuneId) {
        filteredParams.commune = userCommuneId;
      }
      if ((role === 'agent' || role === 'reception_agent' || role === 'verification_agent') && user?.id) {
        filteredParams.assigned_agent = user.id;
      }

      // Nettoyer les paramètres vides
      Object.keys(filteredParams).forEach((key) => {
        if (filteredParams[key] === '' || filteredParams[key] === undefined || filteredParams[key] === null) {
          delete filteredParams[key];
        }
      });

      const result = await getDossiers(filteredParams);
      setData(result);
    } catch (err) {
      setError(err.message || 'Erreur lors du chargement des dossiers');
      console.error('Dossiers fetch error:', err);
    } finally {
      setLoading(false);
    }
  }, [params, role, user]);

  useEffect(() => {
    fetchDossiers();
  }, [fetchDossiers]);

  const updateParams = useCallback((newParams) => {
    setParams((prev) => ({ ...prev, ...newParams, page: newParams.page || 1 }));
  }, []);

  const setPage = useCallback((page) => {
    setParams((prev) => ({ ...prev, page }));
  }, []);

  return {
    data,
    loading,
    error,
    params,
    updateParams,
    setPage,
    refresh: fetchDossiers,
  };
}
