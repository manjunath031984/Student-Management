import axios from 'axios';

const api = axios.create({
  // Local Vite default: Spring Boot on localhost. GKE images bake in VITE_API_BASE_URL=/api
  // so the browser uses the same-origin Gateway HTTPRoute (/api -> backend-service).
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

export const getAllStudents = async () => {
  const response = await api.get('/students');
  return response.data;
};

export const getStudentById = async (id) => {
  const response = await api.get(`/students/${id}`);
  return response.data;
};

export const createStudent = async (student) => {
  const response = await api.post('/students', student);
  return response.data;
};

export const updateStudent = async (id, student) => {
  const response = await api.put(`/students/${id}`, student);
  return response.data;
};

export const deleteStudent = async (id) => {
  await api.delete(`/students/${id}`);
};

export default api;
