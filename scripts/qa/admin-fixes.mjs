import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createServer } from '../../admin-web/node_modules/vite/dist/node/index.js';
import { chromium, expect } from '../../admin-web/node_modules/@playwright/test/index.mjs';
import { startServer } from '../../backend/test/helpers.ts';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const origin = 'http://127.0.0.1:5189';
const out = path.join(root, 'test-results/admin-fixes');
await fs.mkdir(out, { recursive: true });
const fixture = await startServer({ corsOrigins: [origin] });
let vite;
const results = { checks: [], errors: [], failures: [], externalFailures: [] };
let browser;
async function check(name, run) {
  try { await run(); results.checks.push(name); console.log('PASS ' + name); }
  catch (error) { results.failures.push({ name, error: error.message }); console.log('FAIL ' + name + ': ' + error.message); }
}
try {
  vite = await createServer({ root: path.join(root, 'admin-web'), configFile: path.join(root, 'admin-web/vite.config.ts'),
    server: { host: '127.0.0.1', port: 5189, strictPort: true },
    define: { 'import.meta.env.VITE_API_URL': JSON.stringify(fixture.base) }, logLevel: 'error' });
  await vite.listen();
  await expect.poll(async () => { try { return (await fetch(origin)).status; } catch { return 0; } }).toBe(200);
  browser = await chromium.launch({ channel: "chrome", headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const page = await context.newPage();
  page.setDefaultTimeout(8000);
  page.on('pageerror', error => results.errors.push(error.message));
  page.on('requestfailed', req => { if (!req.url().startsWith(origin) && !req.url().startsWith(fixture.base)) results.externalFailures.push(req.url().split('?')[0]); });
  const mutations = [];
  page.on('request', req => { if (['POST', 'PATCH'].includes(req.method()) && /\/(users|auth\/login)$/.test(req.url())) mutations.push(req.url()); });
  const go = route => page.goto(origin + '/admin/' + route);
  await go('login');
  assert.equal(await page.evaluate(async () => (await import('/src/api.ts')).API), fixture.base, 'browser must use the isolated fixture API');
  async function login() {
    await go('login');
    const button = page.getByRole('button', { name: 'Continue as LGU administrator' });
    if (!await button.isVisible()) await page.locator('summary').click();
    await button.click(); await page.getByRole('heading', { name: 'Roads overview', exact: true }).waitFor();
  }
  async function geometry(scope) {
    const input = scope.locator('input[name=password]');
    const show = scope.getByRole('button', { name: 'Show password', exact: true });
    await input.fill('Synthetic-Pass-123!');
    await show.scrollIntoViewIfNeeded();
    await input.focus();
    const before = { input: await input.boundingBox(), button: await show.boundingBox(), parent: await scope.boundingBox() };
    const count = mutations.length;
    const box = before.button;
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await page.mouse.down();
    const during = await show.boundingBox();
    assert.deepEqual(during, before.button, 'pointer-down moved the visibility button');
    await page.mouse.up();
    const hide = scope.getByRole('button', { name: 'Hide password', exact: true });
    await expect(input).toHaveAttribute('type', 'text');
    assert.deepEqual(await hide.boundingBox(), before.button);
    assert.deepEqual(await input.boundingBox(), before.input);
    assert.deepEqual(await scope.boundingBox(), before.parent);
    await expect(input).toHaveValue('Synthetic-Pass-123!'); await expect(input).toBeFocused();
    await hide.focus(); await page.keyboard.press('Space');
    await expect(input).toHaveAttribute('type', 'password'); await expect(show).toBeFocused();
    await page.keyboard.press('Enter'); await expect(input).toHaveAttribute('type', 'text');
    await expect(scope.getByRole('button', { name: 'Hide password', exact: true })).toHaveAttribute('type', 'button');
    assert.equal(mutations.length, count, 'visibility toggle submitted a form');
    await page.keyboard.press('Space');
  }
  await check('English default and login password geometry, focus, keyboard and no submit at 390/1440 in light/dark', async () => {
    for (const theme of ['light', 'dark']) for (const width of [390, 1440]) {
      await page.evaluate(theme => localStorage.setItem('patag-theme', theme), theme);
      await page.setViewportSize({ width, height: 1000 }); await go('login');
      await expect(page.locator('html')).toHaveAttribute('data-theme', theme);
      await expect(page.locator('html')).toHaveAttribute('lang', 'en');
      await geometry(page.locator('.login-form form'));
    }
  });
  await login();
  await check('Actual fullscreen entry, resize, zoom/recenter controls, button exit and Escape exit', async () => {
    await go('map');
    const wrapper = page.locator('.map-wrapper').first();
    const original = await wrapper.boundingBox();
    await page.getByRole('button', { name: 'Enter fullscreen map', exact: true }).click();
    await expect.poll(() => page.evaluate(() => document.fullscreenElement?.className)).toContain('map-wrapper');
    const exit = page.getByRole('button', { name: 'Exit fullscreen map', exact: true });
    await expect(exit).toHaveAttribute('aria-pressed', 'true');
    const full = await wrapper.boundingBox(); const viewport = page.viewportSize();
    assert.equal(full.width, viewport.width); assert.equal(full.height, viewport.height);
    assert.deepEqual(await wrapper.locator('.leaflet-container').boundingBox(), full);
    await page.getByRole('button', { name: 'Zoom in', exact: true }).click();
    await page.getByRole('button', { name: 'Recenter report map', exact: true }).click();
    await page.screenshot({ path: path.join(out, 'fullscreen.png') });
    await exit.click();
    await expect.poll(() => page.evaluate(() => document.fullscreenElement === null)).toBe(true);
    await expect(page.getByRole('button', { name: 'Enter fullscreen map', exact: true })).toBeFocused();
    assert.deepEqual(await wrapper.boundingBox(), original);
    await page.getByRole('button', { name: 'Enter fullscreen map', exact: true }).click();
    await page.keyboard.press('Escape');
    await expect.poll(() => page.evaluate(() => document.fullscreenElement === null)).toBe(true);
    await expect(page.getByRole('button', { name: 'Enter fullscreen map', exact: true })).toHaveAttribute('aria-pressed', 'false');
  });
  await check('Create/edit crew member selection persists after reload and supports adding/removing accounts', async () => {
    const members = (await fixture.store.listUsers()).filter(u => u.role === 'maintenance' && u.active);
    assert.ok(members.length >= 2);
    await go('teams'); await page.getByRole('button', { name: 'Add team', exact: true }).click();
    let dialog = page.getByRole('dialog'); await dialog.getByLabel('Team name', { exact: true }).fill('QA Selected Crew');
    await dialog.locator(`input[value="${members[0].id}"]`).check(); await dialog.getByRole('button', { name: 'Save team' }).click();
    await expect(dialog).toHaveCount(0); await page.reload();
    let panel = page.locator('.panel').filter({ has: page.getByRole('heading', { name: 'QA Selected Crew', exact: true }) });
    await expect(panel).toContainText(members[0].name); await panel.getByRole('button', { name: 'Edit team', exact: true }).click();
    dialog = page.getByRole('dialog'); await expect(dialog.locator(`input[value="${members[0].id}"]`)).toBeChecked();
    await dialog.locator(`input[value="${members[0].id}"]`).uncheck(); await dialog.locator(`input[value="${members[1].id}"]`).check();
    await dialog.getByRole('button', { name: 'Save team' }).click(); await expect(dialog).toHaveCount(0); await page.reload();
    panel = page.locator('.panel').filter({ has: page.getByRole('heading', { name: 'QA Selected Crew', exact: true }) });
    await panel.getByRole('button', { name: 'Edit team', exact: true }).click();
    dialog = page.getByRole('dialog'); await expect(dialog.locator(`input[value="${members[1].id}"]`)).toBeChecked(); await expect(dialog.locator(`input[value="${members[0].id}"]`)).not.toBeChecked();
    assert.equal((await fixture.store.userById(members[0].id)).teamId, null);
    const team = (await fixture.store.listTeams()).find(t => t.name === 'QA Selected Crew');
    assert.equal((await fixture.store.userById(members[1].id)).teamId, team.id);
    await page.screenshot({ path: path.join(out, 'crew-members.png') }); await dialog.getByRole('button', { name: 'Close dialog' }).click();
  });
  await check('Create/edit account password geometry, keyboard, preserved value and no submit at 390/1440 in light/dark', async () => {
    const account = await fixture.store.insertUser({ name: 'QA Account', email: 'qa-account@example.test', role: 'citizen', active: true, teamId: null, address: null, emailVerified: false, passwordHash: null });
    for (const theme of ['light', 'dark']) for (const width of [390, 1440]) for (const edit of [false, true]) {
      await page.evaluate(theme => localStorage.setItem('patag-theme', theme), theme);
      await page.setViewportSize({ width, height: 1000 }); await go('users' + (edit ? '/' + account.id : ''));
      await expect(page.locator('html')).toHaveAttribute('data-theme', theme);
      if (edit) await page.getByRole('button', { name: 'Manage', exact: true }).click();
      else await page.getByRole('button', { name: 'Add account', exact: true }).click();
      const dialog = page.getByRole('dialog'); await geometry(dialog); await dialog.getByRole('button', { name: 'Close dialog', exact: true }).click();
    }
  });
  await page.setViewportSize({ width: 1440, height: 1000 });
  await check('Tagalog across navigation, routes, map controls and dialogs; reload persistence; canonical status filters and English restoration', async () => {
    await go('settings'); await page.getByRole('combobox', { name: 'Language', exact: true }).selectOption('tl');
    await expect(page.locator('html')).toHaveAttribute('lang', 'tl');
    await expect(page.locator('.topnav').getByRole('link', { name: 'Pangkalahatang-ideya', exact: true })).toBeVisible();
    await expect(page.locator('.topnav').getByRole('link', { name: 'Pamamahala ng mga user', exact: true })).toBeVisible(); await expect(page.getByRole('heading', { name: 'Mga setting ng workspace', exact: true })).toBeVisible();
    for (const [route, heading] of [['dashboard', 'Pangkalahatang-ideya ng mga kalsada'], ['reports', 'Lahat ng ulat'], ['map', 'Mapa ng mga lubak'], ['teams', 'Mga pangkat sa pagkukumpuni'], ['users', 'Mga account ng workspace'], ['analytics', 'Pangkalahatang pagtingin sa mga ulat ng komunidad.'], ['exports', 'Pag-download ng datos'], ['activity', 'Kasaysayan ng ulat']]) {
      await go(route); await expect(page.getByRole('heading', { name: heading, exact: true })).toBeVisible();
      if (route === 'map') {
        await expect(page.getByRole('button', { name: 'Ipakita ang mapa sa buong screen', exact: true })).toBeVisible();
        await expect(page.getByRole('button', { name: 'Palakihin', exact: true })).toBeVisible();
        await expect(page.getByRole('button', { name: 'Igitna muli ang mapa ng ulat', exact: true })).toBeVisible();
      }
      if (route === 'activity') await expect(page.getByRole('heading', { name: /naitalang pangyayari/ })).toBeVisible();
    }
    await go('reports'); await page.getByRole('combobox', { name: 'Salain ayon sa katayuan' }).selectOption('Verified');
    await expect(page.getByRole('combobox', { name: 'Salain ayon sa katayuan' })).toHaveValue('Verified');
    await fixture.store.insertTeam({ name: 'Overview', active: true });
    await go('teams'); await expect(page.getByRole('heading', { name: 'Overview', exact: true })).toBeVisible();
    await page.getByRole('button', { name: 'Magdagdag ng pangkat', exact: true }).click();
    await expect(page.getByRole('dialog')).toContainText('Mga miyembro ng pangkat'); await page.getByRole('button', { name: 'Isara ang dialog', exact: true }).click();
    await go('settings'); await page.reload(); await expect(page.getByRole('combobox', { name: 'Wika', exact: true })).toHaveValue('tl');
    const fallback = await page.evaluate(async () => { const m = await import('/src/i18n.ts'); return ['Missing translation sentinel', '__proto__', 'constructor', 'toString'].map(key => m.translate(key, 'tl')); }); assert.deepEqual(fallback, ['Missing translation sentinel', '__proto__', 'constructor', 'toString']);
    await page.screenshot({ path: path.join(out, 'tagalog-settings.png') });
    await page.getByRole('combobox', { name: 'Wika', exact: true }).selectOption('en'); await page.reload();
    await expect(page.getByRole('heading', { name: 'Workspace settings', exact: true })).toBeVisible(); await expect(page.getByRole('combobox', { name: 'Language', exact: true })).toHaveValue('en');
  });
  await check('Invalid saved language falls back to English', async () => {
    const invalid = await browser.newContext(); await invalid.addInitScript(() => localStorage.setItem('patag-language', 'unsupported'));
    const tab = await invalid.newPage(); await tab.goto(origin + '/admin/login'); await expect(tab.locator('html')).toHaveAttribute('lang', 'en');
    await expect(tab.getByRole('button', { name: 'Sign in', exact: true })).toBeVisible(); await invalid.close();
  });
  assert.deepEqual(results.errors, [], 'browser runtime errors');
} catch (error) { results.failures.push({ name: 'runner', error: error.message }); }
finally {
  if (browser) await browser.close(); await vite?.close(); await fixture.close();
  await fs.writeFile(path.join(out, 'results.json'), JSON.stringify(results, null, 2));
  console.log(JSON.stringify(results, null, 2)); if (results.failures.length) process.exitCode = 1;
}
