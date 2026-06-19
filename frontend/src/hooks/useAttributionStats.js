import { useState, useEffect, useCallback } from 'react';
import { attributionApi } from '../services/attributionApi';

export const useAttributionStats = () => {
    const [data, setData] = useState({
        total: 0,
        en_attente: 0,
        en_traitement: 0,
        termines: 0,
        rejetes: 0
    });
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [lastUpdated, setLastUpdated] = useState(Date.now());

    const fetchStats = useCallback(async () => {
        try {
            const stats = await attributionApi.getStats();
            setData(stats);
            setError(null);
            setLastUpdated(Date.now());
        } catch (err) {
            setError('Erreur lors du chargement des statistiques');
            console.error(err);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchStats();
        // Polling toutes les 30 secondes
        const intervalId = setInterval(fetchStats, 30000);
        return () => clearInterval(intervalId);
    }, [fetchStats]);

    return { data, loading, error, lastUpdated, refetch: fetchStats };
};
