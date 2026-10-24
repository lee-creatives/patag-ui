// Run from the repository root: node admin-web/tests/browser-qa.mjs
// Starts all test servers in the same execution context to avoid sandbox process isolation.
import { chromium } from "@playwright/test";
import http from "node:http";
import { createServer } from "../../dev-mock/server.mjs";
import { mkdir, writeFile, readFile } from "node:fs/promises";
import path from "node:path";
const root = path.resolve(import.meta.dirname, "../..");
const api = await createServer({ persist: false });
await new Promise((r) => api.listen(4100, "127.0.0.1", r));
const web = [];
let browser;
const results = { routes: [], widths: [], errors: [], consoleErrors: [], workflows: [] };
try {
  for (const [app, port] of [
    ["admin-web", 5173],
    ["maintenance-web", 5174],
  ]) {
    const s = http.createServer(async (req, res) => {
      let file = path.join(
        root,
        app,
        "dist",
        new URL(req.url, "http://localhost").pathname,
      );
      try {
        const content = await readFile(file);
        const type =
          {
            ".js": "text/javascript",
            ".css": "text/css",
            ".png": "image/png",
            ".ttf": "font/ttf",
          }[path.extname(file)] || "text/html";
        res.writeHead(200, { "Content-Type": type });
        res.end(content);
      } catch {
        res.writeHead(200, { "Content-Type": "text/html" });
        res.end(await readFile(path.join(root, app, "dist/index.html")));
      }
    });
    await new Promise((r) => s.listen(port, "127.0.0.1", r));
    web.push(s);
  }
  await mkdir(path.join(root, "docs/qa-downloads"), { recursive: true });
  browser = await chromium.launch({
    channel: "chrome",
    headless: true,
    downloadsPath: path.join(root, "docs/qa-downloads"),
    args: ["--disable-gpu"],
  });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 1000 },
    acceptDownloads: true,
  });
  const page = await context.newPage();
  page.on("pageerror", (e) => results.errors.push(e.message));
  page.on("console", (m) => { if(m.type()==='error') results.consoleErrors.push(m.text()); });
  const apiCall = async (url, body, token) => {
    const r = await fetch("http://127.0.0.1:4100/api" + url, {
      method: body ? "POST" : "GET",
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: "Bearer " + token } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const data = await r.json();
    if (!r.ok) throw Error(JSON.stringify(data));
    return data;
  };
  const c = await apiCall("/auth/demo", { role: "citizen" }),
    photo = await apiCall(
      "/uploads",
      {
        name: "test.png",
        data: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
      },
      c.token,
    );
  const report = await apiCall(
    "/reports",
    {
      title: "Browser workflow test",
      description: "Broken road beside waiting shed",
      severity: "High",
      photos: [photo],
      location: {
        road: "Workflow Test Road",
        barangay: "Guinhawa",
        city: "Malolos",
        province: "Bulacan",
        landmark: "Test waiting shed",
        coordinates: { lat: 14.852, lng: 120.811 },
      },
    },
    c.token,
  );
  await page.goto("http://127.0.0.1:5173/admin/login");
  await page
    .getByRole("button", { name: "Continue as LGU administrator" })
    .click();
  await page
    .getByRole("heading", { name: "Roads overview" })
    .waitFor();
  await mkdir(path.join(root, "docs/visual-system/production"), { recursive: true });
  const adminRoutes = [
    "dashboard",
    "reports",
    "reports/PTG-2026-0101",
    "verification",
    "verification/PTG-2026-0101",
    "duplicates",
    "map",
    "assignments",
    "assignments/new/PTG-2026-0103",
    "teams",
    "teams/team-1",
    "completions",
    "completions/PTG-2026-0107",
    "users",
    "users/citizen-1",
    "analytics",
    "exports",
    "notifications",
    "settings",
    "activity",
  ];
  for (const route of adminRoutes) {
    await page.goto("http://127.0.0.1:5173/admin/" + route);
    await page.locator("main#main h1").waitFor();
    results.routes.push({
      portal: "admin",
      route,
      title: await page.locator("main#main h1").textContent(),
    });
  }
  await page.goto("http://127.0.0.1:5173/admin/reports");
  await page.getByRole("textbox", { name: "Search reports" }).fill("MacArthur");
  await page.getByText("1 matching reports").waitFor();
  await page.getByRole("button", { name: "Reset", exact: true }).click();
  await page
    .getByRole("combobox", { name: "Severity filter" })
    .selectOption("High");
  results.workflows.push("Admin search and severity filtering");
  await page.goto("http://127.0.0.1:5173/admin/verification/" + report.id);
  await page
    .getByRole("button", { name: "Verify report", exact: true })
    .click();
  await page
    .getByRole("button", { name: "Confirm verify", exact: true })
    .click();
  await page
    .getByRole("button", { name: "Assign maintenance team", exact: true })
    .waitFor();
  await page
    .getByRole("button", { name: "Assign maintenance team", exact: true })
    .click();
  await page
    .getByRole("combobox", { name: "Maintenance team", exact: true })
    .selectOption("team-1");
  await page
    .getByRole("button", { name: "Confirm assign", exact: true })
    .click();
  await page.getByRole("dialog").waitFor({ state: "hidden" });
  results.workflows.push(
    "Admin verified and assigned API-created citizen report",
  );
  await page.goto("http://127.0.0.1:5173/admin/exports");
  await page.evaluate(() => {
    window.__exportBlobs = [];
    const original = URL.createObjectURL;
    URL.createObjectURL = function (blob) {
      window.__exportBlobs.push(blob);
      return original.call(URL, blob);
    };
  });
  for (const kind of ["CSV", "PDF"]) {
    await page.getByRole("button", { name: "Download " + kind }).click();
    await page.waitForFunction(() => window.__exportBlobs.length > 0);
    const encoded = await page.evaluate(async () => {
      const blob = window.__exportBlobs.shift();
      const bytes = new Uint8Array(await blob.arrayBuffer());
      return btoa(Array.from(bytes, (b) => String.fromCharCode(b)).join(""));
    });
    const buffer = Buffer.from(encoded, "base64");
    if (kind === "PDF" && !buffer.toString("ascii", 0, 4).startsWith("%PDF"))
      throw Error("Invalid PDF export");
    if (kind === "CSV" && !buffer.toString("utf8").includes("Reference"))
      throw Error("Invalid CSV export");
    await writeFile(
      path.join(root, "docs/visual-system/production/qa-export." + kind.toLowerCase()),
      buffer,
    );
  }
  results.workflows.push(
    "CSV and PDF export blobs validated; native browser file writes are canceled by this sandbox",
  );
  for (const width of [320, 375, 390, 430, 768, 1024, 1280, 1366, 1440, 1920]) {
    await page.setViewportSize({ width, height: 1000 });
    await page.goto("http://127.0.0.1:5173/admin/dashboard");
    await page.locator("main#main h1").waitFor();
    await page.screenshot({
      path: path.join(root, `docs/visual-system/production/admin-${width}.png`),
      fullPage: true,
    });
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth > innerWidth,
    );
    results.widths.push({ portal: "admin", width, overflow });
    if (overflow) throw Error("Admin overflow at " + width);
  }
  await page.setViewportSize({width:390,height:900});
  if(await page.locator('.sidebar.open').count())await page.getByRole('button',{name:'Close navigation drawer',exact:true}).click();
  await page.getByRole('button',{name:'Open navigation',exact:true}).click();
  await page.getByRole('navigation',{name:'Main navigation'}).getByRole('link',{name:'All reports',exact:true}).click();
  await page.getByRole('heading',{name:'All reports',exact:true}).waitFor();
  await page.waitForFunction(()=>!document.querySelector('.sidebar.open'));
  const tableLayout=await page.evaluate(()=>({width:innerWidth,scroll:document.documentElement.scrollWidth,oversized:[...document.querySelectorAll('body *')].filter(e=>e.getBoundingClientRect().right>innerWidth+2).slice(0,12).map(e=>({tag:e.tagName,cls:e.className,right:e.getBoundingClientRect().right}))}));
  if(tableLayout.scroll>tableLayout.width)throw Error('Mobile table layout overflow: '+JSON.stringify(tableLayout));
  await page.screenshot({path:path.join(root,'docs/visual-system/production/admin-table-390.png'),fullPage:true,animations:'disabled'});
  await page.goto('http://127.0.0.1:5173/admin/map');
  await page.getByRole('button',{name:'Zoom in',exact:true}).click();
  await page.getByRole('button',{name:'Recenter report map'}).click();
  await page.locator('.leaflet-interactive').first().click();
  await page.locator('.leaflet-popup').waitFor();
  results.workflows.push('Mobile sidebar navigation, scrollable report table, map zoom/recenter and marker popup');
  const crew = await context.newPage();
  crew.on("pageerror", (e) => results.errors.push(e.message));
  crew.on("console", (m) => { if(m.type()==='error') results.consoleErrors.push(m.text()); });
  await crew.goto("http://127.0.0.1:5174/maintenance/login");
  await crew
    .getByRole("button", { name: "Continue as Road Crew Alpha" })
    .click();
  await crew
    .getByRole("heading", { name: "Your day on the road" })
    .waitFor();
  const maintenanceRoutes = [
    "dashboard",
    "assignments",
    "assignments/PTG-2026-0104",
    "map",
    "progress",
    "progress/PTG-2026-0106",
    "repairs/PTG-2026-0106/document",
    "repairs/PTG-2026-0106/submit",
    "repairs/PTG-2026-0107/success",
    "submissions",
    "history",
    "notifications",
    "profile",
  ];
  for (const route of maintenanceRoutes) {
    await crew.goto("http://127.0.0.1:5174/maintenance/" + route);
    await crew.locator("main#main h1").waitFor();
    results.routes.push({
      portal: "maintenance",
      route,
      title: await crew.locator("main#main h1").textContent(),
    });
  }
  await crew.goto('http://127.0.0.1:5174/maintenance/users');
  await crew.getByRole('heading',{name:'This page requires another role'}).waitFor();
  results.workflows.push('Maintenance route guard blocks admin user-management view');
  await crew.goto("http://127.0.0.1:5174/maintenance/assignments/" + report.id);
  await crew
    .getByRole("button", { name: "Start inspection / repair", exact: true })
    .click();
  await crew
    .getByRole("button", { name: "Confirm start", exact: true })
    .click();
  await crew
    .getByRole("link", { name: "Update progress", exact: true })
    .waitFor();
  await crew
    .getByRole("link", { name: "Update progress", exact: true })
    .click();
  await crew
    .getByRole("textbox", { name: "Work performed / progress notes" })
    .fill("Inspected the road and compacted the patch.");
  await crew
    .getByRole("button", { name: "Save progress", exact: true })
    .click();
  await crew
    .getByRole("status")
    .filter({ hasText: "Report updated" })
    .waitFor();
  await crew.goto(
    "http://127.0.0.1:5174/maintenance/repairs/" + report.id + "/document",
  );
  await crew
    .getByRole("textbox", { name: "Work performed / progress notes" })
    .fill(
      "Patching complete. Base compacted, finished surface inspected, lane cleared.",
    );
  await crew
    .getByLabel("After-repair photos")
    .setInputFiles({
      name: "after.png",
      mimeType: "image/png",
      buffer: Buffer.from(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
        "base64",
      ),
    });
  await crew.getByRole("button", { name: "Remove after.png" }).waitFor();
  await crew
    .getByRole("link", { name: "Review completion", exact: true })
    .click();
  await crew
    .getByRole("button", {
      name: "Submit for administrative verification",
      exact: true,
    })
    .click();
  await crew
    .getByRole("heading", { name: "Work submitted. One step closer to patag." })
    .waitFor();
  results.workflows.push(
    "Maintenance started work, saved progress, uploaded a photo and submitted completion",
  );
  await page.goto("http://127.0.0.1:5173/admin/completions/" + report.id);
  await page
    .getByRole("button", { name: "Confirm resolution", exact: true })
    .click();
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Confirm resolution", exact: true })
    .click();
  await page.getByRole("dialog").waitFor({ state: "hidden" });
  const own = await apiCall("/bootstrap", undefined, c.token);
  if (own.reports.find((r) => r.id === report.id).status !== "Resolved")
    throw Error("Citizen did not receive resolution");
  await apiCall(
    "/reports/" + report.id + "/feedback",
    { rating: 5, text: "Test feedback after verified repair" },
    c.token,
  );
  results.workflows.push(
    "Admin resolved repair; citizen API received history/notification and submitted feedback",
  );
  for (const width of [320, 375, 390, 430, 768, 1024, 1280, 1366, 1440, 1920]) {
    await crew.setViewportSize({ width, height: 1000 });
    await crew.goto("http://127.0.0.1:5174/maintenance/dashboard");
    await crew.locator("main#main h1").waitFor();
    await crew.screenshot({
      path: path.join(root, `docs/visual-system/production/maintenance-${width}.png`),
      fullPage: true,
    });
    const overflow = await crew.evaluate(
      () => document.documentElement.scrollWidth > innerWidth,
    );
    results.widths.push({ portal: "maintenance", width, overflow });
    if (overflow) throw Error("Maintenance overflow at " + width);
  }
  if (results.errors.length)
    throw Error("Browser errors: " + results.errors.join("; "));
  console.log(JSON.stringify(results, null, 2));
} catch (e) {
  results.failure = e.message;
  console.error(e);
  process.exitCode = 1;
} finally {
  await writeFile(
    path.join(root, "docs/visual-system/production-results.json"),
    JSON.stringify(results, null, 2),
  );
  await browser?.close();
  for (const s of web) await new Promise((r) => s.close(r));
  await new Promise((r) => api.close(r));
}
