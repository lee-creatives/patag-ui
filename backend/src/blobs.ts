// Evidence photo storage. Production: a private Supabase Storage bucket, read through the API.
export interface Blob { bytes: Buffer; contentType: string }
export interface BlobStore {
  put(name: string, bytes: Buffer, contentType: string): Promise<void>;
  get(name: string): Promise<Blob | null>;
}

export class SupabaseBlobStore implements BlobStore {
  base: string; key: string; bucket: string;
  constructor(supabaseUrl: string, secretKey: string, bucket: string) {
    this.base = supabaseUrl.replace(/\/$/, '') + '/storage/v1';
    this.key = secretKey;
    this.bucket = bucket;
  }
  private headers(extra: Record<string, string> = {}) {
    return { apikey: this.key, Authorization: `Bearer ${this.key}`, ...extra };
  }
  async put(name: string, bytes: Buffer, contentType: string) {
    const res = await fetch(`${this.base}/object/${this.bucket}/${name}`, {
      method: 'POST', headers: this.headers({ 'Content-Type': contentType, 'x-upsert': 'false' }), body: new Uint8Array(bytes),
      signal: AbortSignal.timeout(15000),
    });
    if (!res.ok) throw new Error(`Storage upload failed: HTTP ${res.status} ${await res.text().catch(() => '')}`);
  }
  async get(name: string) {
    const res = await fetch(`${this.base}/object/authenticated/${this.bucket}/${name}`, { headers: this.headers(), signal: AbortSignal.timeout(15000) });
    if (res.status === 400 || res.status === 404) return null;
    if (!res.ok) throw new Error(`Storage download failed: HTTP ${res.status}`);
    return { bytes: Buffer.from(await res.arrayBuffer()), contentType: res.headers.get('content-type') || 'application/octet-stream' };
  }
  /** Creates the private bucket if it does not exist yet. */
  async ensureBucket() {
    const res = await fetch(`${this.base}/bucket`, {
      method: 'POST', headers: this.headers({ 'Content-Type': 'application/json' }),
      body: JSON.stringify({ id: this.bucket, name: this.bucket, public: false, file_size_limit: 8 * 1024 * 1024, allowed_mime_types: ['image/png', 'image/jpeg', 'image/webp'] }),
    });
    const text = await res.text();
    if (res.ok) return 'created';
    if (/already exists|Duplicate/i.test(text)) return 'exists';
    throw new Error(`Bucket setup failed: HTTP ${res.status} ${text}`);
  }
}

/** For tests only. */
export class MemoryBlobStore implements BlobStore {
  files = new Map<string, Blob>();
  async put(name: string, bytes: Buffer, contentType: string) { this.files.set(name, { bytes, contentType }); }
  async get(name: string) { return this.files.get(name) ?? null; }
}
