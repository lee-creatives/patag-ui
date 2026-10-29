import type { Bootstrap, Photo } from './types';
export const API = import.meta.env.VITE_API_URL || '/api';
export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) { super(message); this.status = status; }
}
export const asset = (url: string) => /^\/evidence\/[a-f0-9-]{36}$/.test(url) ? API + url : '';
let backendCheck: Promise<void> | undefined;
async function call<T>(path: string, body?: unknown, method?: string): Promise<T> {
  let response: Response;
  try {
    response = await fetch(API + path, {
      method: method || (body ? 'POST' : 'GET'), credentials: 'include',
      headers: { 'Content-Type': 'application/json', 'X-Patag-Request': '1', ...(body && /\/events$/.test(path) ? { 'Idempotency-Key': crypto.randomUUID() } : {}) },
      body: body ? JSON.stringify(body) : undefined, signal: AbortSignal.timeout(20000),
    });
  } catch { throw new ApiError(503, 'PostgreSQL backend unavailable. Check the API address and server setup.'); }
  let data;
  try { data = await response.json(); } catch { throw new ApiError(503, 'PostgreSQL API is unavailable or incorrectly configured.'); }
  if (!response.ok) throw new ApiError(response.status, data.error || 'Request failed. Please retry.');
  return data;
}
export async function request<T>(path: string, body?: unknown, method?: string): Promise<T> {
  backendCheck ??= call<{ backend: string }>('/health').then(data => {
    if (data.backend !== 'postgresql') throw new ApiError(503, 'This admin application requires the PATAG PostgreSQL backend.');
  }).catch(error => { backendCheck = undefined; throw error; });
  await backendCheck;
  if (path !== '/bootstrap') return call<T>(path, body, method);
  const result = await call<Bootstrap & { nextOffset: number | null }>('/bootstrap');
  let next = result.nextOffset, pages = 1;
  while (next !== null) {
    if (++pages > 50) throw new ApiError(413, 'Workspace exceeds 5,000 records per collection. Use a filtered API view.');
    const chunk = await call<Bootstrap & { nextOffset: number | null }>('/bootstrap?offset=' + next);
    result.reports.push(...chunk.reports); result.teams.push(...chunk.teams);
    result.users.push(...chunk.users); result.notifications.push(...chunk.notifications);
    if (chunk.nextOffset !== null && chunk.nextOffset <= next) throw new ApiError(503, 'Invalid API pagination.');
    next = chunk.nextOffset;
  }
  return result as T;
}
export async function upload(file: File, kind = 'after'): Promise<Photo> {
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || file.size > 8 * 1024 * 1024) throw new Error('Choose a JPEG, PNG or WebP photo under 8 MB.');
  const data = await new Promise<string>((resolve, reject) => {
    const reader = new FileReader(); reader.onload = () => resolve(String(reader.result)); reader.onerror = () => reject(new Error('Could not read the photo.')); reader.readAsDataURL(file);
  });
  return request<Photo>('/uploads', { data, name: file.name, kind });
}
