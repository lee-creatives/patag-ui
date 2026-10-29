import test from 'node:test';
import assert from 'node:assert/strict';
import { configuration, accountId, fields, HttpError } from '../config.mjs';

test('missing Supabase configuration fails with a setup error', () => {
  assert.throws(() => configuration({}), /SUPABASE_URL/);
});
test('private keys and TLS are required, with explicit trusted browser origins', () => {
  const env = { SUPABASE_URL: 'https://example.supabase.co', SUPABASE_SERVICE_ROLE_KEY: 'server-key', SUPABASE_DB_URL: 'postgresql://postgres:secret@db.example.supabase.co/postgres', ADMIN_ORIGIN: 'http://127.0.0.1:5173' };
  assert.equal(configuration(env).origin, env.ADMIN_ORIGIN);
  assert.throws(() => configuration({ ...env, SUPABASE_URL: 'http://example.supabase.co' }), /HTTPS/);
  assert.throws(() => configuration({ ...env, NODE_ENV: 'production' }), /HTTPS/);
  assert.throws(() => configuration({ ...env, SUPABASE_SERVICE_ROLE_KEY: '' }), /SERVICE_ROLE/);
});
test('server credentials never select or bypass the signed-in administrator',()=>{
 const env={SUPABASE_URL:'https://example.supabase.co',SUPABASE_SERVICE_ROLE_KEY:'server-key',SUPABASE_DB_URL:'postgresql://postgres:secret@db.example.supabase.co/postgres',ADMIN_ORIGIN:'http://127.0.0.1:5173',PATAG_ALLOW_UNAUTHENTICATED_LOCAL_ADMIN:'true',PATAG_LOCAL_ADMIN_ID:'forged-admin'};
 assert.equal(configuration(env).allowLocalAdmin,undefined);assert.equal(configuration(env).localAdminId,undefined);
 assert.throws(()=>fields({name:'Test',role:'admin'},['name']),HttpError);
});

test('text account identifiers are bounded and distinct from UUID validation',()=>{
 assert.equal(accountId('mobile:account-7'),'mobile:account-7');
 for(const value of [undefined,'',' ','a'.repeat(201),'bad/id','bad?id','bad#id','bad\nvalue']) assert.throws(()=>accountId(value),HttpError);
});
