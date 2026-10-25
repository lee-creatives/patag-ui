import { SupabaseBlobStore } from '../src/blobs.ts';
import { config, requireEnv } from '../src/config.ts';

requireEnv('SUPABASE_URL', 'SUPABASE_SECRET_KEY');
const result = await new SupabaseBlobStore(config.supabaseUrl, config.supabaseSecretKey, config.bucket).ensureBucket();
console.log(`Private bucket "${config.bucket}": ${result}.`);
