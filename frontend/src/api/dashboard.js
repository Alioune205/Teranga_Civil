// src/api/dashboard.js
import axiosClient from './axiosClient';

export const getStats = async () => {
  const response = await axiosClient.get('/api/dashboard/stats/');
  return response.data;
};

export const getGlobalStats = async () => {
  const response = await axiosClient.get('/api/dashboard/global-stats/');
  return response.data;
};

export const getPerformance = async () => {
  const response = await axiosClient.get('/api/dashboard/performance/');
  return response.data;
};

export const getActivity = async () => {
  const response = await axiosClient.get('/api/dashboard/activity/');
  return response.data;
};
