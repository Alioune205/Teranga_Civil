import axiosClient from '../api/axiosClient';

const BASE_URL = '/api/attribution';

export const attributionApi = {
    getStats: async () => {
        const response = await axiosClient.get(`${BASE_URL}/stats/`);
        return response.data;
    },
    getAgentsCharge: async () => {
        const response = await axiosClient.get(`${BASE_URL}/agents/charge/`);
        return response.data;
    },
    getCarteAttributions: async (page = 1) => {
        const response = await axiosClient.get(`${BASE_URL}/dossiers/carte/?page=${page}`);
        return response.data;
    },
    getJournal: async (page = 1) => {
        const response = await axiosClient.get(`${BASE_URL}/journal/?page=${page}`);
        return response.data;
    },
    reattribuerDossier: async (dossierId, agentId, raison) => {
        const response = await axiosClient.post(`${BASE_URL}/dossier/${dossierId}/reattribuer/`, {
            agent_id: agentId,
            raison: raison
        });
        return response.data;
    },
    suspendreAttributionAuto: async (communeId, dureeHeures = 24) => {
        const response = await axiosClient.post(`${BASE_URL}/attribution/suspendre/`, {
            commune_id: communeId,
            duree_heures: dureeHeures
        });
        return response.data;
    },
    getAgentPerformance: async (agentId) => {
        const response = await axiosClient.get(`${BASE_URL}/agents/${agentId}/performance/`);
        return response.data;
    },
    getRecommandation: async (dossierId) => {
        const response = await axiosClient.get(`${BASE_URL}/recommandation/${dossierId}/`);
        return response.data;
    },
    triggerGlobalDispatching: async () => {
        const response = await axiosClient.post(`${BASE_URL}/dispatching/global/`);
        return response.data;
    }
};
