// LAN exposure guard, proxy-aware rate limiting and other hosting settings.
import test from 'node:test';
import assert from 'node:assert/strict';
import { demoExposureError, lanUrls, parseTrustProxy } from '../src/config.ts';
import { startServer } from './helpers.ts';

test('demo logins never start on a network interface by accident', () => {
  assert.equal(demoExposureError('127.0.0.1', true, false), null);
  assert.equal(demoExposureError('localhost', true, false), null);
  assert.equal(demoExposureError('0.0.0.0', false, false), null);
  assert.match(demoExposureError('0.0.0.0', true, false)!, /Refusing to start/);
  assert.match(demoExposureError('192.168.1.23', true, false)!, /ALLOW_DEMO_ON_LAN/);
  assert.equal(demoExposureError('0.0.0.0', true, true), null);
});

test('TRUST_PROXY parsing', () => {
  assert.equal(parseTrustProxy(undefined), false);
  assert.equal(parseTrustProxy(''), false);
  assert.equal(parseTrustProxy('false'), false);
  assert.equal(parseTrustProxy('1'), 1);
  assert.equal(parseTrustProxy('true'), 1);
  assert.deepEqual(parseTrustProxy('10.0.0.0/8, 172.16.0.1'), ['10.0.0.0/8', '172.16.0.1']);
});

test('LAN URLs are IPv4 API URLs', () => {
  for (const url of lanUrls(4100)) assert.match(url, /^http:\/\/\d+\.\d+\.\d+\.\d+:4100\/api$/);
});

async function loginAttempts(base: string, count: number, forwardedFor: (i: number) => string) {
  let last = 0;
  for (let i = 0; i < count; i++) {
    const res = await fetch(base + '/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Forwarded-For': forwardedFor(i) },
      body: JSON.stringify({ email: 'absent@example.test', password: 'wrong' }),
    });
    last = res.status;
  }
  return last;
}

test('behind a trusted proxy, the rate limit applies per real client', async () => {
  const { base, close } = await startServer({ trustProxy: 1 });
  try {
    // 21 attempts from 21 different clients: nobody is throttled.
    assert.equal(await loginAttempts(base, 21, i => `203.0.113.${i + 1}`), 401);
    // 21 attempts from one client: throttled.
    assert.equal(await loginAttempts(base, 21, () => '198.51.100.7'), 429);
  } finally { await close(); }
});

test('without a trusted proxy, a spoofed X-Forwarded-For cannot dodge the rate limit', async () => {
  const { base, close } = await startServer({ trustProxy: false });
  try {
    assert.equal(await loginAttempts(base, 21, i => `203.0.113.${i + 1}`), 429);
  } finally { await close(); }
});
