// src/api/users.js
import axiosClient from './axiosClient';

export const getUserList = async (params = {}) => {
  const response = await axiosClient.get('/api/users/', { params });
  return response.data;
};

export const createUser = async (data) => {
  const response = await axiosClient.post('/api/users/', data);
  return response.data;
};

export const deleteUser = async (id) => {
  const response = await axiosClient.delete(`/api/users/${id}/`);
  return response.data;
};

export const changeUserPassword = async (id, newPassword) => {
  const response = await axiosClient.post(`/api/users/${id}/change_password/`, { password: newPassword });
  return response.data;
};

export const toggleAgentBreak = async (id) => {
  const response = await axiosClient.patch(`/api/users/${id}/toggle_break/`);
  return response.data;
};

export const toggleAgentDispatchEligibility = async (id) => {
  const response = await axiosClient.patch(`/api/users/${id}/toggle_dispatch_eligibility/`);
  return response.data;
};
