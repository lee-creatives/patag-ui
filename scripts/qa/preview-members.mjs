import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium, expect } from '../../admin-web/node_modules/@playwright/test/index.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const html = await fs.readFile(path.join(root, 'preview/Open-PATAG.html'));
const server = http.createServer((req, res) => { res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }); res.end(html); });
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const url = `http://127.0.0.1:${server.address().port}/`;
const out = path.join(root, 'test-results/preview-members');
await fs.mkdir(out, { recursive: true });
const results = { checks: [], errors: [] };
let browser;
try {
  browser = await chromium.launch({ channel: 'chrome', headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const admin = await context.newPage();
  const crew = await context.newPage();
  context.on('page', page => page.on('pageerror', error => results.errors.push(error.message)));
  for (const page of [admin, crew]) { page.setDefaultTimeout(10000); page.on('pageerror', error => results.errors.push(error.message)); }
  const call = (page, endpoint, body, method) => page.evaluate(async ({ endpoint, body, method }) => {
    const response = await fetch('/api' + endpoint, { method: method || (body ? 'POST' : 'GET'), headers: { 'Content-Type': 'application/json' }, body: body ? JSON.stringify(body) : undefined });
    return { status: response.status, data: await response.json() };
  }, { endpoint, body, method });
  async function enter(page, role, label) {
    await page.goto(url + '#/' + role + '/login');
    const demo = page.getByRole('button', { name: label, exact: true });
    if (!await demo.isVisible()) await page.locator('summary').click();
    await demo.click(); await expect(page).toHaveURL(new RegExp('#/' + role + '/dashboard'));
  }
  await enter(admin, 'admin', 'Continue as LGU administrator');
  await enter(crew, 'maintenance', 'Open maintenance demo');
  const before = (await call(crew, '/bootstrap')).data;
  const all = (await call(admin, '/bootstrap')).data;
  const originalReport = before.reports[0].id;
  const unassignedReport = all.reports.find(r => !r.teamId).id;
  const provisioned = await call(admin, '/users', { name: 'Preview Member', email: 'preview-member@example.test', role: 'maintenance', teamId: before.user.teamId, password: 'Preview-Test-123!' });
  expect(provisioned.status).toBe(201);
  const first = before.user.id, second = provisioned.data.id;
  await admin.goto(url + '#/admin/teams');
  await admin.getByRole('button', { name: 'Add team', exact: true }).click();
  let dialog = admin.getByRole('dialog');
  await dialog.getByLabel('Team name', { exact: true }).fill('Preview Selected Crew');
  await dialog.locator(`input[value="${first}"]`).check();
  await dialog.getByRole('button', { name: 'Save team', exact: true }).click(); await expect(dialog).toHaveCount(0);
  await admin.reload();
  let panel = admin.locator('.panel').filter({ has: admin.getByRole('heading', { name: 'Preview Selected Crew', exact: true }) });
  await panel.getByRole('button', { name: 'Edit team', exact: true }).click(); dialog = admin.getByRole('dialog');
  await expect(dialog.locator(`input[value="${first}"]`)).toBeChecked();
  await dialog.locator(`input[value="${first}"]`).uncheck(); await dialog.locator(`input[value="${second}"]`).check();
  await dialog.getByRole('button', { name: 'Save team', exact: true }).click(); await expect(dialog).toHaveCount(0); await admin.reload();
  panel = admin.locator('.panel').filter({ has: admin.getByRole('heading', { name: 'Preview Selected Crew', exact: true }) });
  await panel.getByRole('button', { name: 'Edit team', exact: true }).click(); dialog = admin.getByRole('dialog');
  await expect(dialog.locator(`input[value="${first}"]`)).not.toBeChecked(); await expect(dialog.locator(`input[value="${second}"]`)).toBeChecked();
  await admin.screenshot({ path: path.join(out, 'members.png'), fullPage: true });
  await dialog.getByRole('button', { name: 'Close dialog', exact: true }).click();
  results.checks.push('Generated preview creates crews and persists add/remove selections after reload');
  const removed = (await call(crew, '/bootstrap')).data;
  expect(removed.reports).toEqual([]); expect(removed.notifications).toEqual([]);
  for (const id of [originalReport, unassignedReport]) {
    expect((await call(crew, '/reports/' + id)).status).toBe(403);
    expect((await call(crew, '/reports/' + id + '/events', { action: 'start' })).status).toBe(403);
  }
  results.checks.push('Existing removed-crew session loses old/unassigned report and event access');
  const team = (await call(admin, '/bootstrap')).data.teams.find(t => t.name === 'Preview Selected Crew');
  const race = await admin.evaluate(async ({ first, second, team }) => {
    const call = async (endpoint, body) => {
      const response = await fetch('/api' + endpoint, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
      return response.status;
    };
    return Promise.all([call('/users', { id: first, name: 'Edited concurrently', password: 'Changed-Test-123!' }), call('/teams', { id: team.id, name: team.name, memberIds: [first, second] })]);
  }, { first, second, team });
  expect(race).toEqual([200, 200]);
  const refreshed = (await call(admin, '/bootstrap')).data;
  expect(refreshed.users.find(u => u.id === first).teamId).toBe(team.id);
  expect(refreshed.users.find(u => u.id === first).name).toBe('Edited concurrently');
  results.checks.push('Password edit cannot overwrite a concurrent crew transfer');
  const loginRace = await admin.evaluate(async ({ first, second, team }) => {
    const login = fetch('/api/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'crew@example.test', password: 'Changed-Test-123!', role: 'maintenance' }) });
    const transfer = await fetch('/api/teams', { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id: team.id, name: team.name, memberIds: [second] }) });
    return [(await login).status, transfer.status];
  }, { first, second, team });
  expect(loginRace).toEqual([200, 200]);
  expect((await call(admin, '/bootstrap')).data.users.find(u => u.id === first).teamId).toBe(null);
  results.checks.push('Password login cannot restore an old crew membership snapshot');
  const revoked = await admin.evaluate(async second => {
    const pending = fetch('/api/users', { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id: second, name: 'Must not save', password: 'Revoked-Test-123!' }) });
    await fetch('/api/auth/logout', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' });
    return (await pending).status;
  }, second);
  expect(revoked).toBe(401);
  results.checks.push('Logout during password hashing revokes the pending account edit');
  expect(results.errors).toEqual([]);
} catch (error) { results.failure = error.message; process.exitCode = 1; }
finally {
  if (browser) await browser.close(); await new Promise(resolve => server.close(resolve));
  await fs.writeFile(path.join(out, 'results.json'), JSON.stringify(results, null, 2)); console.log(JSON.stringify(results, null, 2));
}
