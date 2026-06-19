// src/api/dossiers.js
import axiosClient from './axiosClient';

export const getDossiers = async (params = {}) => {
  const response = await axiosClient.get('/api/dossiers/', { params });
  return response.data; // { count, next, previous, results }
};

export const getDossier = async (id) => {
  const response = await axiosClient.get(`/api/dossiers/${id}/`);
  return response.data;
};

export const patchDossier = async (id, data) => {
  const response = await axiosClient.patch(`/api/dossiers/${id}/`, data);
  return response.data;
};

export const assignDossier = async (id, agentId) => {
  const response = await axiosClient.post(`/api/dossiers/${id}/assign/`, { agent_id: agentId });
  return response.data;
};

export const reviewDossier = async (id) => {
  const response = await axiosClient.post(`/api/dossiers/${id}/review/`);
  return response.data;
};

export const approveDossier = async (id) => {
  const response = await axiosClient.post(`/api/dossiers/${id}/approve/`);
  return response.data;
};

export const rejectDossier = async (id, rejectionReason) => {
  const response = await axiosClient.post(`/api/dossiers/${id}/reject/`, { rejection_reason: rejectionReason });
  return response.data;
};

export const submitDossier = async (id) => {
  const response = await axiosClient.post(`/api/dossiers/${id}/submit/`);
  return response.data;
};

export const completeDossier = async (id) => {
  const response = await axiosClient.post(`/api/dossiers/${id}/complete/`);
  return response.data;
};

export const downloadPdf = async (id) => {
  const response = await axiosClient.get(`/api/dossiers/${id}/download-pdf/`, {
    responseType: 'blob',
  });
  return response.data;
};

export const downloadCopieLitterale = async (id) => {
  const response = await axiosClient.get(`/api/dossiers/${id}/download-copie-litterale/`, {
    responseType: 'blob',
  });
  return response.data;
};


