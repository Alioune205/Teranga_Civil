// src/api/auth.js
import axiosClient from './axiosClient';

export const loginAPI = async (email, password) => {
  const response = await axiosClient.post('/api/auth/login/', { email, password });
  return response.data; // { access, refresh, user }
};

export const logoutAPI = async () => {
  try {
    const refresh = localStorage.getItem('refresh_token');
    await axiosClient.post('/api/auth/logout/', { refresh });
  } catch (error) {
    // Même si le logout échoue côté serveur, on nettoie le client
    console.warn('Logout API error:', error);
  }
};

export const refreshTokenAPI = async (refresh) => {
  const response = await axiosClient.post('/api/auth/refresh/', { refresh });
  return response.data; // { access }
};
