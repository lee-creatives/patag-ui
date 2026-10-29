# Current admin backend — 29 October 2026

The real admin-web uses the PostgreSQL Node BFF on4101 and shared public.users/public.sessions for ordinary administrator email/password login. Supabase Auth and the previous local account-ID bypass are removed. Password hashing and opaque session records match both existing mobile-backend branches. HttpOnly cookies, server-side role checks and operation-transaction session revalidation protect admin requests; identity is never inferred from UI selection. Profile compatibility is a view, not an account copy. Hosted migration, distinct legacy admin email and initial password setup remain pending explicit authorization. See [setup](supabase-backend.md) and [ADR-0003](decisions/0003-shared-account-login.md).

The following earlier architecture describes the separate demo, maintenance and citizen clients. Its mock-session/persistence and OSM claims do not describe the real admin's current backend or Mapbox configuration.

# Architecture

Three independent applications: Flutter/Dart citizen Android, Vite/React/TypeScript LGU portal on port 5173, and a separate Vite/React/TypeScript maintenance portal on 5174. Each web app owns its package manifest, node_modules, entry point, router, types, API adapter, assets and build. No web app imports another app's source; there is no React citizen view. Matching web patterns are duplicated locally for independent deployment. Shared changes must be applied to both copies and validated together.

`dev-mock/` is an optional development REST service, not a fourth user application and not a production backend. It uses Node built-ins, in-memory bearer sessions, scrypt account hashes, a local JSON file and local image files. Bind is loopback-only. Web state comes from HTTP bootstrap/polling; browser localStorage is used only for preferences. Android talks to the same API using configurable API_URL. Mock data persists only on the local machine. Reset by stopping the service and moving dev-mock/data elsewhere.

Source layers: `src/types.ts` contract, `src/api.ts` adapter, `src/App.tsx` route/component composition, `src/styles/app.css` design system. Empty structural folders reserve growth; substantive web code is intentionally centralized for this first working implementation. Flutter has `app/` for theme, `core/` for domain/API, `features/` for citizen workflows, and `shared/widgets/` for components.

Every operational mutation is validated by the mock API, with maintenance team ownership checks. Admin resolution requires an Awaiting Verification completion. The canonical status stays In Progress during completion review. Notifications are role/user/team scoped. This local service has intentionally open demo access and must never be deployed as production authentication.

Production requires database transactions, durable account/session handling, real authentication/password recovery, agency and team authorization, upload ownership and malware/image decoding checks, managed object storage, HTTPS, CORS configuration, rate limiting, backup, migration, transactional audit/events, and push/email delivery. Do not place secrets in VITE_ variables or Dart compile-time defines.

Maps use public OSM raster tiles with attribution. Follow https://operations.osmfoundation.org/policies/tiles/ for attribution, identification, caching and usage limits. No bulk download or offline tile prefetch is implemented. Address search/geocoding, clustering, route optimization and invented travel times are absent. Use a suitable provider and policy-compliant plan for production traffic.

Accessibility: semantic HTML, labels, native modal focus handling, Escape dismissal, skip link, visible keyboard focus, text in status/severity chips, reduced motion and overflow containers. Web responsive checks pass; full screen-reader/WCAG certification and native text scaling require additional manual validation. Android requests foreground location only when GPS is selected; image_picker uses Android camera/gallery flows. Location denial has manual fallback. Drafts survive reporting interruption, but submission requires the API; no offline sync is claimed.
