import axiosClient from "./axiosClient";

export const getNdiogoyeLogs = async (page = 1) => {
  const response = await axiosClient.get(`/api/ai/ndiogoye/logs/?page=${page}`);
  return response.data;
};
