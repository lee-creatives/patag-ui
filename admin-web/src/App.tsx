import {
  Fragment,
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
} from "react";
import type { FormEvent, ReactNode } from "react";
import {
  BrowserRouter,
  Link,
  NavLink,
  Navigate,
  Route,
  Routes,
  useLocation,
  useNavigate,
  useParams,
} from "react-router-dom";
import {
  ArrowUpRight,
  ArrowRight,
  ArrowLeft,
  Bell,
  Sun,
  Moon,
  MapPin,
  LayoutDashboard,
  ClipboardList,
  ShieldCheck,
  Users,
  ChartNoAxesCombined,
  Download,
  Settings,
  History,
  Menu,
  X,
  Search,
  Check,
  ChevronRight,
  Truck,
  Camera,
  RefreshCw,
  CheckCircle2,
  Navigation,
  Clock,
  FileCheck,
  Copy,
  Eye,
  EyeOff,
  LogOut,
} from "lucide-react";
import {
  MapContainer,
  TileLayer,
  CircleMarker,
  Popup,
  useMap,
} from "react-leaflet";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import type { Bootstrap, Report, Photo, User, Team } from "./types";
import { statuses } from "./types";
import { request, asset, upload, ApiError } from "./api";
import { validCoordinates, mapSettings } from "./map";
import { reportDates, resolutionDays } from "./analytics";
import { role } from "./config";
import "leaflet/dist/leaflet.css";
import "./styles/app.css";
import "./styles/premium.css";
import "./styles/visual-system.css";
import "./styles/login-redesign.css";
import { useTheme } from "./theme";

const admin = role === "admin",
  base = admin ? "/admin" : "/maintenance";
const navigation = admin
  ? [
      ["dashboard", "Overview", LayoutDashboard],
      ["reports", "All reports", ClipboardList],
      ["map", "Pothole map", MapPin],
      ["verification", "Verification queue", ShieldCheck],
      ["duplicates", "Possible duplicates", Copy],
      ["assignments", "Assignments", Truck],
      ["completions", "Repair verification", FileCheck],
      ["teams", "Maintenance teams", Users],
      ["users", "User accounts", Users],
      ["analytics", "Analytics", ChartNoAxesCombined],
      ["exports", "Export center", Download],
      ["activity", "Report history", History],
    ]
  : [
      ["dashboard", "Overview", LayoutDashboard],
      ["assignments", "My assignments", ClipboardList],
      ["map", "Task map", MapPin],
      ["progress", "In progress", Truck],
      ["submissions", "Completion submissions", FileCheck],
      ["history", "Repair history", History],
    ];
