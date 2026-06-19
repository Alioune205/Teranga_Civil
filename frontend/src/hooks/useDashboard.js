// src/hooks/useDashboard.js
import { useState, useEffect, useCallback } from 'react';
import { getStats, getGlobalStats, getPerformance, getActivity } from '@/api/dashboard';

export function useDashboard() {
  const [stats, setStats] = useState(null);
  const [globalStats, setGlobalStats] = useState(null);
  const [performance, setPerformance] = useState(null);
  const [activity, setActivity] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const results = await Promise.allSettled([
        getStats(),
        getGlobalStats(),
        getPerformance(),
        getActivity(),
      ]);
      
      setStats(results[0].status === 'fulfilled' ? results[0].value : null);
      setGlobalStats(results[1].status === 'fulfilled' ? results[1].value : null);
      setPerformance(results[2].status === 'fulfilled' ? results[2].value : null);
      setActivity(results[3].status === 'fulfilled' ? results[3].value : null);
      setLastUpdated(new Date());
    } catch (err) {
      setError(err.message || 'Erreur lors du chargement des données');
      console.error('Dashboard fetch error:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAll();
  }, [fetchAll]);

  return {
    stats,
    globalStats,
    performance,
    activity,
    loading,
    error,
    lastUpdated,
    refresh: fetchAll,
  };
}
