// src/api/communes.js
import axiosClient from './axiosClient';

export const getCommuneList = async () => {
  const response = await axiosClient.get('/api/communes/');
  return response.data;
};

export const createCommune = async (data) => {
  const response = await axiosClient.post('/api/communes/', data);
  return response.data;
};

export const updateCommune = async (id, data) => {
  const response = await axiosClient.put(`/api/communes/${id}/`, data);
  return response.data;
};

export const patchCommune = async (id, data) => {
  const response = await axiosClient.patch(`/api/communes/${id}/`, data);
  return response.data;
};

export const deleteCommune = async (id) => {
  const response = await axiosClient.delete(`/api/communes/${id}/`);
  return response.data;
};
