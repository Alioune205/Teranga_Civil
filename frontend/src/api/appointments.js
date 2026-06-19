// src/api/appointments.js
import axiosClient from './axiosClient';

export const getAppointments = async (params = {}) => {
  const response = await axiosClient.get('/api/appointments/', { params });
  return response.data; // { count, next, previous, results } ou Array
};

export const scheduleAppointment = async (id, data) => {
  const response = await axiosClient.post(`/api/appointments/${id}/schedule/`, data);
  return response.data;
};

export const cancelAppointment = async (id, cancelReason) => {
  const response = await axiosClient.post(`/api/appointments/${id}/cancel/`, { cancel_reason: cancelReason });
  return response.data;
};
