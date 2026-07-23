import { API_BASE_URL } from './config';
import { getToken } from './tokenStore';

// Thrown on any non-2xx response. `message` is the backend's own
// {error, message} body when present (see GlobalExceptionHandler on
// the server) -- screens show err.message directly in an Alert, same
// convention as every mock-data error string before this rewrite.
export class ApiError extends Error {
  status: number;
  code?: string;

  constructor(status: number, message: string, code?: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

type HttpMethod = 'GET' | 'POST' | 'PATCH' | 'DELETE';

async function request<T = unknown>(method: HttpMethod, path: string, body?: unknown): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw new ApiError(
      0,
      'Could not reach the server. Check your connection and try again.',
      'network_error',
    );
  }

  if (response.status === 204) {
    return null as T;
  }

  const text = await response.text();
  const data = text ? JSON.parse(text) : null;

  if (!response.ok) {
    throw new ApiError(response.status, data?.message || 'Something went wrong.', data?.error);
  }
  return data as T;
}

export const apiClient = {
  get: <T = unknown>(path: string) => request<T>('GET', path),
  post: <T = unknown>(path: string, body?: unknown) => request<T>('POST', path, body ?? {}),
  patch: <T = unknown>(path: string, body?: unknown) => request<T>('PATCH', path, body ?? {}),
  delete: <T = unknown>(path: string) => request<T>('DELETE', path),
};