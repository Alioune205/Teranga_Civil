import axiosClient from '@/api/axiosClient';

export const getCitoyens = async (params = {}) => {
  try {
    const response = await axiosClient.get('/api/citoyens/', { params });
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const getCitoyenById = async (id) => {
  try {
    const response = await axiosClient.get(`/api/citoyens/${id}/`);
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const createCitoyen = async (data) => {
  try {
    const response = await axiosClient.post('/api/citoyens/', data);
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const updateCitoyen = async (id, data) => {
  try {
    const response = await axiosClient.patch(`/api/citoyens/${id}/`, data);
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const processGuichetRapide = async (id, data) => {
  try {
    const response = await axiosClient.post(`/api/citoyens/${id}/guichet/`, data);
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const getCitoyenDocuments = async (id) => {
  try {
    const response = await axiosClient.get(`/api/citoyens/${id}/documents/`);
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const downloadPdfWithAuth = async (pdfUrl) => {
  try {
    const response = await axiosClient.get(pdfUrl, {
      responseType: 'blob'
    });
    return response.data;
  } catch (error) {
    throw error;
  }
};
