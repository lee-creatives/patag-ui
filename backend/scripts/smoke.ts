// Manual end-to-end check against a RUNNING backend. Never run in CI.
//   npm run smoke                          read-only checks against http://127.0.0.1:4100/api
//   npm run smoke -- --url https://…/api   against a hosted backend
//   npm run smoke -- --write               also creates a test citizen and one report (real data!)
// Nothing is deleted; everything created is printed so it can be found in Supabase.
const args = process.argv.slice(2);
const urlArg = args.indexOf('--url');
const base = (urlArg >= 0 ? args[urlArg + 1] : 'http://127.0.0.1:4100/api').replace(/\/$/, '');
const write = args.includes('--write');
const PNG = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

let failures = 0;
const ok = (msg: string) => console.log(`  ok   ${msg}`);
const bad = (msg: string) => { failures++; console.log(`  FAIL ${msg}`); };

async function call(path: string, body?: unknown, token?: string) {
  const started = Date.now();
  const res = await fetch(base + path, {
    method: body ? 'POST' : 'GET',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(60_000), // a sleeping free-tier host can take ~1 min to wake
  });
  return { status: res.status, data: (await res.json()) as any, ms: Date.now() - started };
}

console.log(`PATAG smoke test → ${base}${write ? '  (WRITE mode: creates real data)' : '  (read-only)'}`);
try {
  const health = await call('/health');
  if (health.status === 200 && health.data.mode === 'supabase') ok(`/health reports mode "supabase" (${health.ms} ms)`);
  else bad(`/health returned ${health.status} ${JSON.stringify(health.data)}; expected mode "supabase" (is this the old dev-mock?)`);

  const pub = await call('/public/reports');
  if (pub.status === 200 && Array.isArray(pub.data)) ok(`/public/reports returned ${pub.data.length} reports from Supabase (${pub.ms} ms)`);
  else bad(`/public/reports returned ${pub.status}`);

  if (write) {
    const stamp = Date.now();
    const email = `smoke+${stamp}@example.test`;
    const reg = await call('/auth/register', {
      name: 'Smoke Test Citizen', email, password: `Smoke-test-password-${stamp}`,
      address: { barangay: 'Guinhawa', city: 'Malolos', province: 'Bulacan' },
    });
    if (reg.status !== 201) throw new Error(`register returned ${reg.status} ${JSON.stringify(reg.data)}`);
    ok(`registered test citizen ${email} (user id ${reg.data.user.id})`);
    const token = reg.data.token;

    const photo = await call('/uploads', { data: PNG, name: 'smoke.png', kind: 'before' }, token);
    if (photo.status !== 201) throw new Error(`upload returned ${photo.status} ${JSON.stringify(photo.data)}`);
    ok(`uploaded photo ${photo.data.url} to the Storage bucket`);

    const report = await call('/reports', {
      title: `Smoke test ${new Date(stamp).toISOString()}`, description: 'Automated smoke test report. Safe to reject.',
      severity: 'Low', photos: [photo.data],
      location: { road: 'Smoke Test Road', barangay: 'Guinhawa', city: 'Malolos', province: 'Bulacan', coordinates: { lat: 14.8527, lng: 120.816 } },
    }, token);
    if (report.status !== 201) throw new Error(`report returned ${report.status} ${JSON.stringify(report.data)}`);
    ok(`submitted report ${report.data.id}`);

    const boot = await call('/bootstrap', undefined, token);
    if (boot.data.reports?.some((r: any) => r.id === report.data.id)) ok(`report ${report.data.id} read back from /bootstrap`);
    else bad('the new report was not returned by /bootstrap');
    await call('/auth/logout', {}, token);
    console.log(`\nCreated (not deleted): user ${email}, report ${report.data.id}, photo ${photo.data.url}`);
    console.log('An admin can reject the report in admin-web; the test account can be disabled there too.');
  }
} catch (e) {
  bad((e as Error).message.includes('fetch failed') ? `cannot reach ${base}. Is the backend running?` : (e as Error).message);
}
console.log(failures ? `\n${failures} check(s) failed.` : '\nAll checks passed.');
process.exitCode = failures ? 1 : 0;
