// Reverse geocoding for the report form's map pin, via Mapbox Geocoding API v6.
// The token stays on the server; the apps only ever see the four address fields.
export interface Address { road: string; barangay: string; city: string; province: string; source: 'mapbox' | 'none' }
export type ReverseGeocode = (lat: number, lng: number, lang: string) => Promise<Address>;

const EMPTY: Address = { road: '', barangay: '', city: '', province: '', source: 'none' };
const CACHE_MS = 10 * 60 * 1000;
const str = (v: unknown) => (typeof v === 'string' ? v.trim() : '');

/** Maps a Mapbox v6 reverse-geocoding response to PATAG's address fields. Unknown parts stay "". */
export function toAddress(body: any): Address {
  const f = body?.features?.[0];
  if (!f) return EMPTY;
  const p = f.properties ?? {};
  const c = p.context ?? {};
  const road = str(c.street?.name) || str(c.address?.street_name)
    || (['street', 'address'].includes(p.feature_type) ? str(p.feature_type === 'address' ? c.address?.street_name || p.name_preferred || p.name : p.name) : '');
  const out: Address = {
    road,
    barangay: str(c.neighborhood?.name) || str(c.locality?.name),
    city: str(c.place?.name),
    province: str(c.region?.name),
    source: 'mapbox',
  };
  return out.road || out.barangay || out.city || out.province ? out : EMPTY;
}

export function createGeocoder({ token, fetchImpl = fetch, log = (_m: string) => {} }:
  { token: string; fetchImpl?: typeof fetch; log?: (m: string) => void }): ReverseGeocode {
  const cache = new Map<string, { at: number; value: Address }>();
  return async (lat, lng, lang) => {
    if (!token) return EMPTY;
    const key = `${lat.toFixed(5)},${lng.toFixed(5)},${lang}`;
    const hit = cache.get(key);
    if (hit && Date.now() - hit.at < CACHE_MS) return hit.value;
    const url = new URL('https://api.mapbox.com/search/geocode/v6/reverse');
    url.searchParams.set('longitude', String(lng));
    url.searchParams.set('latitude', String(lat));
    url.searchParams.set('country', 'ph');
    url.searchParams.set('limit', '1');
    if (lang === 'en') url.searchParams.set('language', 'en');
    url.searchParams.set('access_token', token);
    try {
      const res = await fetchImpl(url, { signal: AbortSignal.timeout(8000) });
      if (!res.ok) { log(`Mapbox reverse geocoding failed: HTTP ${res.status}`); return EMPTY; }
      const value = toAddress(await res.json());
      if (cache.size > 2000) cache.clear();
      cache.set(key, { at: Date.now(), value });
      return value;
    } catch (e) {
      log(`Mapbox reverse geocoding failed: ${(e as Error).message}`);
      return EMPTY;
    }
  };
}
