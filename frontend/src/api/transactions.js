import axiosClient from './axiosClient';

/**
 * Récupère la liste des transactions avec filtres et pagination.
 * @param {Object} params - Les filtres (page, page_size, payment_type, status, date_from, date_to)
 */
export const getTransactions = async (params) => {
  const response = await axiosClient.get('/api/v1/admin/transactions', { params });
  return response.data;
};

/**
 * Récupère les statistiques consolidées des transactions pour le dashboard.
 */
export const getTransactionStats = async () => {
  const response = await axiosClient.get('/api/v1/admin/transactions/stats');
  return response.data;
};

