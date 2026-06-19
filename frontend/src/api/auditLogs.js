// src/api/auditLogs.js
import axiosClient from './axiosClient';

export const getAuditLogs = async (params = {}) => {
  const response = await axiosClient.get('/api/audit-logs/', { params });
  return response.data;
};