type Ctx = {
  data: Bootstrap;
  refresh: () => Promise<void>;
  notify: (s: string) => void;
  event: (
    id: string,
    action: string,
    payload?: Record<string, unknown>,
  ) => Promise<void>;
};
const Context = createContext<Ctx | null>(null);
const useData = () => useContext(Context)!;
const date = (v: string) =>
  new Date(v).toLocaleDateString("en-PH", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
function Badge({ value }: { value: string }) {
  return (
    <span className={"badge " + value.toLowerCase().replaceAll(" ", "-")}>
      <span aria-hidden="true" /> {value}
    </span>
  );
}
function Logo() {
  return <img className="logo" src="/assets/patag-logo.png" alt="PATAG" />;
}
function Empty({
  title = "No reports here yet",
  text = "When a report matches this view, it will appear here.",
}: {
  title?: string;
  text?: string;
}) {
  return (
    <div className="empty">
      <img src="/assets/patag-mascot.png" alt="" />
      <h2>{title}</h2>
      <p>{text}</p>
    </div>
  );
}
function Header({
  title,
  description,
  action,
}: {
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  const workspace = useContext(Context)?.data;
  return (
    <header className="page-heading">
      <div>
        <p className="scope">
          {admin ? "LGU operations" : workspace?.teams.find(t=>t.id===workspace.user.teamId)?.name || "Maintenance"}{" "}
          <ChevronRight size={13} /> {workspace?.settings?.city || "Malolos"}, {workspace?.settings?.province || "Bulacan"}
        </p>
        <h1>{title}</h1>
        {description && <p>{description}</p>}
      </div>
      {action}
    </header>
  );
}
function Panel({
  title,
  aside,
  children,
  className = "",
}: {
  title: string;
  aside?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <section className={"panel " + className}>
      <div className="panel-title">
        <h2>{title}</h2>
        {aside}
      </div>
      {children}
    </section>
  );
}
function Modal({
  title,
  children,
  close,
}: {
  title: string;
  children: ReactNode;
  close: () => void;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    ref.current?.showModal();
    return () => ref.current?.close();
  }, []);
  return (
    <dialog
      ref={ref}
      onCancel={close}
      onClick={(e) => {
        if (e.target === ref.current) close();
      }}
    >
      <header>
        <h2>{title}</h2>
        <button
          className="icon-button"
          aria-label="Close dialog"
          onClick={close}
        >
          <X size={20} />
        </button>
      </header>
      {children}
    </dialog>
  );
}
function RoleBoundary({ children }: { children: ReactNode }) {
  const loc = useLocation();
  const page = loc.pathname.split("/")[2];
  const forbidden =
    (!admin &&
      [
        "reports",
        "verification",
        "duplicates",
        "teams",
        "users",
        "completions",
        "analytics",
        "exports",
        "settings",
        "activity",
      ].includes(page)) ||
    (admin && ["progress", "repairs", "submissions", "history"].includes(page));
  return forbidden ? (
    <Empty
      title="This page requires another role"
      text="Use the navigation for your authorized workspace."
    />
  ) : (
    children
  );
}
function Login() {
  const nav = useNavigate();
  const [error, setError] = useState(""), [loading, setLoading] = useState(false), [showPassword, setShowPassword] = useState(false);
  const run = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();const form=new FormData(e.currentTarget);setError("");setLoading(true);
    try {await request("/auth/login",{email:form.get("email"),password:form.get("password")});nav(base+"/dashboard",{replace:true});}
    catch(error) {setError((error as Error).message);}
    finally {setLoading(false);}
  };
  return (
    <main className="login">
      <div className="login-card">
        <section className="login-story">
          <div className="login-story-top">
            <Logo />
          </div>
          <div className="login-story-body">
            <h1>
              {admin ? "Better roads." : "Safe roads."}
              <br />
              {admin ? "Built together." : "Repaired fast."}
            </h1>
            <p className="login-story-desc">
              {admin
                ? "Turn community reports into coordinated municipal action."
                : "One repair at a time. Make the way safer for everyone."}
            </p>
          </div>
          <small className="login-story-footer">
            IT 305 · Bulacan State University · Academic demonstration
          </small>
        </section>
        <section className="login-form">
          <div className="login-accent-mark" aria-hidden="true">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round">
              <line x1="12" y1="2" x2="12" y2="22" />
              <line x1="2" y1="12" x2="22" y2="12" />
              <line x1="4.93" y1="4.93" x2="19.07" y2="19.07" />
              <line x1="19.07" y1="4.93" x2="4.93" y2="19.07" />
            </svg>
          </div>
          <span className="pill-label">
            {admin ? "LGU administrator" : "Road maintenance"}
          </span>
          <h2>Sign in to PATAG</h2>
          <p className="login-subtitle">Use your existing PATAG administrator email and password.</p>
          <form onSubmit={run}>
            <label>
              Email address
              <input
                name="email"
                type="email"
                autoComplete="email"
                required
                placeholder="you@example.test"
              />
            </label>
            {(
              <label className="password-label">
                Password
                <div className="password-wrap">
                  <input
                    name="password"
                    type={showPassword ? "text" : "password"}
                    autoComplete="current-password"
                    required
                    minLength={1}
                    placeholder="Enter your password"
                  />
                  <button
                    type="button"
                    className="password-toggle-btn"
                    aria-label={showPassword ? "Hide password" : "Show password"}
                    aria-pressed={showPassword}
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </label>
            )}
            {error && (
              <p role="alert" className="error">
                {error}
              </p>
            )}
            <button className="primary submit-btn" disabled={loading}>
              {loading ? "Signing in…" : "Sign in"}
              <ArrowRight size={16} />
            </button>
          </form>
          <p className="login-footnote">Administrator access is required. Contact your administrator if your password has not been set.</p>
        </section>
      </div>
    </main>
  );
}
function Shell() {
  const { theme, toggleTheme } = useTheme();
  const [isMobile, setIsMobile] = useState(() => window.innerWidth < 1024);
  useEffect(() => {
    const query = window.matchMedia("(max-width: 1023px)");
    const update = () => setIsMobile(query.matches);
    query.addEventListener("change", update);
    return () => query.removeEventListener("change", update);
  }, []);
  const [data, setData] = useState<Bootstrap | null>(null),
    [error, setError] = useState(""),
    [toast, setToast] = useState(""),
    [menu, setMenu] = useState(() => window.innerWidth >= 1024 && localStorage.getItem("patag-sidebar") !== "collapsed");
  const loc = useLocation(), nav = useNavigate();
  const refresh = useCallback(async () => {
    try {
      const d = await request<Bootstrap>("/bootstrap");
      if (d.user.role !== role) throw Error("Configured account cannot open this workspace.");
      setData(d);
      setError("");
    } catch (e) {
      const m = (e as Error).message;
      setError(m);
      if(e instanceof ApiError&&e.status===401) {setData(null);nav(base+"/login",{replace:true});}
    }
  }, [nav]);
  useEffect(() => {
    void refresh();
    const t = setInterval(() => void refresh(), 5000);
    return () => clearInterval(t);
  }, [refresh]);
  useEffect(() => {
    if (window.innerWidth < 1024) setMenu(false);
    window.scrollTo(0, 0);
  }, [loc.pathname]);
  useEffect(() => {
    if (!menu || !isMobile) return;
    const drawer = document.getElementById("workspace-navigation");
    const previous = document.activeElement as HTMLElement | null;
    const controls = () => Array.from(drawer?.querySelectorAll<HTMLElement>('a, button') ?? []);
    controls()[0]?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") { e.preventDefault(); setMenu(false); }
      if (e.key === "Tab") {
        const items = controls(), first = items[0], last = items[items.length - 1];
        if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last?.focus(); }
        if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first?.focus(); }
      }
    };
    document.addEventListener("keydown", onKey);
    const overflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => { document.removeEventListener("keydown", onKey); document.body.style.overflow = overflow; previous?.focus(); };
  }, [menu, isMobile]);
  useEffect(() => {
    if (toast) {
      const t = setTimeout(() => setToast(""), 5000);
      return () => clearTimeout(t);
    }
  }, [toast]);
  const event = async (
    id: string,
    action: string,
    payload: Record<string, unknown> = {},
  ) => {
    await request("/reports/" + id + "/events", { action, ...payload });
    await refresh();
    setToast(
      action === "complete"
        ? "Evidence submitted. Awaiting LGU verification."
        : "Report updated and history recorded.",
    );
  };
  if (!data)
    return (
      <main className="loading">
        <Logo />
        <h1>{error ? "Workspace setup required" : "Opening your workspace…"}</h1>
        <p>{error || "Loading your reports and assignments."}</p>
        <button onClick={() => void refresh()}>
          <RefreshCw size={16} /> Retry
        </button>
        <Link to={base+"/login"}>Return to sign in</Link>
      </main>
    );
  return (
    <Context.Provider value={{ data, refresh, notify: setToast, event }}>
      <a className="skip-link" href="#main">
        Skip to content
      </a>
      <div className={menu ? "shell menu-expanded" : "shell"}>
        <aside id="workspace-navigation" aria-label="Workspace navigation" className={menu ? "sidebar open" : "sidebar"}>
          <button className="icon-button drawer-close" aria-label="Close navigation drawer" onClick={() => setMenu(false)}><X size={20} /></button>
          <Link to={base + "/dashboard"} aria-label="PATAG overview">
            <Logo />
          </Link>
          <div className="workspace">
            <span className="workspace-avatar">{admin ? "LG" : "RC"}</span>
            <div>
              <strong>{admin ? data.settings?.agency || "Bulacan administrator" : data.teams.find(t=>t.id===data.user.teamId)?.name || "Maintenance"}</strong>
              <small>
                {admin ? "City engineering office" : "Maintenance workspace"}
              </small>
            </div>
          </div>
          <nav aria-label="Main navigation">
            {(admin ? [
              ["Overview", ["dashboard", "analytics"]],
              ["Report management", ["reports", "verification", "duplicates", "map"]],
              ["Operations", ["assignments", "completions", "teams"]],
              ["Management", ["users", "exports"]],
              ["System", ["activity"]],
            ] : [
              ["Overview", ["dashboard", "map"]],
              ["Field operations", ["assignments", "progress", "submissions"]],
              ["Records", ["history"]],
            ]).map(([label, paths]) => <Fragment key={String(label)}>
              <p className="nav-label">{String(label)}</p>
              {navigation.filter(([path]) => (paths as string[]).includes(String(path))).map(([path, label, Icon]) => (
                <NavLink key={String(path)} title={String(label)} aria-label={String(label)} to={base + "/" + path}>
                  <Icon size={18} /><span>{String(label)}</span>
                  {path === "verification" && <b>{data.reports.filter(r => ["Submitted", "Under Review"].includes(r.status)).length}</b>}
                </NavLink>
              ))}
            </Fragment>)}
          </nav>
          <div className="nav-bottom">
            <button className="button" onClick={async()=>{try{await request("/auth/logout",{});setData(null);nav(base+"/login",{replace:true});}catch(error){setError((error as Error).message);}}}>Sign out <LogOut size={16}/></button>
            <NavLink title="Profile and settings" aria-label="Profile and settings" to={base + (admin ? "/settings" : "/profile")}>
              <Settings size={18} />
              <span className="nav-text">{admin ? "Settings" : "Profile & settings"}</span>
            </NavLink>
            <div className="user-row">
              <span className="avatar">
                {data.user.name
                  .split(" ")
                  .map((s) => s[0])
                  .slice(0, 2)
                  .join("")}
              </span>
              <div>
                <strong>{data.user.name}</strong>
                <small>
                  {admin ? "LGU administrator" : "Maintenance personnel"}
                </small>
              </div>
            </div>
          </div>
        </aside>
        {menu && <button className="drawer-backdrop" aria-label="Close navigation overlay" onClick={() => setMenu(false)} />}
        <div className="workspace-main">
          <div className="topbar">
            <button
              className="icon-button mobile-menu"
              aria-label={menu ? "Close navigation" : "Open navigation"}
              aria-expanded={menu}
              aria-controls="workspace-navigation"
              onClick={() => { setMenu(!menu); if (window.innerWidth >= 1024) localStorage.setItem("patag-sidebar", menu ? "collapsed" : "expanded"); }}
            >
              {menu ? <X size={22} /> : <Menu size={22} />}
            </button>
            <Link className="topbar-brand" to={base + '/dashboard'} aria-label="PATAG home"><Logo /></Link>
            <nav className="topnav" aria-label="Primary workspace">
              {(admin ? [['dashboard','Overview'],['reports','Reports'],['assignments','Operations'],['users','User management']] : [['dashboard','Overview'],['assignments','My tasks'],['map','Task map'],['history','History']]).map(([path,label])=><NavLink key={path} to={base+'/'+path}>{label}</NavLink>)}
            </nav>
            <span className="workspace-caption">{admin ? (data.settings?.city || 'Malolos') + ' · LGU' : data.teams.find(t=>t.id===data.user.teamId)?.name || 'Maintenance'}</span>
            <button className="icon-button theme-toggle" onClick={toggleTheme} aria-label={theme === "dark" ? "Switch to light mode" : "Switch to dark mode"} title={theme === "dark" ? "Light mode" : "Dark mode"}>
              {theme === "dark" ? <Sun size={19} /> : <Moon size={19} />}
            </button>
            <Link to={base + "/notifications"} className="notification-link" aria-label={"Notifications" + (data.notifications.some(n => !n.read) ? ", unread updates" : "")}>
              <Bell size={18} />
              {localStorage.getItem("patag-notification-preference") !== "off" && data.notifications.some(n => !n.read) && <i className="unread-dot" />}
            </Link>
          </div>
          <main id="main">
            {error && (
              <div className="error" role="alert">
                {error}
                <button onClick={() => void refresh()}>Reconnect</button>
              </div>
            )}
            <RoleBoundary>
              <Routes>
                <Route path="dashboard" element={<Dashboard />} />
                <Route path="reports" element={<ReportList mode="all" />} />
                <Route path="reports/:id" element={<Details />} />
                <Route
                  path="verification"
                  element={<ReportList mode="verification" />}
                />
                <Route
                  path="verification/:id"
                  element={<Details mode="review" />}
                />
                <Route path="duplicates" element={<Duplicates />} />
                <Route path="map" element={<MapPage />} />
                <Route
                  path="assignments"
                  element={<ReportList mode="assignments" />}
                />
                <Route
                  path="assignments/new/:id"
                  element={<Details mode="assign" />}
                />
                <Route path="assignments/:id" element={<Details />} />
                <Route path="teams" element={<Teams />} />
                <Route path="teams/:id" element={<Teams />} />
                <Route path="users" element={<UsersPage />} />
                <Route path="users/:id" element={<UsersPage />} />
                <Route
                  path="completions"
                  element={<ReportList mode="completions" />}
                />
                <Route
                  path="completions/:id"
                  element={<Details mode="completion" />}
                />
                <Route path="analytics" element={<Analytics />} />
                <Route path="exports" element={<Exports />} />
                <Route path="notifications" element={<Notifications />} />
                <Route path="settings" element={<SettingsPage />} />
                <Route path="profile" element={<SettingsPage />} />
                <Route path="activity" element={<Activity />} />
                <Route
                  path="progress"
                  element={<ReportList mode="progress" />}
                />
                <Route
                  path="progress/:id"
                  element={<Details mode="progress" />}
                />
                <Route
                  path="repairs/:id/document"
                  element={<Details mode="document" />}
                />
                <Route
                  path="repairs/:id/submit"
                  element={<Details mode="submit" />}
                />
                <Route path="repairs/:id/success" element={<Success />} />
                <Route
                  path="submissions"
                  element={<ReportList mode="submissions" />}
                />
                <Route path="history" element={<ReportList mode="history" />} />
                <Route
                  path="*"
                  element={
                    <Empty
                      title="Page not found"
                      text="Use the workspace navigation to continue."
                    />
                  }
                />
              </Routes>
            </RoleBoundary>
          </main>
          <footer className="footer">
            PATAG <span>Community reports. Coordinated action.</span>
            <small>PATAG · Bulacan</small>
          </footer>
        </div>
      </div>
      {toast && (
        <div className="toast" role="status">
          <CheckCircle2 size={18} />
          {toast}
          <button
            aria-label="Dismiss notification"
            onClick={() => setToast("")}
          >
            <X size={15} />
          </button>
        </div>
      )}
    </Context.Provider>
  );
}
function Stats({
  reports,
  compact = false,
}: {
  reports: Report[];
  compact?: boolean;
}) {
  const groups = admin
    ? [
        ["Total reports", reports.length],
        [
          "Pending review",
          reports.filter((r) =>
            ["Submitted", "Under Review"].includes(r.status),
          ).length,
        ],
        [
          "In progress",
          reports.filter((r) => r.status === "In Progress").length,
        ],
        ["Resolved", reports.filter((r) => r.status === "Resolved").length],
      ]
    : [
        [
          "Assigned tasks",
          reports.filter((r) => r.status === "Assigned").length,
        ],
        [
          "In progress",
          reports.filter((r) => r.status === "In Progress").length,
        ],
        [
          "Awaiting verification",
          reports.filter((r) => r.completion?.state === "Awaiting Verification")
            .length,
        ],
        ["Resolved", reports.filter((r) => r.status === "Resolved").length],
      ];
  return (
    <div className={"stats " + (compact ? "compact" : "")}>
      {groups.map(([label, n], i) => (
        <div key={label}>
          <span>{label}</span>
          <strong>{String(n)}</strong>
          <small>
            {admin
              ? i === 0
                ? "Current workspace"
                : i === 1
                  ? "Needs attention"
                  : i === 2
                    ? "Roads under repair"
                    : "LGU verified repairs"
              : i === 0
                ? "Ready to start"
                : i === 1
                  ? "Inspection or repair underway"
                  : i === 2
                    ? "Awaiting LGU decision"
                    : "LGU verified repairs"}
          </small>
        </div>
      ))}
    </div>
  );
}
function Chart({
  reports,
  kind = "status",
}: {
  reports: Report[];
  kind?: string;
}) {
  const groups =
    kind === "severity"
      ? ["High", "Medium", "Low"]
      : kind === "area"
        ? [...new Set(reports.map((r) => r.location.barangay))]
        : kind === "time"
          ? reportDates(reports)
          : statuses;
  const series = groups.map((name) => ({
    name: name,
    total: reports.filter((r) =>
      kind === "time"
        ? r.createdAt.slice(0, 10) === name
        : kind === "area"
          ? r.location.barangay === name
          : kind === "severity"
            ? r.severity === name
            : r.status === name,
    ).length,
  }));
  return (
    <div
      className="chart"
      role="img"
      aria-label={`Reports by ${kind}: ${series.map((x) => x.name + " " + x.total).join(", ")}`}
    >
      <ResponsiveContainer width="100%" height={180}>
        <BarChart
          data={series}
          margin={{ top: 12, right: 8, left: -26, bottom: 0 }}
        >
          <CartesianGrid vertical={false} stroke="var(--line)" />
          <XAxis
            dataKey="name"
            tick={{ fontSize: 11, fill: "var(--slate)" }}
            axisLine={false}
            tickLine={false}
            interval="preserveStartEnd"
            minTickGap={18}
          />
          <YAxis tick={{ fill: "var(--slate)", fontSize: 11 }} allowDecimals={false} axisLine={false} tickLine={false} />
          <Tooltip cursor={{ fill: "var(--raised)" }} contentStyle={{ background: "var(--surface)", borderColor: "var(--line)", color: "var(--ink)", borderRadius: 12 }} />
          <Bar
            isAnimationActive={false}
            dataKey="total"
            name="Reports"
            fill="#F26A32"
            maxBarSize={26}
            radius={[3, 3, 0, 0]}
          />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
function Recenter({ reports }: { reports: Report[] }) {
  const m = useMap();
  useEffect(() => {
    const observer = new ResizeObserver(() => m.invalidateSize({ pan: false }));
    observer.observe(m.getContainer());
    return () => observer.disconnect();
  }, [m]);
  return (
    <button
      className="map-recenter"
      onClick={() => {
        if (reports.length)
          m.setView(
            [
              reports[0].location.coordinates.lat,
              reports[0].location.coordinates.lng,
            ],
            14,
          );
      }}
      aria-label="Recenter report map"
    >
      <Navigation size={16} />
    </button>
  );
}
function ReportMap({
  reports,
  height = 300,
}: {
  reports: Report[];
  height?: number;
}) {
  const [tileError, setTileError] = useState(false);
  const map = mapSettings(import.meta.env.VITE_MAPBOX_TOKEN);
  const markers = reports.filter(r => validCoordinates(r.location.coordinates));
  return (
    <div className="map-wrapper" style={{ height }}>
      <MapContainer
        center={[14.855, 120.815]}
        zoom={13}
        scrollWheelZoom={false}
        style={{ height: "100%", width: "100%" }}
      >
        {map.url && !tileError && <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://www.mapbox.com/about/maps/">Mapbox</a> <a href="https://apps.mapbox.com/feedback/">Improve this map</a>'
          url={map.url}
          eventHandlers={{ tileerror: () => setTileError(true) }}
        />}
        {markers.map((r) => (
          <CircleMarker
            key={r.id}
            center={[r.location.coordinates.lat, r.location.coordinates.lng]}
            radius={r.severity === "High" ? 9 : 7}
            pathOptions={{
              color: "white",
              weight: 2,
              fillColor:
                r.status === "Resolved"
                  ? "#247b50"
                  : r.severity === "High"
                    ? "#b6471c"
                    : "#182B49",
              fillOpacity: 1,
            }}
          >
            <Popup>
              <strong>{r.location.road}</strong>
              <p>
                {r.id} · {r.status}
                <br />
                {r.severity} severity
              </p>
              <Link to={base + (admin ? "/reports/" : "/assignments/") + r.id}>
                View {admin ? "report" : "task"}
              </Link>
            </Popup>
          </CircleMarker>
        ))}
        <Recenter reports={markers} />
      </MapContainer>
      {(!map.url || tileError) && (
        <span className="tile-error">
          {map.message || "Mapbox tiles unavailable. Check the token and URL restrictions. Coordinates and report list remain available."}
        </span>
      )}
    </div>
  );
}
function SmallReports({ reports }: { reports: Report[] }) {
  return reports.length ? (
    <div className="small-reports">
      {reports.map((r) => (
        <Link
          className="report-row"
          key={r.id}
          to={base + (admin ? "/reports/" : "/assignments/") + r.id}
        >
          <img
            src={r.photos[0] ? asset(r.photos[0].url) : undefined}
            alt="Report evidence"
          />
          <div>
            <strong>{r.location.road}</strong>
            <small>
              {r.location.barangay} · {r.id}
            </small>
          </div>
          <Badge value={r.severity} />
          <ArrowUpRight size={17} />
        </Link>
      ))}
    </div>
  ) : (
    <Empty
      title="You're all caught up"
      text="No reports need action in this queue."
    />
  );
}
function Dashboard() {
  const {data}=useData();
  const rs=data.reports;
  const pending=rs.filter(r=>admin?['Submitted','Under Review'].includes(r.status):['Assigned','In Progress'].includes(r.status));
  const high=rs.filter(r=>r.severity==='High'&&!['Resolved','Rejected','Duplicate'].includes(r.status));
  const awaiting=rs.filter(r=>r.completion?.state==='Awaiting Verification');
  const verified=rs.filter(r=>r.status==='Verified');
  const resolved=rs.filter(r=>r.status==='Resolved').length;
  const working=rs.filter(r=>r.status==='In Progress').length;
  const next=[...pending].sort((a,b)=>Number(b.severity==='High')-Number(a.severity==='High'))[0];
  const metricRows=admin?[['Pending review',pending.length,'verification'],['In progress',working,'reports?status=In%20Progress'],['Resolved',resolved,'reports?status=Resolved']]:[['Assigned',rs.filter(r=>r.status==='Assigned').length,'assignments'],['In progress',working,'progress'],['Awaiting review',awaiting.length,'submissions']];
  return <div className={'premium-overview '+(admin?'admin-overview':'crew-overview')}>
    <Header title={admin?'Roads overview':'Your day on the road'} description={admin?pending.length+' reports need your review. Let’s keep Malolos moving.':pending.length+' active tasks. Clear priorities for your next repair.'} action={<Link className="primary" to={base+(admin?'/verification':'/assignments')}>{admin?'Review reports':'View my tasks'}<ArrowUpRight size={17}/></Link>}/>
    <section className="overview-summary" aria-label="Report summary">
      <Link className="summary-lead" to={base+(admin?'/reports':'/history')}><span>{admin?'Community reports':'Verified repairs'}</span><div><strong>{admin?rs.length:resolved}</strong><ArrowUpRight size={23}/></div><small>{admin?'Every tag is a road toward change.':'Completed and confirmed by the LGU.'}</small></Link>
      {metricRows.map(([label,value,route])=><Link className="summary-metric" key={label} to={base+'/'+route}><span>{label}</span><strong>{value}</strong><small>View {String(label).toLowerCase()}<ArrowUpRight size={14}/></small></Link>)}
    </section>
    <div className="operations-grid">
      <Panel title={admin?'The action desk':'Your next task'} aside={<span className="count">{pending.length} active</span>} className={admin?'action-desk':'next-task-panel'}>
        {admin?<><div className="action-shortcuts"><Link to={base+'/verification'}><span>Verify reports</span><strong>{pending.length}</strong><ArrowRight size={17}/></Link><Link to={base+'/assignments'}><span>Ready for a crew</span><strong>{verified.length}</strong><ArrowRight size={17}/></Link><Link to={base+'/completions'}><span>Approve repairs</span><strong>{awaiting.length}</strong><ArrowRight size={17}/></Link></div><SmallReports reports={pending.slice(0,2)}/></>:next?<div className="next-task"><div className="next-task-heading"><Badge value={next.severity}/><span>{next.id}</span></div><h2>{next.location.road}</h2><p><MapPin size={16}/>Brgy. {next.location.barangay}, {next.location.city}</p><div className="next-task-status"><Badge value={next.status}/><span>Assigned to your crew</span></div><Link className="primary" to={base+'/assignments/'+next.id}>Open task<ArrowUpRight size={17}/></Link></div>:<Empty title="All clear for now" text="Your next assigned repair will appear here."/>}
      </Panel>
      <Panel title={admin?'Road conditions':'Your repair locations'} aside={<Link to={base+'/map'}>Open map<ArrowUpRight size={14}/></Link>} className="overview-map"><ReportMap reports={admin?rs:pending} height={235}/><div className="map-legend"><span><i className="navy-dot"/>Reported</span><span><i className="orange-dot"/>High severity</span><span><i className="green-dot"/>Resolved</span></div></Panel>
      <Panel title="Reports over time" aside={<span className="muted">Authorized reports</span>} className="overview-trend"><Chart reports={rs} kind="time"/></Panel>
      <Panel title={admin?'Priority roads':'Up next'} aside={<Link to={base+(admin?'/reports?severity=High':'/assignments')}>View all<ArrowUpRight size={14}/></Link>} className="overview-priority"><SmallReports reports={(admin?high:pending.filter(r=>r.id!==next?.id)).slice(0,2)}/></Panel>
    </div>
    <section className="road-progress"><div><h2>From a tag to a better road</h2><p>Every stage, accounted for.</p></div><div className="progress-stages">{['Submitted','Under Review','Verified','Assigned','In Progress','Resolved'].map(s=><Link key={s} to={base+(admin?'/reports?status='+encodeURIComponent(s):'/assignments')}><strong>{rs.filter(r=>r.status===s).length}</strong><span>{s}</span></Link>)}</div></section>
  </div>;
}
function ReportList({ mode }: { mode: string }) {
  const route = useLocation();
  const { data } = useData();
  const [q, setQ] = useState(""),
    [status, setStatus] = useState(
      new URLSearchParams(route.search).get("status") || "All",
    ),
    [severity, setSeverity] = useState(new URLSearchParams(route.search).get("severity") || "All"),
    [area, setArea] = useState("All"),
    [team, setTeam] = useState("All"),
    [sort, setSort] = useState("newest"),
    [from, setFrom] = useState(""),
    [to, setTo] = useState(""),
    [page, setPage] = useState(1);
  const title: Record<string, string> = {
    all: "All reports",
    verification: "Verification queue",
    assignments: admin ? "Assignment management" : "My assignments",
    completions: "Repair verification",
    progress: "Repairs in progress",
    submissions: "Completion submissions",
    history: "Repair history",
  };
  const source = data.reports.filter((r) =>
    mode === "verification"
      ? ["Submitted", "Under Review"].includes(r.status)
      : mode === "assignments"
        ? admin
          ? ["Verified", "Assigned", "In Progress"].includes(r.status)
          : Boolean(r.teamId)
        : mode === "completions"
          ? r.completion?.state === "Awaiting Verification"
          : mode === "progress"
            ? r.status === "In Progress"
            : mode === "submissions"
              ? Boolean(r.completion)
              : mode === "history"
                ? r.status === "Resolved"
                : true,
  );
  let rows = source
    .filter(
      (r) =>
        (r.id + " " + r.location.road + " " + r.location.barangay)
          .toLowerCase()
          .includes(q.toLowerCase()) &&
        (status === "All" || r.status === status) &&
        (severity === "All" || r.severity === severity) &&
        (area === "All" || r.location.barangay === area) &&
        (team === "All" || r.teamId === team) &&
        (!from || r.createdAt.slice(0, 10) >= from) &&
        (!to || r.createdAt.slice(0, 10) <= to),
    )
    .sort((a, b) =>
      sort === "road"
        ? a.location.road.localeCompare(b.location.road)
        : sort === "oldest"
          ? a.createdAt.localeCompare(b.createdAt)
          : b.createdAt.localeCompare(a.createdAt),
    );
  const pages = Math.max(1, Math.ceil(rows.length / 8));
  const current = Math.min(page, pages);
  const link = (r: Report) =>
    base +
    (admin
      ? mode === "verification"
        ? "/verification/"
        : mode === "completions"
          ? "/completions/"
          : mode === "assignments" && r.status === "Verified"
            ? "/assignments/new/"
            : "/reports/"
      : mode === "progress"
        ? "/progress/"
        : "/assignments/") +
    r.id;
  return (
    <>
      <Header
        title={title[mode] || "Reports"}
        description={`${source.length} ${admin ? "community reports" : "crew tasks"} · Evidence and progress in one place.`}
      />
      <div className="filters">
        <label className="search">
          <Search size={16} />
          <input
            aria-label="Search reports"
            placeholder="Search road, barangay or reference…"
            value={q}
            onChange={(e) => {
              setQ(e.target.value);
              setPage(1);
            }}
          />
        </label>
        <select
          aria-label="Status filter"
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(1);
          }}
        >
          <option value="All">All statuses</option>
          {statuses.map((s) => (
            <option key={s}>{s}</option>
          ))}
        </select>
        <select
          aria-label="Severity filter"
          value={severity}
          onChange={(e) => {
            setSeverity(e.target.value);
            setPage(1);
          }}
        >
          <option value="All">All severities</option>
          {["High", "Medium", "Low"].map((s) => (
            <option key={s}>{s}</option>
          ))}
        </select>
        <select
          aria-label="Barangay filter"
          value={area}
          onChange={(e) => setArea(e.target.value)}
        >
          <option value="All">All barangays</option>
          {[...new Set(source.map((r) => r.location.barangay))].map((s) => (
            <option key={s}>{s}</option>
          ))}
        </select>
        <select
          aria-label="Team filter"
          value={team}
          onChange={(e) => setTeam(e.target.value)}
        >
          <option value="All">All teams</option>
          {data.teams.map((t) => (
            <option key={t.id} value={t.id}>
              {t.name}
            </option>
          ))}
        </select>
        <select
          aria-label="Sort reports"
          value={sort}
          onChange={(e) => setSort(e.target.value)}
        >
          <option value="newest">Newest first</option>
          <option value="oldest">Oldest first</option>
          <option value="road">Road A–Z</option>
        </select>
        <label className="inline-label">
          From
          <input
            aria-label="From date"
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
          />
        </label>
        <label className="inline-label">
          To
          <input
            aria-label="To date"
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
          />
        </label>
        <button
          className="text-button"
          onClick={() => {
            setQ("");
            setStatus("All");
            setSeverity("All");
            setArea("All");
            setTeam("All");
            setFrom("");
            setTo("");
          }}
        >
          Reset
        </button>
      </div>
      <section className="panel report-table">
        <div className="panel-title">
          <h2>
            {rows.length} matching {admin ? "reports" : "tasks"}
          </h2>
          <span className="muted">Supabase workspace</span>
        </div>
        {rows.length ? (
          <>
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>Report & location</th>
                    <th>Severity</th>
                    <th>Status</th>
                    <th>Assigned team</th>
                    <th className="numeric">Submitted</th>
                    <th>
                      <span className="sr-only">Action</span>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {rows.slice((current - 1) * 8, current * 8).map((r) => (
                    <tr key={r.id}>
                      <td>
                        <Link className="table-identity" to={link(r)}>
                          <img
                            src={asset(r.photos[0]?.url)}
                            alt="Evidence preview"
                          />
                          <span>
                            <strong>{r.location.road}</strong>
                            <small>
                              {r.id} · Brgy. {r.location.barangay}
                            </small>
                          </span>
                        </Link>
                      </td>
                      <td>
                        <Badge value={r.severity} />
                      </td>
                      <td>
                        <Badge value={r.status} />
                        {r.completion?.state === "Awaiting Verification" && (
                          <small className="sub-state">
                            Awaiting verification
                          </small>
                        )}
                      </td>
                      <td>
                        {data.teams.find((t) => t.id === r.teamId)?.name ||
                          "Unassigned"}
                      </td>
                      <td className="numeric">{date(r.createdAt)}</td>
                      <td>
                        <Link className="row-action" to={link(r)}>
                          {mode === "verification"
                            ? "Review"
                            : mode === "assignments" && r.status === "Verified"
                              ? "Assign"
                              : "View"}
                          <ArrowUpRight size={15} />
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="pagination">
              <span>
                {(current - 1) * 8 + 1}–{Math.min(current * 8, rows.length)} of{" "}
                {rows.length}
              </span>
              <button
                disabled={current === 1}
                onClick={() => setPage(current - 1)}
                aria-label="Previous page"
              >
                <ArrowLeft size={15} />
              </button>
              <span>
                Page {current} of {pages}
              </span>
              <button
                disabled={current === pages}
                onClick={() => setPage(current + 1)}
                aria-label="Next page"
              >
                <ArrowRight size={15} />
              </button>
            </div>
          </>
        ) : (
          <Empty
            title="No matching reports"
            text="Try another search or reset the filters."
          />
        )}
      </section>
    </>
  );
}
function Gallery({ photos, label }: { photos: Photo[]; label: string }) {
  return (
    <div className="gallery">
      {photos.map((p) => (
        <a key={p.id} href={asset(p.url)} target="_blank" rel="noreferrer">
          <img
            src={asset(p.url)}
            alt={label + (p.demo ? " — illustrated demo" : "")}
          />
          <span>
            {p.demo ? "Illustrated demo" : label}
            <ArrowUpRight size={14} />
          </span>
        </a>
      ))}
      {!photos.length && (
        <p className="muted">No {label.toLowerCase()} submitted.</p>
      )}
    </div>
  );
}
function Details({ mode = "detail" }: { mode?: string }) {
  const { id } = useParams();
  const { data, event, notify } = useData();
  const navigate = useNavigate();
  const r = data.reports.find((r) => r.id === id);
  const [decision, setDecision] = useState(""),
    [error, setError] = useState(""),
    [busy, setBusy] = useState(false),
    [photos, setPhotos] = useState<Photo[]>(() =>
      JSON.parse(sessionStorage.getItem("repair-photos-" + id) || "[]"),
    ),
    [notes, setNotes] = useState(
      () => sessionStorage.getItem("repair-notes-" + id) || "",
    ),
    [nearby, setNearby] = useState<{ report: Report; distance: number }[]>([]);
  useEffect(() => {
    if (r)
      void request<{ report: Report; distance: number }[]>("/duplicates", {id:r.id})
        .then(setNearby)
        .catch(() => setNearby([]));
  }, [r]);
  if (!r)
    return (
      <Empty
        title="Report not found"
        text="It may belong to another team or account."
      />
    );
  const c = r.location.coordinates;
  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setBusy(true);
    setError("");
    const f = new FormData(e.currentTarget);
    try {
      await event(r.id, decision, Object.fromEntries(f.entries()));
      setDecision("");
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  };
  const direct = async (
    action: string,
    payload: Record<string, unknown> = {},
  ) => {
    setBusy(true);
    setError("");
    try {
      await event(r.id, action, payload);
      if (action === "complete") {
        sessionStorage.removeItem("repair-photos-" + id);
        sessionStorage.removeItem("repair-notes-" + id);
        navigate(base + "/repairs/" + id + "/success");
      }
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  };
  const pickBefore = async (files: FileList | null) => {
    if (!files?.length) return;
    setBusy(true);
    setError("");
    try {
      const evidence: Photo[] = [];
      for (const file of Array.from(files)) evidence.push(await upload(file, "before"));
      await event(r.id, "before-photos", { photos: evidence, note: "Maintenance before-repair evidence added." });
      notify("Before-repair evidence saved.");
    } catch (error) {
      setError((error as Error).message);
    } finally { setBusy(false); }
  };
  const pick = async (files: FileList | null) => {
    if (!files) return;
    setBusy(true);
    setError("");
    try {
      const next = [...photos];
      for (const f of Array.from(files)) next.push(await upload(f));
      setPhotos(next);
      sessionStorage.setItem("repair-photos-" + id, JSON.stringify(next));
      notify("Photo uploaded. Repair draft saved.");
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  };
  return (
    <>
      <Link
        className="back-link"
        to={base + (admin ? "/reports" : "/assignments")}
      >
        <ArrowLeft size={15} /> {admin ? "All reports" : "My assignments"}
      </Link>
      <Header
        title={
          mode === "review"
            ? "Review the report"
            : mode === "assign"
              ? "Assign a maintenance team"
              : mode === "completion"
                ? "Verify completed repair"
                : mode === "document"
                  ? "Document the repair"
                  : mode === "submit"
                    ? "Review completion evidence"
                    : r.location.road
        }
        description={`${r.id} · Brgy. ${r.location.barangay}, ${r.location.city}`}
        action={<Badge value={r.status} />}
      />
      {error && (
        <div className="error" role="alert">
          {error}
        </div>
      )}
      <div className="detail-grid">
        <div>
          <Panel
            title={
              mode === "completion" ? "Before repair" : "Submitted evidence"
            }
            aside={<Badge value={r.severity} />}
          >
            <Gallery photos={r.photos} label="Before repair" />
            {admin && <div className="notice" style={{display:"block"}}>
              <strong>Public photo visibility</strong>
              <p>Review all before-and-after images for faces, plates and personal details before allowing them on the community map. New evidence requires a new review.</p>
              <button className="button" disabled={busy} onClick={() => void direct("publication",{approved:!r.publicPhotosApproved,note:r.publicPhotosApproved?"Public photos hidden.":"Photos reviewed and approved for public display."})}>{r.publicPhotosApproved ? "Hide public photos" : "Approve public photos"}</button>
            </div>}
            {!admin && ["Assigned", "In Progress"].includes(r.status) && r.completion?.state !== "Awaiting Verification" && (
              <label className="upload">
                <Camera size={20} />
                <strong>Add before-repair photos</strong>
                <span>Document the site before work. Original citizen evidence is kept.</span>
                <input type="file" accept="image/png,image/jpeg,image/webp" multiple disabled={busy} aria-label="Before-repair photos" onChange={(e) => { void pickBefore(e.target.files); e.target.value = ""; }} />
              </label>
            )}
            <h3>{r.title}</h3>
            <p>{r.description}</p>
            <dl className="detail-list">
              <div>
                <dt>Observed hazards</dt>
                <dd>{r.hazards || "None stated"}</dd>
              </div>
              <div>
                <dt>Nearby landmark</dt>
                <dd>{r.location.landmark || "Not specified"}</dd>
              </div>
              <div>
                <dt>Responsible agency</dt>
                <dd>{r.jurisdiction}</dd>
              </div>
              <div>
                <dt>Submitted</dt>
                <dd>{date(r.createdAt)}</dd>
              </div>
              {admin && (
                <div>
                  <dt>Reporter reference</dt>
                  <dd>{r.reporterId}</dd>
                </div>
              )}
            </dl>
          </Panel>
          {r.completion && (
            <Panel
              title="After repair"
              aside={<Badge value={r.completion.state} />}
            >
              <Gallery photos={r.completion.photos} label="After repair" />
              <p>{r.completion.note}</p>
              <small className="muted">Submitted {date(r.completion.at)}</small>
            </Panel>
          )}
          {!admin && ["progress", "document", "submit"].includes(mode) && (
            <Panel
              title={
                mode === "progress" ? "Repair progress" : "Repair documentation"
              }
            >
              <p>
                Completion remains In Progress until the LGU verifies the
                repair.
              </p>
              <label>
                Work performed / progress notes
                <textarea
                  rows={4}
                  value={notes}
                  onChange={(e) => {
                    setNotes(e.target.value);
                    sessionStorage.setItem(
                      "repair-notes-" + id,
                      e.target.value,
                    );
                  }}
                  placeholder="Describe the inspection, materials and work completed."
                />
              </label>
              {mode !== "progress" && (
                <>
                  <label className="upload">
                    <Camera size={22} />
                    <strong>Add after-repair photos</strong>
                    <span>PNG, JPEG or WebP · up to 8 MB per photo</span>
                    <input
                      aria-label="After-repair photos"
                      type="file"
                      accept="image/png,image/jpeg,image/webp"
                      multiple
                      onChange={(e) => void pick(e.target.files)}
                    />
                  </label>
                  <Gallery photos={photos} label="Draft after repair" />
                  {photos.map((p) => (
                    <button
                      className="text-button"
                      key={p.id}
                      onClick={() => {
                        const next = photos.filter((x) => x.id !== p.id);
                        setPhotos(next);
                        sessionStorage.setItem(
                          "repair-photos-" + id,
                          JSON.stringify(next),
                        );
                      }}
                    >
                      Remove {p.name}
                    </button>
                  ))}
                </>
              )}
              {mode === "progress" ? (
                <button
                  className="primary"
                  disabled={busy || !notes.trim()}
                  onClick={() =>
                    void direct("progress", { note: notes, phase: "Repair" })
                  }
                >
                  Save progress
                  <Check size={16} />
                </button>
              ) : mode === "document" ? (
                <Link
                  className="primary"
                  to={base + "/repairs/" + r.id + "/submit"}
                >
                  Review completion
                  <ArrowRight size={16} />
                </Link>
              ) : (
                <>
                  <p className="notice">
                    <ShieldCheck size={18} /> Confirm that these photos show
                    this road after repair. The LGU will review all evidence.
                  </p>
                  <button
                    className="primary"
                    disabled={
                      busy ||
                      !notes.trim() ||
                      !photos.length ||
                      r.completion?.state === "Awaiting Verification" ||
                      r.status !== "In Progress"
                    }
                    onClick={() =>
                      void direct("complete", { note: notes, photos })
                    }
                  >
                    Submit for administrative verification
                    <ArrowRight size={16} />
                  </button>
                  <Link
                    className="back-link"
                    to={base + "/repairs/" + id + "/document"}
                  >
                    Back to edit
                  </Link>
                </>
              )}
            </Panel>
          )}
          <Panel title="Report timeline">
            <ol className="timeline">
              {r.history
                .slice()
                .reverse()
                .map((h) => (
                  <li key={h.id}>
                    <span className="timeline-dot" />
                    <div>
                      <strong>
                        {h.action === "complete"
                          ? "Completion submitted for verification"
                          : h.action === "return"
                            ? "Additional work requested"
                            : h.to}
                      </strong>
                      <p>{h.note || h.action}</p>
                      <small>
                        {date(h.at)} · {h.actor}
                      </small>
                    </div>
                  </li>
                ))}
            </ol>
            {r.updates.map((u, i) => (
              <p key={i}>
                <strong>{u.phase}</strong> · {u.note}{" "}
                <small>{date(u.at)}</small>
              </p>
            ))}
          </Panel>
        </div>
        <div>
          <Panel title="Location">
            <ReportMap reports={[r]} height={260} />
            <div className="location-detail">
              <MapPin size={18} />
              <div>
                <strong>{r.location.road}</strong>
                <p>
                  Brgy. {r.location.barangay}, {r.location.city},{" "}
                  {r.location.province}
                </p>
                <small>
                  {c.lat.toFixed(6)}, {c.lng.toFixed(6)}
                </small>
              </div>
            </div>
            <a
              className="external-link"
              href={`https://www.google.com/maps/dir/?api=1&destination=${c.lat},${c.lng}`}
              target="_blank"
              rel="noreferrer"
            >
              <Navigation size={16} />
              Open map navigation
              <ArrowUpRight size={15} />
            </a>
          </Panel>
          <Panel title={admin ? "Next action" : "Your task"}>
            <div className="action-stack">
              {admin ? (
                <>
                  {["Submitted", "Under Review"].includes(r.status) && (
                    <>
                      <p>
                        Check the photo, pinned location and reported severity
                        before deciding.
                      </p>
                      <button
                        className="primary"
                        onClick={() => setDecision("verify")}
                      >
                        Verify report
                        <ShieldCheck size={16} />
                      </button>
                      {r.status === "Submitted" && (
                        <button onClick={() => setDecision("review")}>
                          Move to Under Review
                        </button>
                      )}
                      <button onClick={() => setDecision("flag")}>
                        Flag for follow-up
                      </button>
                      <button onClick={() => setDecision("duplicate")}>
                        Confirm duplicate
                      </button>
                      <button
                        className="danger-button"
                        onClick={() => setDecision("reject")}
                      >
                        Reject with reason
                      </button>
                    </>
                  )}
                  {r.status === "Verified" && (
                    <button
                      className="primary"
                      onClick={() => setDecision("assign")}
                    >
                      Assign maintenance team
                      <Truck size={16} />
                    </button>
                  )}
                  {r.completion?.state === "Awaiting Verification" && (
                    <>
                      <p>
                        Compare before-and-after evidence and the repair notes.
                      </p>
                      <button
                        className="primary"
                        onClick={() => setDecision("resolve")}
                      >
                        Confirm resolution
                        <CheckCircle2 size={16} />
                      </button>
                      <button onClick={() => setDecision("return")}>
                        Request additional work
                      </button>
                    </>
                  )}
                  <button onClick={() => setDecision("forward")}>
                    Forward to responsible agency
                  </button>
                </>
              ) : (
                <>
                  {r.status === "Assigned" && (
                    <button
                      className="primary"
                      disabled={busy}
                      onClick={() => setDecision("start")}
                    >
                      Start inspection / repair
                      <Truck size={16} />
                    </button>
                  )}
                  {r.status === "In Progress" &&
                    r.completion?.state !== "Awaiting Verification" && (
                      <>
                        <Link
                          className="primary"
                          to={base + "/progress/" + r.id}
                        >
                          Update progress
                          <ArrowRight size={16} />
                        </Link>
                        <Link
                          className="button"
                          to={base + "/repairs/" + r.id + "/document"}
                        >
                          Upload repair evidence
                          <Camera size={16} />
                        </Link>
                      </>
                    )}
                  {r.completion?.state === "Awaiting Verification" && (
                    <p className="notice">
                      <Clock size={18} />
                      Awaiting LGU verification. Your work is submitted; this
                      case is not yet resolved.
                    </p>
                  )}
                </>
              )}
              {r.status === "Resolved" && (
                <p className="notice">
                  <CheckCircle2 size={18} />
                  Repair verified by the LGU. The reporter can now give
                  feedback.
                </p>
              )}
            </div>
          </Panel>
          {r.assignment && (
            <Panel title="Assigned crew">
              <strong>{data.teams.find((t) => t.id === r.teamId)?.name}</strong>
              <p>{r.assignment.note || "No additional instructions."}</p>
              <small className="muted">
                Target: {r.assignment.targetDate || "Not set"} · Priority:{" "}
                {r.assignment.priority}
              </small>
            </Panel>
          )}
          {admin && (
            <Panel title="Possible duplicates">
              {nearby.length ? (
                nearby.map((x) => (
                  <Link
                    className="duplicate-link"
                    key={x.report.id}
                    to={base + "/reports/" + x.report.id}
                  >
                    <strong>{x.report.id}</strong>
                    <span>
                      {x.distance} m away · {x.report.location.road}
                    </span>
                    <ArrowUpRight size={15} />
                  </Link>
                ))
              ) : (
                <p className="muted">
                  No similar active reports within 150 m on this road.
                </p>
              )}
              <small className="muted">
                Suggestions require a human decision.
              </small>
            </Panel>
          )}
        </div>
      </div>
      {decision && (
        <Modal
          title={
            {
              verify: "Verify this report?",
              reject: "Reject report",
              duplicate: "Confirm duplicate",
              flag: "Flag for follow-up",
              review: "Begin review",
              assign: "Assign maintenance team",
              resolve: "Confirm road repair?",
              return: "Request additional work",
              forward: "Forward to agency",
              start: "Start inspection / repair?",
            }[decision] || decision
          }
          close={() => setDecision("")}
        >
          <form onSubmit={submit}>
            <p>
              {decision === "resolve"
                ? "Confirm that the road repair is complete and evidence is sufficient. This will notify the reporter."
                : `Report ${r.id} · ${r.location.road}`}
            </p>
            {decision === "assign" && (
              <>
                <label>
                  Maintenance team
                  <select name="teamId" required>
                    <option value="">Select a team</option>
                    {data.teams
                      .filter((t) => t.active)
                      .map((t) => (
                        <option key={t.id} value={t.id}>
                          {t.name} ·{" "}
                          {
                            data.reports.filter(
                              (x) =>
                                x.teamId === t.id &&
                                !["Resolved", "Rejected", "Duplicate"].includes(
                                  x.status,
                                ),
                            ).length
                          }{" "}
                          open tasks
                        </option>
                      ))}
                  </select>
                </label>
                <label>
                  Priority
                  <select name="priority" defaultValue={r.severity}>
                    <option>High</option>
                    <option>Medium</option>
                    <option>Low</option>
                  </select>
                </label>
                <label>
                  Target date
                  <input
                    type="date"
                    name="targetDate"
                    min={new Date().toISOString().slice(0, 10)}
                  />
                </label>
              </>
            )}
            {decision === "duplicate" && (
              <label>
                Original report
                <select name="duplicateOf" required>
                  <option value="">Select the original report</option>
                  {data.reports
                    .filter(
                      (x) =>
                        x.id !== r.id &&
                        !["Rejected", "Duplicate"].includes(x.status),
                    )
                    .map((x) => (
                      <option key={x.id} value={x.id}>
                        {x.id} · {x.location.road}
                      </option>
                    ))}
                </select>
              </label>
            )}
            {decision === "forward" && (
              <label>
                Responsible agency
                <input
                  name="jurisdiction"
                  required
                  placeholder="Agency or jurisdiction name"
                />
              </label>
            )}
            <label>
              {["reject", "return", "flag"].includes(decision)
                ? "Reason / instructions (required)"
                : "Review / assignment notes"}
              <textarea
                name="note"
                required={["reject", "return", "flag"].includes(decision)}
                rows={3}
              />
            </label>
            {error && (
              <p className="error" role="alert">
                {error}
              </p>
            )}
            <div className="dialog-actions">
              <button type="button" onClick={() => setDecision("")}>
                Cancel
              </button>
              <button className="primary" disabled={busy}>
                {busy
                  ? "Saving…"
                  : "Confirm " +
                    (decision === "resolve" ? "resolution" : decision)}
              </button>
            </div>
          </form>
        </Modal>
      )}
    </>
  );
}
function MapPage() {
  const { data } = useData();
  const [severity, setSeverity] = useState("All"),
    [status, setStatus] = useState("All"),
    [area, setArea] = useState("All");
  const rs = data.reports.filter(
    (r) =>
      (severity === "All" || r.severity === severity) &&
      (status === "All" || r.status === status) &&
      (area === "All" || r.location.barangay === area),
  );
  return (
    <>
      <Header
        title={admin ? "Pothole map" : "Assigned task map"}
        description={`${rs.length} reports on the map · Bulacan · authorized report locations`}
      />
      <div className="filters">
        <select
          aria-label="Severity filter"
          value={severity}
          onChange={(e) => setSeverity(e.target.value)}
        >
          <option value="All">All severities</option>
          {["High", "Medium", "Low"].map((s) => (
            <option key={s}>{s}</option>
          ))}
        </select>
        <select
          aria-label="Status filter"
          value={status}
          onChange={(e) => setStatus(e.target.value)}
        >
          <option value="All">All statuses</option>
          {statuses.map((s) => (
            <option key={s}>{s}</option>
          ))}
        </select>
        <select
          aria-label="Barangay filter"
          value={area}
          onChange={(e) => setArea(e.target.value)}
        >
          <option value="All">All barangays</option>
          {[...new Set(data.reports.map((r) => r.location.barangay))].map(
            (s) => (
              <option key={s}>{s}</option>
            ),
          )}
        </select>
        <button
          onClick={() => {
            setSeverity("All");
            setStatus("All");
            setArea("All");
          }}
        >
          Reset filters
        </button>
      </div>
      <div className="map-layout">
        <ReportMap reports={rs} height={560} />
        <Panel title="Reports in view">
          {rs.length ? (
            <SmallReports reports={rs} />
          ) : (
            <Empty title="No matching roads" />
          )}
        </Panel>
      </div>
    </>
  );
}
function Duplicates() {
  const { data } = useData();
  const [pairsError,setPairsError]=useState("");
  const [pairs, setPairs] = useState<
    { a: Report; b: Report; distance: number }[]
  >([]);
  useEffect(() => {
    void request<{a:string;b:string;distance:number}[]>("/duplicates?limit=50")
      .then(list => {setPairsError("");setPairs(list.flatMap(pair => {
        const a=data.reports.find(r=>r.id===pair.a),b=data.reports.find(r=>r.id===pair.b);
        return a&&b?[{a,b,distance:pair.distance}]:[];
      }));})
      .catch(error=>setPairsError((error as Error).message));
  }, [data.reports]);
  return (
    <>
      <Header
        title="Possible duplicates"
        description="Same road, within 150 metres. Compare evidence before confirming a duplicate."
      />
      <p>Showing up to 50 authorized candidate pairs. Suggestions require administrative confirmation.</p>
      {pairsError && <p role="alert" className="error">{pairsError}</p>}
      {pairs.length ? (
        pairs.map(({ a, b, distance }) => (
          <section className="panel duplicate-pair" key={a.id + b.id}>
            <div className="panel-title">
              <h2>
                {distance} m apart · {a.location.road}
              </h2>
              <Badge value="Possible duplicate" />
            </div>
            <div className="two-columns">
              {[a, b].map((r) => (
                <div key={r.id}>
                  <Gallery photos={r.photos} label="Report evidence" />
                  <h3>{r.id}</h3>
                  <p>{r.description}</p>
                  <p className="muted">
                    {date(r.createdAt)} · {r.location.coordinates.lat},{" "}
                    {r.location.coordinates.lng}
                  </p>
                  <Link className="button" to={base + "/verification/" + r.id}>
                    Compare & review
                    <ArrowUpRight size={16} />
                  </Link>
                </div>
              ))}
            </div>
          </section>
        ))
      ) : (
        <Empty
          title="No possible duplicates"
          text="New reports are checked by proximity and road name."
        />
      )}
    </>
  );
}
function Teams() {
  const { data, refresh, notify } = useData();
  const { id } = useParams();
  const [q, setQ] = useState("");
  const [editing, setEditing] = useState<Team | null>(null);
  const [error, setError] = useState("");
  return (
    <>
      <Header
        title={id ? "Maintenance team" : "Maintenance teams"}
        description="Create crews, manage availability and review assigned work."
        action={<button className="primary" onClick={() => {setError("");setEditing({id:"",name:"",members:[],active:true});}}>Add team <Users size={16}/></button>}
      />
      <label className="search">
        <Search size={16} />
        <input
          aria-label="Search teams"
          placeholder="Search maintenance teams"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </label>
      <div className="two-columns">
        {data.teams
          .filter(
            (t) =>
              (!id || t.id === id) &&
              t.name.toLowerCase().includes(q.toLowerCase()),
          )
          .map((t) => (
            <Panel
              key={t.id}
              title={t.name}
              aside={<Badge value={t.active ? "Active" : "Inactive"} />}
            >
              <p>{t.members.join(" · ") || "No active members yet. Assign accounts from User management."}</p>
              <button className="button" onClick={() => {setError("");setEditing(t);}}>Edit team</button>
              <dl className="detail-list">
                <div>
                  <dt>Open tasks</dt>
                  <dd>
                    {
                      data.reports.filter(
                        (r) =>
                          r.teamId === t.id &&
                          !["Resolved", "Rejected", "Duplicate"].includes(
                            r.status,
                          ),
                      ).length
                    }
                  </dd>
                </div>
                <div>
                  <dt>Verified repairs</dt>
                  <dd>
                    {
                      data.reports.filter(
                        (r) => r.teamId === t.id && r.status === "Resolved",
                      ).length
                    }
                  </dd>
                </div>
              </dl>
              <SmallReports
                reports={data.reports.filter((r) => r.teamId === t.id)}
              />
              {!id && (
                <Link className="panel-bottom" to={base + "/teams/" + t.id}>
                  View team
                  <ArrowRight size={15} />
                </Link>
              )}
            </Panel>
          ))}
      </div>
      {editing && <Modal title={editing.id ? "Edit maintenance team" : "Add maintenance team"} close={() => setEditing(null)}>
        <form onSubmit={async(e) => {e.preventDefault();const f=new FormData(e.currentTarget);try{await request("/teams",{...(editing.id?{id:editing.id}:{municipality:f.get("municipality")}),name:f.get("name"),active:f.get("active")==="true"},editing.id?"PATCH":"POST");await refresh();setEditing(null);notify("Team saved.");}catch(e){setError((e as Error).message);}}}>
          <label>Team name<input name="name" defaultValue={editing.name} required maxLength={100}/></label>
          {!editing.id && <label>Municipality / city<input name="municipality" required maxLength={100} placeholder="e.g. Malolos or Baliwag"/></label>}
          <label>Availability<select name="active" defaultValue={String(editing.active)}><option value="true">Active</option><option value="false">Inactive</option></select></label>
          <p>Members are linked through User accounts. Finish open tasks and move active members before deactivating a team.</p>
          {error && <p className="error" role="alert">{error}</p>}
          <button className="primary">Save team <Check size={16}/></button>
        </form>
      </Modal>}
    </>
  );
}
function UsersPage() {
  const { data, refresh, notify } = useData();
  const { id } = useParams();
  const [q, setQ] = useState(""),
    [filter, setFilter] = useState("All"),
    [selected, setSelected] = useState<User | null>(null),
    [error, setError] = useState("");
  const [users, setUsers] = useState<User[]>([]), [teams, setTeams] = useState<Team[]>([]);
  const [offset, setOffset] = useState(0), [nextOffset, setNextOffset] = useState<number | null>(null);
  const [accountStatus, setAccountStatus] = useState("All"), [loading, setLoading] = useState(false);
  const [revision, setRevision] = useState(0);
  useEffect(() => {
    let ignore = false, pending = false;
    const load = async () => {
      if(pending) return;
      pending=true;
      setLoading(true);
      try {
        const query = new URLSearchParams({limit:'25',offset:String(offset)});
        if(q) query.set('q',q);
        if(filter!=="All") query.set('role',filter);
        if(accountStatus!=="All") query.set('active',accountStatus);
        const result = id ? {users:[await request<User>('/users/'+encodeURIComponent(id))],nextOffset:null} : await request<{users:User[];nextOffset:number|null}>('/users?'+query);
        const accountTeams = await request<Team[]>('/account-teams');
        if(!ignore) { setUsers(result.users); setNextOffset(result.nextOffset); setTeams(accountTeams); setError(""); }
      } catch(e) { if(!ignore) setError((e as Error).message); }
      finally { pending=false; if(!ignore) setLoading(false); }
    };
    void load(); const timer=setInterval(()=>void load(),5000);
    return () => { ignore=true; clearInterval(timer); };
  }, [q, filter, accountStatus, offset, id, revision]);
  return (
    <>
      <Header
        title={id ? "User details" : "User accounts"}
        description="Manage accounts, roles and maintenance team membership."
        action={<button className="primary" onClick={() => {setError("");setSelected({id:"",name:"",email:"",role:"citizen",active:true});}}>Add account <Users size={16}/></button>}
      />
      <div className="filters">
        <label className="search">
          <Search size={16} />
          <input
            aria-label="Search users"
            value={q}
            onChange={(e) => {setOffset(0);setQ(e.target.value);}}
            placeholder="Search names or email"
          />
        </label>
        <select
          aria-label="Role filter"
          value={filter}
          onChange={(e) => {setOffset(0);setFilter(e.target.value);}}
        >
          <option>All</option>
          <option>admin</option>
          <option>citizen</option>
          <option>maintenance</option>
        </select>
      </div>
      <label>Account status filter<select aria-label="Account status filter" value={accountStatus} onChange={e=>{setOffset(0);setAccountStatus(e.target.value);}}><option value="All">All statuses</option><option value="true">Active</option><option value="false">Inactive</option></select></label>
      {error && <p role="alert" className="error">{error}</p>}
      {loading && <p role="status">Loading accounts…</p>}
      <Panel title="Shared PostgreSQL accounts">
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>Account status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {users
                .map((u) => (
                  <tr key={u.id}>
                    <td>
                      <Link to={base + "/users/" + encodeURIComponent(u.id)}>{u.name}</Link>
                    </td>
                    <td>{u.email}</td>
                    <td>{u.role}</td>
                    <td>
                      <Badge value={u.active ? "Active" : "Inactive"} />
                    </td>
                    <td>
                      <button
                        disabled={u.id === data.user.id}
                        onClick={() => setSelected(u)}
                      >
                        Manage
                      </button>
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </Panel>
      {!id && <div className="pagination"><button disabled={offset===0||loading} onClick={()=>setOffset(Math.max(0,offset-25))}>Previous accounts</button><span>Page {Math.floor(offset/25)+1}</span><button disabled={nextOffset===null||loading} onClick={()=>setOffset(nextOffset!)}>Next accounts</button></div>}
      {!loading && !users.length && <p>No accounts match these filters.</p>}
      {selected && (
        <Modal
          title={selected.id ? "Manage " + selected.name : "Add account"}
          close={() => setSelected(null)}
        >
          <form
            onSubmit={async (e) => {
              e.preventDefault();
              const f = new FormData(e.currentTarget);
              try {
                await request(
                  "/users",
                  {
                    ...(selected.id ? {id:selected.id} : {name:f.get("name"),email:f.get("email")}),teamId:f.get("teamId"),
                    role: f.get("role"),
                    active: f.get("active") === "true",
                  },
                  selected.id ? "PATCH" : "POST",
                );
                await refresh();
                setRevision(value=>value+1);
                setSelected(null);
                notify("Account updated.");
              } catch (e) {
                setError((e as Error).message);
              }
            }}
          >
            {!selected.id && <>
              <label>Full name<input name="name" required autoComplete="name"/></label>
              <label>Email address<input name="email" type="email" required autoComplete="off"/></label>
              <p>This creates a shared account record without credentials. Mobile credential enrollment remains a separate workflow.</p>
            </>}
            <label>Maintenance team<select name="teamId" aria-label="Maintenance team" defaultValue={selected.teamId || ""}><option value="">Not assigned (non-maintenance roles)</option>{selected.teamId&&!teams.some(t=>t.id===selected.teamId)&&<option value={selected.teamId}>Current team (unavailable for new assignments)</option>}{teams.filter(t=>t.active).map(t=><option key={t.id} value={t.id}>{t.name}</option>)}</select></label>
            <label>
              Role
              <select name="role" aria-label="Role" defaultValue={selected.role}>
                <option>citizen</option>
                <option>maintenance</option>
                <option>admin</option>
              </select>
            </label>
            <label>
              Account status
              <select name="active" defaultValue={String(selected.active)}>
                <option value="true">Active</option>
                <option value="false">Inactive</option>
              </select>
            </label>
            {error && (
              <p role="alert" className="error">
                {error}
              </p>
            )}
            <p>
              Changing roles or deactivating access takes effect on the next API
              request.
            </p>
            <button className="primary">Confirm account changes</button>
          </form>
        </Modal>
      )}
    </>
  );
}
function Analytics() {
  const { data } = useData();
  const rs = data.reports,
    done = rs.filter((r) => r.status === "Resolved");
  const avg = done.length
    ? Math.round(
        done.reduce(
          (sum, r) =>
            sum +
            resolutionDays(r),
          0,
        ) / done.length,
      )
    : null;
  return (
    <>
      <Header
        title="Community reports, in perspective."
        description="Derived from reports in your authorized Supabase workspace."
        action={
          <Link className="button" to={base + "/exports"}>
            Export summary
            <Download size={15} />
          </Link>
        }
      />
      <Stats reports={rs} />
      <div className="two-columns">
        <Panel title="Reports over time">
          <Chart reports={rs} kind="time" />
        </Panel>
        <Panel title="Reports by status">
          <Chart reports={rs} />
        </Panel>
        <Panel title="Reported severity">
          <Chart reports={rs} kind="severity" />
        </Panel>
        <Panel title="Barangay distribution">
          <Chart reports={rs} kind="area" />
        </Panel>
        <Panel title="Maintenance workload">
          {data.teams.map((t) => (
            <div className="breakdown" key={t.id}>
              <span>{t.name}</span>
              <strong>
                {
                  rs.filter((r) => r.teamId === t.id && r.status !== "Resolved")
                    .length
                }{" "}
                open
              </strong>
            </div>
          ))}
        </Panel>
        <Panel title="Resolution summary">
          <div className="breakdown">
            <span>Verified repairs</span>
            <strong>{done.length}</strong>
          </div>
          <div className="breakdown">
            <span>Unresolved reports</span>
            <strong>
              {
                rs.filter(
                  (r) =>
                    !["Resolved", "Rejected", "Duplicate"].includes(r.status),
                ).length
              }
            </strong>
          </div>
          <div className="breakdown">
            <span>Mean elapsed time</span>
            <strong>{avg === null ? "—" : avg + " days"}</strong>
          </div>
        </Panel>
      </div>
    </>
  );
}
type ExportRow = Pick<Report, 'id' | 'severity' | 'status' | 'createdAt'> & {location:Pick<Report['location'], 'road' | 'barangay'>};
function Exports() {
  const { data, notify } = useData();
  const [status, setStatus] = useState("All"),
    [severity, setSeverity] = useState("All"),
    [area, setArea] = useState("All"),
    [from, setFrom] = useState(""),
    [to, setTo] = useState(""),
    [fields, setFields] = useState([
      "Reference",
      "Road",
      "Barangay",
      "Severity",
      "Status",
      "Submitted",
    ]),
    [error, setError] = useState("");
  const rs = data.reports.filter(
    (r) =>
      (status === "All" || r.status === status) &&
      (severity === "All" || r.severity === severity) &&
      (area === "All" || r.location.barangay === area) &&
      (!from || r.createdAt.slice(0, 10) >= from) &&
      (!to || r.createdAt.slice(0, 10) <= to),
  );
  function value(r: ExportRow, f: string) {
    return (
      {
        Reference: r.id,
        Road: r.location.road,
        Barangay: r.location.barangay,
        Severity: r.severity,
        Status: r.status,
        Submitted: r.createdAt.slice(0, 10),
      }[f] || ""
    );
  }
  async function exportFile(kind: string) {
    try {
      if (!fields.length) throw Error("Select at least one report field.");
      if (from && to && from > to)
        throw Error("The end date must be after the start date.");
      const exported = await request<{reports:ExportRow[]}>("/exports", {ids:rs.map(r=>r.id),fields,format:kind});
      const authorized = exported.reports;
      if (kind === "CSV") {
        const quote = (v: string) =>
          '"' + (/^\s*[=+@-]/.test(v) ? "'" + v : v).replaceAll('"', '""') + '"';
        const csv =
          "\uFEFF" +
          [fields, ...authorized.map((r) => fields.map((f) => value(r, f)))]
            .map((row) => row.map(quote).join(","))
            .join("\r\n");
        const url = URL.createObjectURL(
            new Blob([csv], { type: "text/csv;charset=utf-8" }),
          ),
          a = document.createElement("a");
        a.href = url;
        a.download = "patag-reports.csv";
        a.click();
        setTimeout(() => URL.revokeObjectURL(url), 1000);
      } else {
        const { jsPDF } = await import("jspdf");
        const pdf = new jsPDF({ orientation: "landscape" });
        pdf.setTextColor("#182B49");
        pdf.setFontSize(22);
        pdf.text("PATAG | Road report summary", 16, 20);
        pdf.setFontSize(10);
        pdf.text(
          "Authorized report export - " + authorized.length + " reports",
          16,
          29,
        );
        let y = 42;
        const col = 264 / fields.length;
        const head = () => {
          pdf.setFont("helvetica", "bold");
          fields.forEach((f, i) => pdf.text(f, 16 + i * col, y));
          pdf.setFont("helvetica", "normal");
          y += 10;
        };
        head();
        authorized.forEach((r) => {
          const cells = fields.map((f) =>
            pdf.splitTextToSize(value(r, f), col - 5),
          );
          const height = Math.max(...cells.map((c) => c.length)) * 5 + 6;
          if (y + height > 192) {
            pdf.addPage();
            y = 20;
            head();
          }
          cells.forEach((c, i) => pdf.text(c, 16 + i * col, y));
          y += height;
        });
        pdf.save("patag-reports.pdf");
      }
      notify(kind + " export downloaded.");
    } catch (e) {
      setError((e as Error).message);
    }
  }
  return (
    <>
      <Header
        title="Export center"
        description="Choose the reports and fields for a downloadable summary."
      />
      <div className="export-layout">
        <Panel title="Report selection">
          <label>
            Status
            <select value={status} onChange={(e) => setStatus(e.target.value)}>
              <option value="All">All statuses</option>
              {statuses.map((s) => (
                <option key={s}>{s}</option>
              ))}
            </select>
          </label>
          <label>
            Severity
            <select
              value={severity}
              onChange={(e) => setSeverity(e.target.value)}
            >
              <option value="All">All severities</option>
              <option>High</option>
              <option>Medium</option>
              <option>Low</option>
            </select>
          </label>
          <label>
            Barangay
            <select value={area} onChange={(e) => setArea(e.target.value)}>
              <option value="All">All barangays</option>
              {[...new Set(data.reports.map((r) => r.location.barangay))].map(
                (s) => (
                  <option key={s}>{s}</option>
                ),
              )}
            </select>
          </label>
          <div className="two-columns">
            <label>
              From date
              <input
                type="date"
                value={from}
                onChange={(e) => setFrom(e.target.value)}
              />
            </label>
            <label>
              To date
              <input
                type="date"
                value={to}
                onChange={(e) => setTo(e.target.value)}
              />
            </label>
          </div>
          <fieldset>
            <legend>Include fields</legend>
            {[
              "Reference",
              "Road",
              "Barangay",
              "Severity",
              "Status",
              "Submitted",
            ].map((f) => (
              <label className="checkbox" key={f}>
                <input
                  type="checkbox"
                  checked={fields.includes(f)}
                  onChange={(e) =>
                    setFields(
                      e.target.checked
                        ? [...fields, f]
                        : fields.filter((x) => x !== f),
                    )
                  }
                />
                {f}
              </label>
            ))}
          </fieldset>
        </Panel>
        <Panel title="Ready for your records">
          <Download size={32} />
          <h3>{rs.length} reports selected</h3>
          <p>
            Downloads contain authorized report fields. Reporter personal
            information is excluded.
          </p>
          {error && (
            <p className="error" role="alert">
              {error}
            </p>
          )}
          <div className="action-stack">
            <button className="primary" onClick={() => exportFile("CSV")}>
              Download CSV
              <Download size={16} />
            </button>
            <button onClick={() => exportFile("PDF")}>
              Download PDF
              <Download size={16} />
            </button>
          </div>
        </Panel>
      </div>
    </>
  );
}
function Notifications() {
  const { data, refresh } = useData();
  return (
    <>
      <Header
        title="Notifications"
        description="Report and repair updates for your authorized account."
        action={
          <button
            onClick={async () => {
              await request("/notifications/read", { id: "all" });
              await refresh();
            }}
          >
            Mark all as read
            <Check size={16} />
          </button>
        }
      />
      <Panel title="Workspace activity">
        {data.notifications.length ? (
          data.notifications.map((n) => (
            <div
              className={"notice-row " + (!n.read ? "unread" : "")}
              key={n.id}
            >
              <Bell size={18} />
              <Link
                to={base + (admin ? "/reports/" : "/assignments/") + n.reportId}
                onClick={async () => {
                  await request("/notifications/read", { id: n.id });
                  await refresh();
                }}
              >
                <strong>{n.title}</strong>
                <small>
                  {n.reportId} · {date(n.at)}
                </small>
              </Link>
              {!n.read && <span className="unread-dot" />}
            </div>
          ))
        ) : (
          <Empty
            title="All quiet for now"
            text="Status updates and assignments will appear here."
          />
        )}
      </Panel>
    </>
  );
}
function Activity() {
  const { data } = useData();
  const [q, setQ] = useState("");
  const entries = data.reports
    .flatMap((r) => r.history.map((h) => ({ ...h, reportId: r.id })))
    .filter((h) =>
      (h.reportId + " " + h.actor + " " + h.action + " " + h.note)
        .toLowerCase()
        .includes(q.toLowerCase()),
    )
    .sort((a, b) => b.at.localeCompare(a.at));
  return (
    <>
      <Header
        title="Report history"
        description="Report workflow history. Privileged API actions are also recorded in the protected audit log."
      />
      <label className="search">
        <Search size={16} />
        <input
          aria-label="Search history"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search report, action or actor"
        />
      </label>
      <Panel title={`${entries.length} recorded events`}>
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Report</th>
                <th>Actor</th>
                <th>Action</th>
                <th>Previous status</th>
                <th>New status</th>
                <th className="numeric">Date</th>
              </tr>
            </thead>
            <tbody>
              {entries.map((h) => (
                <tr key={h.id}>
                  <td>
                    <Link to={base + "/reports/" + h.reportId}>
                      {h.reportId}
                    </Link>
                  </td>
                  <td>{h.actor}</td>
                  <td>
                    {h.action}
                    <small className="sub-state">{h.note}</small>
                  </td>
                  <td>{h.from || "—"}</td>
                  <td>{h.to}</td>
                  <td className="numeric">{date(h.at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Panel>
    </>
  );
}

function SettingsPage() {
  const { data, refresh, notify } = useData();
  const [error, setError] = useState(""),
    [enabled, setEnabled] = useState(
      localStorage.getItem("patag-notification-preference") !== "off",
    );
  return (
    <>
      <Header
        title={admin ? "Workspace settings" : "Profile & settings"}
        description="Profile and preferences for your account."
      />

      <section className="settings-row">
        <div>
          <h2>Your profile</h2>
          <p>Used on review notes and task activity.</p>
        </div>
        <form
          className="panel"
          onSubmit={async (e) => {
            e.preventDefault();
            const f = new FormData(e.currentTarget);
            try {
              await request(
                "/me",
                { name: f.get("name"), email: f.get("email") },
                "PATCH",
              );
              await refresh();
              notify("Profile saved.");
            } catch (e) {
              setError((e as Error).message);
            }
          }}
        >
          <label>
            Full name
            <input name="name" defaultValue={data.user.name} required />
          </label>
          <label>
            Email address
            <input
              name="email"
              type="email"
              defaultValue={data.user.email}
              readOnly
              required
            />
          </label>
          <p>
            Role: {data.user.role}
            {!admin ? " · " + (data.teams.find(t=>t.id===data.user.teamId)?.name || "No team") : ""}
          </p>
          {error && (
            <p className="error" role="alert">
              {error}
            </p>
          )}
          <button className="primary">
            Save profile
            <Check size={15} />
          </button>
        </form>
      </section>
      <section className="settings-row">
        <div>
          <h2>Notification preference</h2>
          <p>Saved on this browser. In-app history stays available.</p>
        </div>
        <div className="panel">
          <label className="checkbox">
            <input
              type="checkbox"
              checked={enabled}
              onChange={(e) => {
                setEnabled(e.target.checked);
                localStorage.setItem(
                  "patag-notification-preference",
                  e.target.checked ? "on" : "off",
                );
                notify("Preference saved on this browser.");
              }}
            />
            Show unread notification indicators
          </label>
          <p className="muted">
            System push and email delivery require a production notification
            service.
          </p>
        </div>
      </section>
      {admin && (
        <section className="settings-row">
          <div>
            <h2>Agency & jurisdiction</h2>
            <p>
              Shared by all roles in this workspace. New reports use this agency; existing reports keep their assigned jurisdiction.
            </p>
          </div>
          <form
            className="panel"
            onSubmit={async(e) => {
              e.preventDefault();const f=new FormData(e.currentTarget);
              try {await request("/settings",{agency:f.get("agency"),city:f.get("city"),province:f.get("province")},"PATCH");await refresh();notify("Workspace settings saved.");setError("");}catch(e){setError((e as Error).message);}
            }}
          >
            <label>
              Agency label
              <input
                name="agency"
                defaultValue={
                  data.settings?.agency || "Bulacan-wide administrator scope"
                }
                required
              />
            </label>
            <label>City<input name="city" defaultValue={data.settings?.city || "Malolos"} required/></label>
            <label>Province<input name="province" defaultValue={data.settings?.province || "Bulacan"} required/></label>
            {error && <p className="error" role="alert">{error}</p>}
            <button className="primary">Save workspace settings</button>
            <Link className="back-link" to={base + "/users"}>
              Manage user accounts
              <ArrowRight size={16} />
            </Link>
          </form>
        </section>
      )}
      <section className="settings-row">
        <div>
          <h2>About PATAG</h2>
          <p>Pa-tag lubak, lubak patag.</p>
        </div>
        <div className="panel">
          <p>
            A Philippine civic platform connecting community reports, LGU
            verification and maintenance action.
          </p>
          <p>
            IT 305 · Bulacan State University
            <br />
            Academic final project · Local development API
          </p>
          <p className="muted">
            Only enter personal data needed for authorized PATAG work.
          </p>
        </div>
      </section>
    </>
  );
}
function Success() {
  const { id } = useParams();
  return (
    <section className="success">
      <img src="/assets/patag-mascot.png" alt="PATAG mascot" />
      <Badge value="Awaiting Verification" />
      <h1>
        Work submitted.
        <br />
        One step closer to patag.
      </h1>
      <p>
        {id} · The LGU will review your repair evidence before closing the
        report.
      </p>
      <Link className="primary" to={base + "/assignments/" + id}>
        View task
        <ArrowRight size={16} />
      </Link>
      <Link to={base + "/dashboard"}>Return to overview</Link>
    </section>
  );
}
export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path={base + "/login"} element={<Login />} />
        <Route path={base + "/*"} element={<Shell />} />
        <Route
          path="*"
          element={<Navigate to={base + "/dashboard"} replace />}
        />
      </Routes>
    </BrowserRouter>
  );
}
