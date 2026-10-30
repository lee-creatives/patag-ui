// Reverse geocoding: Mapbox response mapping, caching, failure handling and the HTTP route.
// Mapbox is always faked here; the real API is never called.
import test from 'node:test';
import assert from 'node:assert/strict';
import { createGeocoder, toAddress } from '../src/geocode.ts';
import { startServer } from './helpers.ts';

const mapbox = (properties: object) => ({ type: 'FeatureCollection', features: [{ type: 'Feature', properties }] });
const malolos = mapbox({
  feature_type: 'address', name: '123 MacArthur Highway',
  context: {
    address: { name: '123 MacArthur Highway', street_name: 'MacArthur Highway' },
    street: { name: 'MacArthur Highway' },
    neighborhood: { name: 'Guinhawa' },
    place: { name: 'Malolos' },
    region: { name: 'Bulacan' },
    country: { name: 'Philippines' },
  },
});
const jsonResponse = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

test('maps Mapbox context to road, barangay, city and province', () => {
  assert.deepEqual(toAddress(malolos), { road: 'MacArthur Highway', barangay: 'Guinhawa', city: 'Malolos', province: 'Bulacan', source: 'mapbox' });
  // locality stands in for barangay when there is no neighborhood
  assert.equal(toAddress(mapbox({ context: { locality: { name: 'Mojon' }, place: { name: 'Malolos' } } })).barangay, 'Mojon');
  // unknown parts stay empty; nothing is invented
  assert.deepEqual(toAddress(mapbox({ context: { place: { name: 'Malolos' } } })), { road: '', barangay: '', city: 'Malolos', province: '', source: 'mapbox' });
  // nothing found
  assert.equal(toAddress({ features: [] }).source, 'none');
  assert.equal(toAddress(mapbox({ context: {} })).source, 'none');
  assert.equal(toAddress(null).source, 'none');
});

test('geocoder: request shape, cache, errors and missing token', async () => {
  const calls: URL[] = [];
  const geocode = createGeocoder({ token: 'pk.test', fetchImpl: (async (url: URL) => { calls.push(new URL(url)); return jsonResponse(malolos); }) as typeof fetch });
  const a = await geocode(14.857629, 120.81612, 'en');
  assert.equal(a.road, 'MacArthur Highway');
  const url = calls[0];
  assert.equal(url.origin + url.pathname, 'https://api.mapbox.com/search/geocode/v6/reverse');
  assert.equal(url.searchParams.get('latitude'), '14.857629');
  assert.equal(url.searchParams.get('longitude'), '120.81612');
  assert.equal(url.searchParams.get('country'), 'ph');
  assert.equal(url.searchParams.get('access_token'), 'pk.test');
  // same spot (to 5 decimals) is served from cache
  await geocode(14.8576291, 120.8161201, 'en');
  assert.equal(calls.length, 1);

  const failing = createGeocoder({ token: 'pk.test', fetchImpl: (async () => jsonResponse({ message: 'quota' }, 429)) as typeof fetch });
  assert.equal((await failing(14.85, 120.81, 'en')).source, 'none');
  const throwing = createGeocoder({ token: 'pk.test', fetchImpl: (async () => { throw new Error('offline'); }) as typeof fetch });
  assert.equal((await throwing(14.85, 120.81, 'en')).source, 'none');
  let called = false;
  const noToken = createGeocoder({ token: '', fetchImpl: (async () => { called = true; return jsonResponse(malolos); }) as typeof fetch });
  assert.equal((await noToken(14.85, 120.81, 'en')).source, 'none');
  assert.equal(called, false);
});

test('GET /geocode/reverse: auth, validation, rate limit and fallback', async () => {
  const seen: [number, number, string][] = [];
  const { call, close } = await startServer({ geocode: async (lat, lng, lang) => { seen.push([lat, lng, lang]); return toAddress(malolos); } });
  try {
    assert.equal((await call('/geocode/reverse?lat=14.85&lng=120.81')).status, 401);
    const citizen = (await call('/auth/demo', { role: 'citizen' })).data.token;
    const ok = await call('/geocode/reverse?lat=14.857629&lng=120.81612&lang=fil', undefined, citizen);
    assert.equal(ok.status, 200);
    assert.deepEqual(ok.data, { road: 'MacArthur Highway', barangay: 'Guinhawa', city: 'Malolos', province: 'Bulacan', source: 'mapbox' });
    assert.deepEqual(seen[0], [14.857629, 120.81612, 'fil']);
    for (const q of ['lat=200&lng=120', 'lat=14&lng=abc', 'lng=120', '']) {
      assert.equal((await call('/geocode/reverse?' + q, undefined, citizen)).status, 400, q);
    }
    let last = 0;
    for (let i = 0; i < 31; i++) last = (await call('/geocode/reverse?lat=14.85&lng=120.81', undefined, citizen)).status;
    assert.equal(last, 429);
  } finally { await close(); }

  // No geocoder configured: empty fields, never an error.
  const bare = await startServer();
  try {
    const citizen = (await bare.call('/auth/demo', { role: 'citizen' })).data.token;
    const r = await bare.call('/geocode/reverse?lat=14.85&lng=120.81', undefined, citizen);
    assert.equal(r.status, 200);
    assert.deepEqual(r.data, { road: '', barangay: '', city: '', province: '', source: 'none' });
  } finally { await bare.close(); }
});
