import axiosClient from './axiosClient';

/**
 * Récupère la liste des notifications
 * @param {Object} params - Paramètres de pagination/filtres (ex: { page: 1, is_read: false })
 */
export const getNotifications = async (params = {}) => {
  try {
    const response = await axiosClient.get('/api/notifications/', { params });
    return response.data;
  } catch (error) {
    console.error('Erreur lors de la récupération des notifications', error);
    throw error;
  }
};

/**
 * Marque une notification comme lue
 * @param {string|number} id - L'ID de la notification
 */
export const markAsRead = async (id) => {
  try {
    const response = await axiosClient.post(`/api/notifications/${id}/mark-read/`);
    return response.data;
  } catch (error) {
    console.error('Erreur lors du marquage de la notification', error);
    throw error;
  }
};

/**
 * Marque toutes les notifications de l'utilisateur comme lues
 */
export const markAllAsRead = async () => {
  try {
    const response = await axiosClient.post('/api/notifications/mark-all-read/');
    return response.data;
  } catch (error) {
    console.error('Erreur lors du marquage de toutes les notifications', error);
    throw error;
  }
};
