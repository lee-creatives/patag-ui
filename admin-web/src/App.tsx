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
  LogOut,
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
  Maximize,
  Minimize,
} from "lucide-react";
import {
  MapContainer,
  TileLayer,
  ZoomControl,
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
import { request, asset, upload } from "./api";
import { role } from "./config";
import "leaflet/dist/leaflet.css";
import "./styles/app.css";
import "./styles/premium.css";
import "./styles/visual-system.css";
import "./styles/login-redesign.css";
import { useTheme } from "./theme";
import { translate as tr, getLanguage, useLanguage, setLanguage, languages } from "./i18n";
import type { Language } from "./i18n";

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
  new Date(v).toLocaleDateString(getLanguage() === "tl" ? "fil-PH" : "en-PH", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
// Local YYYY-MM-DD: filters and exports must use the same day the screen shows (UTC+8, not UTC).
const localDay = (v: string | Date) => new Date(v).toLocaleDateString("en-CA");
const dateTime = (v: string) =>
  new Date(v).toLocaleString(getLanguage() === "tl" ? "fil-PH" : "en-PH", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
const roleLabels: Record<string, string> = {
  admin: "LGU administrator",
  maintenance: "Road crew",
  citizen: "Citizen",
};
const actorLabel = (h: { actor: string; actorName?: string }) => {
  const role = roleLabels[h.actor] || h.actor;
  return h.actorName ? `${h.actorName} (${tr(role)})` : tr(role);
};
function Badge({ value }: { value: string }) {
  return (
    <span className={"badge " + value.toLowerCase().replaceAll(" ", "-")}>
      <span aria-hidden="true" /> {tr(value)}
    </span>
  );
}
function Logo() {
  return <img className="logo" src="/assets/patag-logo.png" alt={tr("PATAG")} />;
}
function Empty({
  title = tr("No reports here yet"),
  text = tr("When a report matches this view, it will appear here."),
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
          {admin ? tr("LGU operations") : workspace?.teams.find(t=>t.id===workspace.user.teamId)?.name || tr("Maintenance")}{" "}
          <ChevronRight size={13} /> {workspace?.settings?.city || tr("Malolos")}, {workspace?.settings?.province || tr("Bulacan")}
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
      onCancel={(e) => {
        e.preventDefault();
      }}
    >
      <header>
        <h2>{title}</h2>
        <button
          type="button"
          className="icon-button"
          aria-label={tr("Close dialog")}
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
      title={tr("This page requires another role")}
      text={tr("Use the navigation for your authorized workspace.")}
    />
  ) : (
    children
  );
}
function Login() {
  const nav = useNavigate();
  const [error, setError] = useState(""),
    [loading, setLoading] = useState(false),
    [recovery, setRecovery] = useState(false),
    [showPassword, setShowPassword] = useState(false),
    [message, setMessage] = useState("");
  const run = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setError("");
    setLoading(true);
    try {
      if (recovery) {
        const r = await request<{ message: string }>("/auth/recovery", {
          email: f.get("email"),
        });
        setMessage(r.message);
      } else {
        const r = await request<{ token: string; user: User }>("/auth/login", {
          email: f.get("email"),
          password: f.get("password"),
          role,
        });
        if (r.user.role !== role)
          throw Error("This account belongs to a different portal.");
        sessionStorage.setItem("patag-token", r.token);
        nav(base + "/dashboard");
      }
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  };
  async function demo() {
    setLoading(true);
    try {
      const r = await request<{ token: string }>("/auth/demo", { role });
      sessionStorage.setItem("patag-token", r.token);
      nav(base + "/dashboard");
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }
  return (
    <main className="login">
      <div className="login-card">
        <section className="login-story">
          <div className="login-story-top">
            <Logo />
          </div>
          <div className="login-story-body">
            <h1>
              {admin ? tr("Better roads.") : tr("Safe roads.")}
              <br />
              {admin ? tr("Built together.") : tr("Repaired fast.")}
            </h1>
            <p className="login-story-desc">
              {admin ? tr("Turn community reports into coordinated municipal action.") : tr("One repair at a time. Make the way safer for everyone.")}
            </p>
          </div>
          <small className="login-story-footer">{tr("IT 305 · Bulacan State University · Academic demonstration")}</small>
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
            {admin ? tr("LGU administrator") : tr("Road maintenance")}
          </span>
          <h2>{recovery ? tr("Recover access") : (admin ? tr("Welcome to LGU Portal") : tr("Crew Workspace Sign In"))}</h2>
          <p className="login-subtitle">
            {recovery ? tr("Request a password reset for your staff account.") : (admin ? tr("Access your tasks, reports, and teams anytime, anywhere — all in one place.") : tr("Access assigned road work orders, document repairs, and record evidence."))}
          </p>
          <form onSubmit={run}>
            <label>{tr("Email address")}<input
                name="email"
                type="email"
                autoComplete="email"
                required
                placeholder={tr("you@example.test")}
              />
            </label>
            {!recovery && (
              <label className="password-label">{tr("Password")}<div className="password-wrap">
                  <input
                    name="password"
                    type={showPassword ? "text" : "password"}
                    autoComplete="current-password"
                    required
                    minLength={1}
                    placeholder={tr("Enter your password")}
                  />
                  <button
                    type="button"
                    className="password-toggle-btn"
                  onMouseDown={(e) => e.preventDefault()}
                    aria-label={showPassword ? tr("Hide password") : tr("Show password")}
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
                {tr(error)}
              </p>
            )}
            {message && <p role="status">{tr(message)}</p>}
            <button className="primary submit-btn" disabled={loading}>
              {loading ? tr("Connecting…") : recovery ? tr("Request recovery") : tr("Sign in")}
              <ArrowRight size={16} />
            </button>
          </form>
          <button
            className="text-button forgot-btn"
            onClick={() => {
              setRecovery(!recovery);
              setMessage("");
            }}
          >
            {recovery ? tr("Back to sign in") : tr("Forgot password?")}
          </button>
          <div className="login-divider">
            <span>{tr("or continue with")}</span>
          </div>
          <details className="demo-access" open>
            <summary>{tr("Explore fictional demo data")}</summary>
            <strong>{tr("Explore the working demo")}</strong>
            <p>{tr("Fictional reports, local API, and role-based workflows. No official LGU records.")}</p>
            <button onClick={demo} disabled={loading} className="demo-action-btn">{tr("Continue as")}{" "}{admin ? tr("LGU administrator") : tr("Road Crew Alpha")}
              <ArrowUpRight size={16} />
            </button>
          </details>
          <p className="login-footnote">{tr("Staff accounts are provided by an authorized administrator. Contact your administrator if you need access.")}</p>
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
  const loc = useLocation(),
    nav = useNavigate();
  const refresh = useCallback(async () => {
    try {
      const d = await request<Bootstrap>("/bootstrap");
      if (d.user.role !== role) {
        sessionStorage.removeItem("patag-token");
        nav(base + "/login");
        return;
      }
      setData(d);
      setError("");
    } catch (e) {
      const m = (e as Error).message;
      setError(m);
      if (m.includes("Session expired")) {
        sessionStorage.removeItem("patag-token");
        nav(base + "/login");
      }
    }
  }, [nav]);
  useEffect(() => {
    if (!sessionStorage.getItem("patag-token")) {
      nav(base + "/login");
      return;
    }
    void refresh();
    const t = setInterval(() => void refresh(), 5000);
    return () => clearInterval(t);
  }, [nav, refresh]);
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
        <h1>{error ? tr("Local API unavailable") : tr("Opening your workspace…")}</h1>
        <p>{error || tr("Loading your reports and assignments.")}</p>
        <button onClick={() => void refresh()}>
          <RefreshCw size={16} />{" "}{tr("Retry")}</button>
        <Link to={base + "/login"}>{tr("Return to sign in")}</Link>
      </main>
    );
  return (
    <Context.Provider value={{ data, refresh, notify: setToast, event }}>
      <a className="skip-link" href="#main">{tr("Skip to content")}</a>
      <div className={menu ? "shell menu-expanded" : "shell"}>
        <aside id="workspace-navigation" aria-label={tr("Workspace navigation")} className={menu ? "sidebar open" : "sidebar"}>
          <button className="icon-button drawer-close" aria-label={tr("Close navigation drawer")} onClick={() => setMenu(false)}><X size={20} /></button>
          <Link to={base + "/dashboard"} aria-label={tr("PATAG overview")}>
            <Logo />
          </Link>
          <div className="workspace">
            <span className="workspace-avatar">{admin ? tr("LG") : tr("RC")}</span>
            <div>
              <strong>{admin ? data.settings?.agency || tr("Malolos demo LGU") : data.teams.find(t=>t.id===data.user.teamId)?.name || tr("Maintenance")}</strong>
              <small>
                {admin ? tr("City engineering office") : tr("Maintenance workspace")}
              </small>
            </div>
          </div>
          <nav aria-label={tr("Main navigation")}>
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
              <p className="nav-label">{tr(String(label))}</p>
              {navigation.filter(([path]) => (paths as string[]).includes(String(path))).map(([path, label, Icon]) => (
                <NavLink key={String(path)} title={tr(String(label))} aria-label={tr(String(label))} to={base + "/" + path}>
                  <Icon size={18} /><span>{tr(String(label))}</span>
                  {path === "verification" && <b>{data.reports.filter(r => ["Submitted", "Under Review"].includes(r.status)).length}</b>}
                </NavLink>
              ))}
            </Fragment>)}
          </nav>
          <div className="nav-bottom">
            <NavLink title={tr("Profile and settings")} aria-label={tr("Profile and settings")} to={base + (admin ? "/settings" : "/profile")}>
              <Settings size={18} />
              <span className="nav-text">{admin ? tr("Settings") : tr("Profile & settings")}</span>
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
                  {admin ? tr("LGU administrator") : tr("Maintenance personnel")}
                </small>
              </div>
              <button
                className="icon-button"
                aria-label={tr("Sign out")}
                onClick={async () => {
                  try {
                    await request("/auth/logout", {});
                  } catch {
                    // Signing out locally still matters when the server can't be reached.
                  } finally {
                    sessionStorage.removeItem("patag-token");
                    nav(base + "/login");
                  }
                }}
              >
                <LogOut size={17} />
              </button>
            </div>
          </div>
        </aside>
        {menu && <button className="drawer-backdrop" aria-label={tr("Close navigation overlay")} onClick={() => setMenu(false)} />}
        <div className="workspace-main">
          <div className="topbar">
            <button
              className="icon-button mobile-menu"
              aria-label={menu ? tr("Close navigation") : tr("Open navigation")}
              aria-expanded={menu}
              aria-controls="workspace-navigation"
              onClick={() => { setMenu(!menu); if (window.innerWidth >= 1024) localStorage.setItem("patag-sidebar", menu ? "collapsed" : "expanded"); }}
            >
              {menu ? <X size={22} /> : <Menu size={22} />}
            </button>
            <Link className="topbar-brand" to={base + '/dashboard'} aria-label={tr("PATAG home")}><Logo /></Link>
            <nav className="topnav" aria-label={tr("Primary workspace")}>
              {(admin ? [['dashboard','Overview'],['reports','Reports'],['assignments','Operations'],['users','User management']] : [['dashboard','Overview'],['assignments','My tasks'],['map','Task map'],['history','History']]).map(([path,label])=><NavLink key={path} to={base + '/' + path}>{tr(label)}</NavLink>)}
            </nav>
            <span className="workspace-caption">{admin ? (data.settings?.city || tr('Malolos')) + tr(' · LGU') : data.teams.find(t=>t.id===data.user.teamId)?.name || tr('Maintenance')}</span>
            <button className="icon-button theme-toggle" onClick={toggleTheme} aria-label={theme === "dark" ? tr("Switch to light mode") : tr("Switch to dark mode")} title={theme === "dark" ? tr("Light mode") : tr("Dark mode")}>
              {theme === "dark" ? <Sun size={19} /> : <Moon size={19} />}
            </button>
            <Link to={base + "/notifications"} className="notification-link" aria-label={tr("Notifications") + (data.notifications.some(n => !n.read) ? tr(", unread updates") : "")}>
              <Bell size={18} />
              {localStorage.getItem("patag-notification-preference") !== "off" && data.notifications.some(n => !n.read) && <i className="unread-dot" />}
            </Link>
          </div>
          <main id="main">
            {error && (
              <div className="error" role="alert">
                {tr(error)}
                <button onClick={() => void refresh()}>{tr("Reconnect")}</button>
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
                      title={tr("Page not found")}
                      text={tr("Use the workspace navigation to continue.")}
                    />
                  }
                />
              </Routes>
            </RoleBoundary>
          </main>
          <footer className="footer">{tr("PATAG")}{" "}<span>{tr("Community reports. Coordinated action.")}</span>
            <small>{tr("Fictional demo data · IT 305")}</small>
          </footer>
        </div>
      </div>
      {toast && (
        <div className="toast" role="status">
          <CheckCircle2 size={18} />
          {tr(toast)}
          <button
            aria-label={tr("Dismiss notification")}
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
          <span>{tr(String(label))}</span>
          <strong>{String(n)}</strong>
          <small>
            {admin ? i === 0 ? tr("Current workspace") : i === 1 ? tr("Needs attention") : i === 2 ? tr("Roads under repair") : tr("LGU verified repairs") : i === 0 ? tr("Ready to start") : i === 1 ? tr("Inspection or repair underway") : i === 2 ? tr("Awaiting LGU decision") : tr("LGU verified repairs")}
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
          ? [...new Set(reports.map((r) => localDay(r.createdAt)))].sort().slice(-14)
          : statuses;
  const series = groups.map((name) => ({
    name:
      kind === "time"
        ? new Date(name + "T00:00:00").toLocaleDateString(getLanguage() === "tl" ? "fil-PH" : "en-PH", { month: "short", day: "numeric" })
        : kind === "area" ? name : tr(name),
    total: reports.filter((r) =>
      kind === "time"
        ? localDay(r.createdAt) === name
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
      aria-label={`${tr("Reports by")} ${tr(kind)}: ${series.map((x) => x.name + " " + x.total).join(", ")}`}
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
            name={tr("Reports")}
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
      type="button"
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
      aria-label={tr("Recenter report map")}
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
  const language = useLanguage();
  const [tileError, setTileError] = useState(false);
  const wrapper = useRef<HTMLDivElement>(null);
  const toggle = useRef<HTMLButtonElement>(null);
  const [fullscreen, setFullscreen] = useState(false);
  const [fullscreenError, setFullscreenError] = useState("");
  useEffect(() => {
    let wasFullscreen = false;
    const changed = () => {
      const active = document.fullscreenElement === wrapper.current;
      setFullscreen(active);
      if (wasFullscreen && !active) toggle.current?.focus();
      wasFullscreen = active;
    };
    const escape = (event: KeyboardEvent) => {
      if (event.key === "Escape" && document.fullscreenElement === wrapper.current) {
        void document.exitFullscreen().catch(() => {
          if (document.fullscreenElement === wrapper.current) setFullscreenError("Fullscreen is unavailable. Try again.");
        });
      }
    };
    document.addEventListener("fullscreenchange", changed);
    document.addEventListener("keydown", escape);
    return () => {
      document.removeEventListener("fullscreenchange", changed);
      document.removeEventListener("keydown", escape);
    };
  }, []);
  return (
    <div ref={wrapper} className="map-wrapper" style={{ height }}>
      <button ref={toggle} type="button" className="map-fullscreen"
        aria-label={fullscreen ? tr("Exit fullscreen map") : tr("Enter fullscreen map")}
        aria-pressed={fullscreen} disabled={!document.fullscreenEnabled}
        onClick={async () => {
          setFullscreenError("");
          try {
            if (document.fullscreenElement === wrapper.current) await document.exitFullscreen();
            else await wrapper.current?.requestFullscreen();
          } catch { setFullscreenError("Fullscreen is unavailable. Try again."); }
        }}>
        {fullscreen ? <Minimize size={18} /> : <Maximize size={18} />}
      </button>
      {fullscreenError && <span className="tile-error" role="alert">{tr(fullscreenError)}</span>}
      <MapContainer
        center={[14.855, 120.815]}
        zoom={13}
        zoomControl={false}
        scrollWheelZoom={false}
        style={{ height: "100%", width: "100%" }}
      >
        <ZoomControl key={language} zoomInTitle={tr("Zoom in")} zoomOutTitle={tr("Zoom out")} />
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
          eventHandlers={{ tileerror: () => setTileError(true) }}
        />
        {reports.map((r) => (
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
                {r.id} · {tr(r.status)}
                <br />
                {tr(r.severity)}{" "}{tr("severity")}</p>
              <Link to={base + (admin ? "/reports/" : "/assignments/") + r.id}>{tr("View")}{" "}{admin ? tr("report") : tr("task")}
              </Link>
            </Popup>
          </CircleMarker>
        ))}
        <Recenter reports={reports} />
      </MapContainer>
      {tileError && (
        <span className="tile-error">{tr("Map tiles unavailable. Coordinates and report list remain available.")}</span>
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
            src={asset(r.photos[0]?.url || "/demo-evidence.svg")}
            alt={tr("Report evidence")}
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
      title={tr("You're all caught up")}
      text={tr("No reports need action in this queue.")}
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
  return <div className={'premium-overview ' + (admin ? 'admin-overview' : 'crew-overview')}>
    <Header title={admin ? tr('Roads overview') : tr('Your day on the road')} description={admin ? pending.length + tr(' reports need your review. Let’s keep Malolos moving.') : pending.length + tr(' active tasks. Clear priorities for your next repair.')} action={<Link className="primary" to={base + (admin ? '/verification' : '/assignments')}>{admin ? tr('Review reports') : tr('View my tasks')}<ArrowUpRight size={17}/></Link>}/>
    <section className="overview-summary" aria-label={tr("Report summary")}>
      <Link className="summary-lead" to={base + (admin ? '/reports' : '/history')}><span>{admin ? tr('Community reports') : tr('Verified repairs')}</span><div><strong>{admin ? rs.length : resolved}</strong><ArrowUpRight size={23}/></div><small>{admin ? tr(tr('Every tag is a road toward change.')) : tr('Completed and confirmed by the LGU.')}</small></Link>
      {metricRows.map(([label,value,route])=><Link className="summary-metric" key={label} to={base + '/' + route}><span>{tr(String(label))}</span><strong>{value}</strong><small>{tr("View")}{" "}{tr(String(label)).toLowerCase()}<ArrowUpRight size={14}/></small></Link>)}
    </section>
    <div className="operations-grid">
      <Panel title={admin ? tr('The action desk') : tr('Your next task')} aside={<span className="count">{pending.length}{" "}{tr("active")}</span>} className={admin ? 'action-desk' : 'next-task-panel'}>
        {admin ? <><div className="action-shortcuts"><Link to={base + '/verification'}><span>{tr("Verify reports")}</span><strong>{pending.length}</strong><ArrowRight size={17}/></Link><Link to={base + '/assignments'}><span>{tr("Ready for a crew")}</span><strong>{verified.length}</strong><ArrowRight size={17}/></Link><Link to={base + '/completions'}><span>{tr("Approve repairs")}</span><strong>{awaiting.length}</strong><ArrowRight size={17}/></Link></div><SmallReports reports={pending.slice(0,2)}/></> : next ? <div className="next-task"><div className="next-task-heading"><Badge value={next.severity}/><span>{next.id}</span></div><h2>{next.location.road}</h2><p><MapPin size={16}/>{tr("Brgy.")}{" "}{next.location.barangay}, {next.location.city}</p><div className="next-task-status"><Badge value={next.status}/><span>{tr("Assigned to your crew")}</span></div><Link className="primary" to={base + '/assignments/' + next.id}>{tr("Open task")}<ArrowUpRight size={17}/></Link></div> : <Empty title={tr("All clear for now")} text={tr("Your next assigned repair will appear here.")}/>}
      </Panel>
      <Panel title={admin ? tr('Road conditions') : tr('Your repair locations')} aside={<Link to={base + '/map'}>{tr("Open map")}<ArrowUpRight size={14}/></Link>} className="overview-map"><ReportMap reports={admin ? rs : pending} height={235}/><div className="map-legend"><span><i className="navy-dot"/>{tr("Reported")}</span><span><i className="orange-dot"/>{tr("High severity")}</span><span><i className="green-dot"/>{tr("Resolved")}</span></div></Panel>
      <Panel title={tr("Reports over time")} aside={<span className="muted">{tr("October 2026 · demo")}</span>} className="overview-trend"><Chart reports={rs} kind="time"/></Panel>
      <Panel title={admin ? tr('Priority roads') : tr('Up next')} aside={<Link to={base + (admin ? '/reports?severity=High' : '/assignments')}>{tr("View all")}<ArrowUpRight size={14}/></Link>} className="overview-priority"><SmallReports reports={(admin?high:pending.filter(r=>r.id!==next?.id)).slice(0,2)}/></Panel>
    </div>
    <section className="road-progress"><div><h2>{tr("From a tag to a better road")}</h2><p>{tr("Every stage, accounted for.")}</p></div><div className="progress-stages">{['Submitted','Under Review','Verified','Assigned','In Progress','Resolved'].map(s=><Link key={s} to={base + (admin ? '/reports?status=' + encodeURIComponent(s) : '/assignments')}><strong>{rs.filter(r=>r.status===s).length}</strong><span>{tr(s)}</span></Link>)}</div></section>
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
        (!from || localDay(r.createdAt) >= from) &&
        (!to || localDay(r.createdAt) <= to),
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
        title={tr(title[mode] || "Reports")}
        description={`${source.length} ${admin ? tr("community reports") : tr("crew tasks")} · ${tr("Evidence and progress in one place.")}`}
      />
      <div className="filters">
        <label className="search">
          <Search size={16} />
          <input
            aria-label={tr("Search reports")}
            placeholder={tr("Search road, barangay or reference…")}
            value={q}
            onChange={(e) => {
              setQ(e.target.value);
              setPage(1);
            }}
          />
        </label>
        <select
          aria-label={tr("Status filter")}
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(1);
          }}
        >
          <option value="All">{tr("All statuses")}</option>
          {statuses.map((s) => (
            <option key={s} value={s}>{tr(s)}</option>
          ))}
        </select>
        <select
          aria-label={tr("Severity filter")}
          value={severity}
          onChange={(e) => {
            setSeverity(e.target.value);
            setPage(1);
          }}
        >
          <option value="All">{tr("All severities")}</option>
          {["High", "Medium", "Low"].map((s) => (
            <option key={s} value={s}>{tr(s)}</option>
          ))}
        </select>
        <select
          aria-label={tr("Barangay filter")}
          value={area}
          onChange={(e) => setArea(e.target.value)}
        >
          <option value="All">{tr("All barangays")}</option>
          {[...new Set(source.map((r) => r.location.barangay))].map((s) => (
            <option key={s} value={s}>{s}</option>
          ))}
        </select>
        <select
          aria-label={tr("Team filter")}
          value={team}
          onChange={(e) => setTeam(e.target.value)}
        >
          <option value="All">{tr("All teams")}</option>
          {data.teams.map((t) => (
            <option key={t.id} value={t.id}>
              {t.name}
            </option>
          ))}
        </select>
        <select
          aria-label={tr("Sort reports")}
          value={sort}
          onChange={(e) => setSort(e.target.value)}
        >
          <option value="newest">{tr("Newest first")}</option>
          <option value="oldest">{tr("Oldest first")}</option>
          <option value="road">{tr("Road A–Z")}</option>
        </select>
        <label className="inline-label">{tr("From")}<input
            aria-label={tr("From date")}
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
          />
        </label>
        <label className="inline-label">{tr("To")}<input
            aria-label={tr("To date")}
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
        >{tr("Reset")}</button>
      </div>
      <section className="panel report-table">
        <div className="panel-title">
          <h2>
            {rows.length}{" "}{tr("matching")}{" "}{admin ? tr("reports") : tr("tasks")}
          </h2>
          <span className="muted">{tr("Live local demo")}</span>
        </div>
        {rows.length ? (<>
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>{tr("Report & location")}</th>
                    <th>{tr("Severity")}</th>
                    <th>{tr("Status")}</th>
                    <th>{tr("Assigned team")}</th>
                    <th className="numeric">{tr("Submitted")}</th>
                    <th>
                      <span className="sr-only">{tr("Action")}</span>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {rows.slice((current - 1) * 8, current * 8).map((r) => (
                    <tr key={r.id}>
                      <td>
                        <Link className="table-identity" to={link(r)}>
                          <img
                            src={asset(r.photos[0]?.url || "/demo-evidence.svg")}
                            alt={tr("Evidence preview")}
                          />
                          <span>
                            <strong>{r.location.road}</strong>
                            <small>
                              {r.id}{" "}{tr("· Brgy.")}{" "}{r.location.barangay}
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
                          <small className="sub-state">{tr("Awaiting verification")}</small>
                        )}
                      </td>
                      <td>
                        {data.teams.find((t) => t.id === r.teamId)?.name || tr("Unassigned")}
                      </td>
                      <td className="numeric">{date(r.createdAt)}</td>
                      <td>
                        <Link className="row-action" to={link(r)}>
                          {mode === "verification" ? tr("Review") : mode === "assignments" && r.status === "Verified" ? tr("Assign") : tr("View")}
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
                {(current - 1) * 8 + 1}–{Math.min(current * 8, rows.length)}{" "}{tr("of")}{" "}
                {rows.length}
              </span>
              <button
                disabled={current === 1}
                onClick={() => setPage(current - 1)}
                aria-label={tr("Previous page")}
              >
                <ArrowLeft size={15} />
              </button>
              <span>{tr("Page")}{" "}{current}{" "}{tr("of")}{" "}{pages}
              </span>
              <button
                disabled={current === pages}
                onClick={() => setPage(current + 1)}
                aria-label={tr("Next page")}
              >
                <ArrowRight size={15} />
              </button>
            </div>
          </>) : (<Empty
            title={tr("No matching reports")}
            text={tr("Try another search or reset the filters.")}
          />)}
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
            alt={label + (p.demo ? tr(" — illustrated demo") : "")}
          />
          <span>
            {p.demo ? tr("Illustrated demo") : label}
            <ArrowUpRight size={14} />
          </span>
        </a>
      ))}
      {!photos.length && (
        <p className="muted">{tr("No")}{" "}{label.toLowerCase()}{" "}{tr("submitted.")}</p>
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
  const dupKey = r
    ? [r.id, r.location.road, r.location.coordinates.lat, r.location.coordinates.lng].join("|")
    : "";
  useEffect(() => {
    if (r)
      void request<{ report: Report; distance: number }[]>("/duplicates", r)
        .then(setNearby)
        .catch(() => setNearby([]));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dupKey]);
  if (!r)
    return (
      <Empty
        title={tr("Report not found")}
        text={tr("It may belong to another team or account.")}
      />
    );
  const c = r.location.coordinates;
  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setBusy(true);
    setError("");
    const f = new FormData(e.currentTarget);
    try {
      const fields = ["note", "teamId", "priority", "targetDate", "duplicateOf", "jurisdiction"];
      await event(
        r.id,
        decision,
        Object.fromEntries(
          fields
            .map((k) => [k, f.get(k)] as const)
            .filter(([, v]) => typeof v === "string" && v.trim() !== ""),
        ),
      );
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
      notify(tr("Before-repair evidence saved."));
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
      notify(tr("Photo uploaded. Repair draft saved."));
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
        <ArrowLeft size={15} /> {admin ? tr("All reports") : tr("My assignments")}
      </Link>
      <Header
        title={
          mode === "review" ? tr("Review the report") : mode === "assign" ? tr("Assign a maintenance team") : mode === "completion" ? tr("Verify completed repair") : mode === "document" ? tr("Document the repair") : mode === "submit" ? tr("Review completion evidence") : r.location.road
        }
        description={`${r.id} · Brgy. ${r.location.barangay}, ${r.location.city}`}
        action={<Badge value={r.status} />}
      />
      {error && (
        <div className="error" role="alert">
          {tr(error)}
        </div>
      )}
      <div className="detail-grid">
        <div>
          <Panel
            title={
              mode === "completion" ? tr("Before repair") : tr("Submitted evidence")
            }
            aside={<Badge value={r.severity} />}
          >
            <Gallery photos={r.photos} label={tr("Before repair")} />
            {admin && <div className="notice" style={{display:"block"}}>
              <strong>{tr("Public photo visibility")}</strong>
              <p>{tr("Review all before-and-after images for faces, plates and personal details before allowing them on the community map. New evidence requires a new review.")}</p>
              <button className="button" disabled={busy} onClick={() => void direct("publication",{approved:!r.publicPhotosApproved,note:r.publicPhotosApproved?"Public photos hidden.":"Photos reviewed and approved for public display."})}>{r.publicPhotosApproved ? tr("Hide public photos") : tr("Approve public photos")}</button>
            </div>}
            {!admin && ["Assigned", "In Progress"].includes(r.status) && r.completion?.state !== "Awaiting Verification" && (
              <label className="upload">
                <Camera size={20} />
                <strong>{tr("Add before-repair photos")}</strong>
                <span>{tr("Document the site before work. Original citizen evidence is kept.")}</span>
                <input type="file" accept="image/png,image/jpeg,image/webp" multiple disabled={busy} aria-label={tr("Before-repair photos")} onChange={(e) => { void pickBefore(e.target.files); e.target.value = ""; }} />
              </label>
            )}
            <h3>{r.title}</h3>
            <p>{r.description}</p>
            <dl className="detail-list">
              <div>
                <dt>{tr("Observed hazards")}</dt>
                <dd>{r.hazards || tr("None stated")}</dd>
              </div>
              <div>
                <dt>{tr("Nearby landmark")}</dt>
                <dd>{r.location.landmark || tr("Not specified")}</dd>
              </div>
              <div>
                <dt>{tr("Responsible agency")}</dt>
                <dd>{r.jurisdiction}</dd>
              </div>
              <div>
                <dt>{tr("Submitted")}</dt>
                <dd>{date(r.createdAt)}</dd>
              </div>
              {admin && (
                <div>
                  <dt>{tr("Reporter reference")}</dt>
                  <dd>{r.reporterId}</dd>
                </div>
              )}
            </dl>
          </Panel>
          {r.completion && (
            <Panel
              title={tr("After repair")}
              aside={<Badge value={r.completion.state} />}
            >
              <Gallery photos={r.completion.photos} label={tr("After repair")} />
              <p>{r.completion.note}</p>
              <small className="muted">{tr("Submitted")}{" "}{date(r.completion.at)}</small>
            </Panel>
          )}
          {!admin && ["progress", "document", "submit"].includes(mode) && (
            <Panel
              title={
                mode === "progress" ? tr("Repair progress") : tr("Repair documentation")
              }
            >
              <p>{tr("Completion remains In Progress until the LGU verifies the repair.")}</p>
              <label>{tr("Work performed / progress notes")}<textarea
                  rows={4}
                  value={notes}
                  onChange={(e) => {
                    setNotes(e.target.value);
                    sessionStorage.setItem(
                      "repair-notes-" + id,
                      e.target.value,
                    );
                  }}
                  placeholder={tr("Describe the inspection, materials and work completed.")}
                />
              </label>
              {mode !== "progress" && (
                <>
                  <label className="upload">
                    <Camera size={22} />
                    <strong>{tr("Add after-repair photos")}</strong>
                    <span>{tr("PNG, JPEG or WebP · up to 8 MB per photo")}</span>
                    <input
                      aria-label={tr("After-repair photos")}
                      type="file"
                      accept="image/png,image/jpeg,image/webp"
                      multiple
                      onChange={(e) => void pick(e.target.files)}
                    />
                  </label>
                  <Gallery photos={photos} label={tr("Draft after repair")} />
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
                    >{tr("Remove")}{" "}{p.name}
                    </button>
                  ))}
                </>
              )}
              {mode === "progress" ? (<button
                  className="primary"
                  disabled={busy || !notes.trim()}
                  onClick={() =>
                    void direct("progress", { note: notes, phase: "Repair" })
                  }
                >{tr("Save progress")}<Check size={16} />
                </button>) : mode === "document" ? (<Link
                  className="primary"
                  to={base + "/repairs/" + r.id + "/submit"}
                >{tr("Review completion")}<ArrowRight size={16} />
                </Link>) : (<>
                  <p className="notice">
                    <ShieldCheck size={18} />{" "}{tr("Confirm that these photos show this road after repair. The LGU will review all evidence.")}</p>
                  <button
                    className="primary"
                    disabled={
                      busy || !notes.trim() || !photos.length || r.completion?.state === "Awaiting Verification" || r.status !== "In Progress"
                    }
                    onClick={() =>
                      void direct("complete", { note: notes, photos })
                    }
                  >{tr("Submit for administrative verification")}<ArrowRight size={16} />
                  </button>
                  <Link
                    className="back-link"
                    to={base + "/repairs/" + id + "/document"}
                  >{tr("Back to edit")}</Link>
                </>)}
            </Panel>
          )}
          <Panel title={tr("Report timeline")}>
            <ol className="timeline">
              {r.history
                .slice()
                .reverse()
                .map((h) => (
                  <li key={h.id}>
                    <span className="timeline-dot" />
                    <div>
                      <strong>
                        {h.action === "complete" ? tr("Completion submitted for verification") : h.action === "return" ? tr("Additional work requested") : h.to}
                      </strong>
                      <p>{h.note || h.action}</p>
                      <small>
                        {dateTime(h.at)} · {actorLabel(h)}
                      </small>
                    </div>
                  </li>
                ))}
            </ol>
            {r.updates.map((u, i) => (
              <p key={i}>
                <strong>{tr(u.phase)}</strong> · {u.note}{" "}
                <small>{date(u.at)}</small>
              </p>
            ))}
          </Panel>
        </div>
        <div>
          <Panel title={tr("Location")}>
            <ReportMap reports={[r]} height={260} />
            <div className="location-detail">
              <MapPin size={18} />
              <div>
                <strong>{r.location.road}</strong>
                <p>{tr("Brgy.")}{" "}{r.location.barangay}, {r.location.city},{" "}
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
              <Navigation size={16} />{tr("Open map navigation")}<ArrowUpRight size={15} />
            </a>
          </Panel>
          <Panel title={admin ? tr("Next action") : tr("Your task")}>
            <div className="action-stack">
              {admin ? (<>
                  {["Submitted", "Under Review"].includes(r.status) && (
                    <>
                      <p>{tr("Check the photo, pinned location and reported severity before deciding.")}</p>
                      <button
                        className="primary"
                        onClick={() => setDecision("verify")}
                      >{tr("Verify report")}<ShieldCheck size={16} />
                      </button>
                      {r.status === "Submitted" && (
                        <button onClick={() => setDecision("review")}>{tr("Move to Under Review")}</button>
                      )}
                      <button onClick={() => setDecision("flag")}>{tr("Flag for follow-up")}</button>
                      <button onClick={() => setDecision("duplicate")}>{tr("Confirm duplicate")}</button>
                      <button
                        className="danger-button"
                        onClick={() => setDecision("reject")}
                      >{tr("Reject with reason")}</button>
                    </>
                  )}
                  {r.status === "Verified" && (
                    <button
                      className="primary"
                      onClick={() => setDecision("assign")}
                    >{tr("Assign maintenance team")}<Truck size={16} />
                    </button>
                  )}
                  {r.completion?.state === "Awaiting Verification" && (
                    <>
                      <p>{tr("Compare before-and-after evidence and the repair notes.")}</p>
                      <button
                        className="primary"
                        onClick={() => setDecision("resolve")}
                      >{tr("Confirm resolution")}<CheckCircle2 size={16} />
                      </button>
                      <button onClick={() => setDecision("return")}>{tr("Request additional work")}</button>
                    </>
                  )}
                  <button onClick={() => setDecision("forward")}>{tr("Forward to responsible agency")}</button>
                </>) : (<>
                  {r.status === "Assigned" && (
                    <button
                      className="primary"
                      disabled={busy}
                      onClick={() => setDecision("start")}
                    >{tr("Start inspection / repair")}<Truck size={16} />
                    </button>
                  )}
                  {r.status === "In Progress" &&
                    r.completion?.state !== "Awaiting Verification" && (
                      <>
                        <Link
                          className="primary"
                          to={base + "/progress/" + r.id}
                        >{tr("Update progress")}<ArrowRight size={16} />
                        </Link>
                        <Link
                          className="button"
                          to={base + "/repairs/" + r.id + "/document"}
                        >{tr("Upload repair evidence")}<Camera size={16} />
                        </Link>
                      </>
                    )}
                  {r.completion?.state === "Awaiting Verification" && (
                    <p className="notice">
                      <Clock size={18} />{tr("Awaiting LGU verification. Your work is submitted; this case is not yet resolved.")}</p>
                  )}
                </>)}
              {r.status === "Resolved" && (
                <p className="notice">
                  <CheckCircle2 size={18} />{tr("Repair verified by the LGU. The reporter can now give feedback.")}</p>
              )}
            </div>
          </Panel>
          {r.assignment && (
            <Panel title={tr("Assigned crew")}>
              <strong>{data.teams.find((t) => t.id === r.teamId)?.name}</strong>
              <p>{r.assignment.note || tr("No additional instructions.")}</p>
              <small className="muted">{tr("Target:")}{" "}{r.assignment.targetDate || tr("Not set")}{" "}{tr("· Priority:")}{" "}
                {r.assignment.priority}
              </small>
            </Panel>
          )}
          {admin && (
            <Panel title={tr("Possible duplicates")}>
              {nearby.length ? (nearby.map((x) => (
                  <Link
                    className="duplicate-link"
                    key={x.report.id}
                    to={base + "/reports/" + x.report.id}
                  >
                    <strong>{x.report.id}</strong>
                    <span>
                      {x.distance}{" "}{tr("m away ·")}{" "}{x.report.location.road}
                    </span>
                    <ArrowUpRight size={15} />
                  </Link>
                ))) : (<p className="muted">{tr("No similar active reports within 150 m on this road.")}</p>)}
              <small className="muted">{tr("Suggestions require a human decision.")}</small>
            </Panel>
          )}
        </div>
      </div>
      {decision && (
        <Modal
          title={tr(
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
          )}
          close={() => setDecision("")}
        >
          <form onSubmit={submit}>
            <p>
              {decision === "resolve" ? tr("Confirm that the road repair is complete and evidence is sufficient. This will notify the reporter.") : `${tr("Report")} ${r.id} · ${r.location.road}`}
            </p>
            {decision === "assign" && (
              <>
                <label>{tr("Maintenance team")}<select name="teamId" required>
                    <option value="">{tr("Select a team")}</option>
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
                          }{" "}{tr("open tasks")}</option>
                      ))}
                  </select>
                </label>
                <label>{tr("Priority")}<select name="priority" defaultValue={r.severity}>
                    <option value="High">{tr("High")}</option>
                    <option value="Medium">{tr("Medium")}</option>
                    <option value="Low">{tr("Low")}</option>
                  </select>
                </label>
                <label>{tr("Target date")}<input
                    type="date"
                    name="targetDate"
                    min={localDay(new Date())}
                  />
                </label>
              </>
            )}
            {decision === "duplicate" && (
              <label>{tr("Original report")}<select name="duplicateOf" required>
                  <option value="">{tr("Select the original report")}</option>
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
              <label>{tr("Responsible agency")}<input
                  name="jurisdiction"
                  required
                  placeholder={tr("Agency or jurisdiction name")}
                />
              </label>
            )}
            <label>
              {["reject", "return", "flag"].includes(decision) ? tr("Reason / instructions (required)") : tr("Review / assignment notes")}
              <textarea
                name="note"
                required={["reject", "return", "flag"].includes(decision)}
                rows={3}
              />
            </label>
            {error && (
              <p className="error" role="alert">
                {tr(error)}
              </p>
            )}
            <div className="dialog-actions">
              <button type="button" onClick={() => setDecision("")}>{tr("Cancel")}</button>
              <button className="primary" disabled={busy}>
                {busy ? tr("Saving…") : tr("Confirm ") + (decision === "resolve" ? tr("resolution") : tr(decision))}
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
        title={admin ? tr("Pothole map") : tr("Assigned task map")}
        description={`${rs.length} ${tr("reports on the map")} · Malolos, Bulacan · ${tr("fictional demonstration locations")}`}
      />
      <div className="filters">
        <select
          aria-label={tr("Severity filter")}
          value={severity}
          onChange={(e) => setSeverity(e.target.value)}
        >
          <option value="All">{tr("All severities")}</option>
          {["High", "Medium", "Low"].map((s) => (
            <option key={s} value={s}>{tr(s)}</option>
          ))}
        </select>
        <select
          aria-label={tr("Status filter")}
          value={status}
          onChange={(e) => setStatus(e.target.value)}
        >
          <option value="All">{tr("All statuses")}</option>
          {statuses.map((s) => (
            <option key={s} value={s}>{tr(s)}</option>
          ))}
        </select>
        <select
          aria-label={tr("Barangay filter")}
          value={area}
          onChange={(e) => setArea(e.target.value)}
        >
          <option value="All">{tr("All barangays")}</option>
          {[...new Set(data.reports.map((r) => r.location.barangay))].map(
            (s) => (
              <option key={s} value={s}>{s}</option>
            ),
          )}
        </select>
        <button
          onClick={() => {
            setSeverity("All");
            setStatus("All");
            setArea("All");
          }}
        >{tr("Reset filters")}</button>
      </div>
      <div className="map-layout">
        <ReportMap reports={rs} height={560} />
        <Panel title={tr("Reports in view")}>
          {rs.length ? (<SmallReports reports={rs} />) : (<Empty title={tr("No matching roads")} />)}
        </Panel>
      </div>
    </>
  );
}
function Duplicates() {
  const { data } = useData();
  const [pairs, setPairs] = useState<
    { a: Report; b: Report; distance: number }[]
  >([]);
  const pending = data.reports.filter((r) =>
    ["Submitted", "Under Review"].includes(r.status),
  );
  const pendingKey = pending.map((r) => r.id + ":" + r.status).join(",");
  useEffect(() => {
    // allSettled: one failed check must not blank the whole list.
    void Promise.allSettled(
      pending.map(async (a) => {
        const list = await request<{ report: Report; distance: number }[]>(
          "/duplicates",
          a,
        );
        return list.map((x) => ({ a, b: x.report, distance: x.distance }));
      }),
    ).then((results) =>
      setPairs(results.flatMap((x) => (x.status === "fulfilled" ? x.value : []))),
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pendingKey]);
  return (
    <>
      <Header
        title={tr("Possible duplicates")}
        description={tr("Same road, within 150 metres. Compare evidence before confirming a duplicate.")}
      />
      {pairs.length ? (pairs.map(({ a, b, distance }) => (
          <section className="panel duplicate-pair" key={a.id + b.id}>
            <div className="panel-title">
              <h2>
                {distance}{" "}{tr("m apart ·")}{" "}{a.location.road}
              </h2>
              <Badge value="Possible duplicate" />
            </div>
            <div className="two-columns">
              {[a, b].map((r) => (
                <div key={r.id}>
                  <Gallery photos={r.photos} label={tr("Report evidence")} />
                  <h3>{r.id}</h3>
                  <p>{r.description}</p>
                  <p className="muted">
                    {date(r.createdAt)} · {r.location.coordinates.lat},{" "}
                    {r.location.coordinates.lng}
                  </p>
                  <Link className="button" to={base + "/verification/" + r.id}>{tr("Compare & review")}<ArrowUpRight size={16} />
                  </Link>
                </div>
              ))}
            </div>
          </section>
        ))) : (<Empty
          title={tr("No possible duplicates")}
          text={tr("New reports are checked by proximity and road name.")}
        />)}
    </>
  );
}
function Teams() {
  const { data, refresh, notify } = useData();
  const { id } = useParams();
  const [q, setQ] = useState("");
  const [editing, setEditing] = useState<Team | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  return (
    <>
      <Header
        title={id ? tr("Maintenance team") : tr("Maintenance teams")}
        description={tr("Create crews, manage availability and review assigned work.")}
        action={<button className="primary" onClick={() => {setError("");setEditing({id:"",name:"",members:[],active:true});}}>{tr("Add team")}{" "}<Users size={16}/></button>}
      />
      <label className="search">
        <Search size={16} />
        <input
          aria-label={tr("Search teams")}
          placeholder={tr("Search maintenance teams")}
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
              <p>{t.members.join(" · ") || tr("No active members yet. Select accounts in Edit team.")}</p>
              <button className="button" onClick={() => {setError("");setEditing(t);}}>{tr("Edit team")}</button>
              <dl className="detail-list">
                <div>
                  <dt>{tr("Open tasks")}</dt>
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
                  <dt>{tr("Verified repairs")}</dt>
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
                <Link className="panel-bottom" to={base + "/teams/" + t.id}>{tr("View team")}<ArrowRight size={15} />
                </Link>
              )}
            </Panel>
          ))}
      </div>
      {editing && <Modal title={editing.id ? tr("Edit maintenance team") : tr("Add maintenance team")} close={() => setEditing(null)}>
        <form onSubmit={async(e) => {e.preventDefault();const f=new FormData(e.currentTarget);setSaving(true);try{await request("/teams",{id:editing.id,name:f.get("name"),active:f.get("active")==="true",memberIds:f.getAll("memberIds")},editing.id?"PATCH":"POST");await refresh();setEditing(null);notify("Team saved.");}catch(e){setError((e as Error).message);}finally{setSaving(false);}}}>
          <label>{tr("Team name")}<input name="name" defaultValue={editing.name} required maxLength={100}/></label>
          <label>{tr("Availability")}<select name="active" defaultValue={String(editing.active)}><option value="true">{tr("Active")}</option><option value="false">{tr("Inactive")}</option></select></label>
          <fieldset disabled={saving}>
            <legend>{tr("Crew members")}</legend>
            <p>{tr("Select active crew accounts. Selecting a member moves them from their current team. Removing a member leaves their account unassigned.")}</p>
            {data.users.filter(u => u.active && u.role === "maintenance").map(u => (
              <label className="checkbox" key={u.id}>
                <input type="checkbox" name="memberIds" value={u.id} defaultChecked={!!editing.id && u.teamId === editing.id} />
                {u.name} · {u.email} · {data.teams.find(t => t.id === u.teamId)?.name || tr("Not assigned")}
              </label>
            ))}
            {!data.users.some(u => u.active && u.role === "maintenance") && <p>{tr("No eligible crew accounts. Create an active road crew account in User accounts.")}</p>}
          </fieldset>
          <p>{tr("Finish open tasks and remove active members before deactivating a team.")}</p>
          {error && <p className="error" role="alert">{tr(error)}</p>}
          <button className="primary" disabled={saving}>{tr("Save team")}{" "}<Check size={16}/></button>
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
    [deleting, setDeleting] = useState<User | null>(null),
    [showPw, setShowPw] = useState(false),
    [error, setError] = useState("");
  const emptyDraft = {
    name: "",
    email: "",
    password: "",
    teamId: "",
    role: "citizen" as User["role"],
    active: true,
  };
  const [draft, setDraft] = useState(emptyDraft);

  const openAdd = () => {
    setError("");
    setShowPw(false);
    setSelected({
      id: "",
      name: draft.name,
      email: draft.email,
      role: draft.role,
      teamId: draft.teamId || undefined,
      active: draft.active,
    });
  };

  const openEdit = (u: User) => {
    setError("");
    setShowPw(false);
    setSelected(u);
  };

  const isValidPassword = (pw: string) =>
    [...pw].length >= 8 &&
    [...pw].length <= 128 &&
    /[a-z]/.test(pw) &&
    /[A-Z]/.test(pw) &&
    /[0-9]/.test(pw) &&
    /[^A-Za-z0-9]/.test(pw);

  return (
    <>
      {id && (
        <Link className="back-link" to={base + "/users"}>
          <ArrowLeft size={16} />{" "}{tr("All user accounts")}</Link>
      )}
      <Header
        title={id ? tr("User details") : tr("User accounts")}
        description={tr("Create, update, manage roles, assign teams, or delete workspace accounts.")}
        action={
          <button className="primary" onClick={openAdd}>{tr("Add account")}{" "}<Users size={16} />
          </button>
        }
      />
      <div className="filters">
        <label className="search">
          <Search size={16} />
          <input
            aria-label={tr("Search users")}
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder={tr("Search names or email")}
          />
        </label>
        <select
          aria-label={tr("Role filter")}
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        >
          <option value="All">{tr("All")}</option>
          <option value="admin">{tr("admin")}</option>
          <option value="citizen">{tr("citizen")}</option>
          <option value="maintenance">{tr("maintenance")}</option>
        </select>
      </div>
      <Panel title={tr("Workspace accounts")}>
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>{tr("Name")}</th>
                <th>{tr("Email")}</th>
                <th>{tr("Role")}</th>
                <th>{tr("Team")}</th>
                <th>{tr("Account status")}</th>
                <th>{tr("Action")}</th>
              </tr>
            </thead>
            <tbody>
              {data.users
                .filter(
                  (u) =>
                    (!id || u.id === id) &&
                    (u.name + u.email)
                      .toLowerCase()
                      .includes(q.toLowerCase()) &&
                    (filter === "All" || u.role === filter),
                )
                .map((u) => (
                  <tr key={u.id}>
                    <td>
                      <Link to={base + "/users/" + u.id}>{u.name}</Link>
                    </td>
                    <td>{u.email}</td>
                    <td>{tr(u.role)}</td>
                    <td>
                      {data.teams.find((t) => t.id === u.teamId)?.name || "—"}
                    </td>
                    <td>
                      <Badge value={u.active ? "Active" : "Inactive"} />
                    </td>
                    <td>
                      <div style={{ display: "flex", gap: "8px", flexWrap: "wrap" }}>
                        <button
                          disabled={u.id === data.user.id}
                          onClick={() => openEdit(u)}
                        >{tr("Manage")}</button>
                        <button
                          disabled={u.id === data.user.id}
                          onClick={() => {
                            setError("");
                            setDeleting(u);
                          }}
                        >{tr("Delete")}</button>
                      </div>
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </Panel>
      {selected && (
        <Modal
          title={selected.id ? tr("Manage ") + selected.name : tr("Add account")}
          close={() => setSelected(null)}
        >
          <form
            key={selected.id || "add-account"}
            onSubmit={async (e) => {
              e.preventDefault();
              setError("");
              const f = new FormData(e.currentTarget);
              const name = String(f.get("name") || "").trim();
              const email = String(f.get("email") || "").trim();
              const password = String(f.get("password") || "");
              const teamId = String(f.get("teamId") || "");
              const selectedRole = String(f.get("role") || "citizen");
              const active = f.get("active") === "true";

              if (!selected.id || password.length > 0) {
                if (!isValidPassword(password)) {
                  setError(
                    "Password must be at least 8 characters and include lowercase, uppercase, number, and special character.",
                  );
                  return;
                }
              }

              try {
                await request(
                  "/users",
                  {
                    id: selected.id,
                    name,
                    email,
                    ...(password ? { password } : {}),
                    teamId,
                    role: selectedRole,
                    active,
                  },
                  selected.id ? "PATCH" : "POST",
                );
                await refresh();
                if (!selected.id) setDraft(emptyDraft);
                setSelected(null);
                notify(selected.id ? "Account updated." : "Account created.");
              } catch (e) {
                setError((e as Error).message);
              }
            }}
          >
            <label>{tr("Full name")}<input
                name="name"
                required
                maxLength={100}
                autoComplete="name"
                defaultValue={selected.id ? selected.name : draft.name}
                onChange={(e) => {
                  if (!selected.id)
                    setDraft((d) => ({ ...d, name: e.target.value }));
                }}
              />
            </label>
            <label>{tr("Email address")}<input
                name="email"
                type="email"
                required
                maxLength={254}
                autoComplete="off"
                defaultValue={selected.id ? selected.email : draft.email}
                onChange={(e) => {
                  if (!selected.id)
                    setDraft((d) => ({ ...d, email: e.target.value }));
                }}
              />
            </label>
            <label className="password-label">
              {selected.id ? tr("New password (leave blank to keep current)") : tr("Temporary demo password")}
              <div className="password-wrap">
                <input
                  name="password"
                  type={showPw ? "text" : "password"}
                  minLength={8}
                  maxLength={128}
                  required={!selected.id}
                  autoComplete="new-password"
                  placeholder={
                    selected.id ? tr("Leave blank to keep existing password") : tr("Min. 8 chars (Aa1!)")
                  }
                  defaultValue={selected.id ? "" : draft.password}
                  onChange={(e) => {
                    if (!selected.id)
                      setDraft((d) => ({ ...d, password: e.target.value }));
                  }}
                />
                <button
                  type="button"
                  className="password-toggle-btn"
                  onMouseDown={(e) => e.preventDefault()}
                  aria-label={showPw ? tr("Hide password") : tr("Show password")}
                  aria-pressed={showPw}
                  onClick={() => setShowPw(!showPw)}
                >
                  {showPw ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </label>
            <p>{tr("Requires at least 8 characters including uppercase, lowercase, number, and special character.")}</p>
            <label>{tr("Maintenance team")}<select
                name="teamId"
                aria-label={tr("Maintenance team")}
                defaultValue={
                  selected.id ? selected.teamId || "" : draft.teamId
                }
                onChange={(e) => {
                  if (!selected.id)
                    setDraft((d) => ({ ...d, teamId: e.target.value }));
                }}
              >
                <option value="">{tr("Not assigned")}</option>
                {data.teams
                  .filter((t) => t.active)
                  .map((t) => (
                    <option key={t.id} value={t.id}>
                      {t.name}
                    </option>
                  ))}
              </select>
            </label>
            <label>{tr("Role")}<select
                name="role"
                aria-label={tr("Role")}
                defaultValue={selected.id ? selected.role : draft.role}
                onChange={(e) => {
                  if (!selected.id)
                    setDraft((d) => ({
                      ...d,
                      role: e.target.value as User["role"],
                    }));
                }}
              >
                <option value="citizen">{tr("citizen")}</option>
                <option value="maintenance">{tr("maintenance")}</option>
                <option value="admin">{tr("admin")}</option>
              </select>
            </label>
            <label>{tr("Account status")}<select
                name="active"
                defaultValue={String(
                  selected.id ? selected.active : draft.active,
                )}
                onChange={(e) => {
                  if (!selected.id)
                    setDraft((d) => ({
                      ...d,
                      active: e.target.value === "true",
                    }));
                }}
              >
                <option value="true">{tr("Active")}</option>
                <option value="false">{tr("Inactive")}</option>
              </select>
            </label>
            {error && (
              <p role="alert" className="error">
                {tr(error)}
              </p>
            )}
            <p>{tr("Changing roles or deactivating access takes effect on the next API request.")}</p>
            <div className="dialog-actions" style={{ display: "flex", gap: "8px", flexWrap: "wrap" }}>
              <button className="primary" type="submit">{tr("Confirm account changes")}</button>
              {selected.id && (
                <button
                  type="button"
                  onClick={() => {
                    const target = selected;
                    setSelected(null);
                    setError("");
                    setDeleting(target);
                  }}
                >{tr("Delete account")}</button>
              )}
              {!selected.id && (
                <button
                  type="button"
                  onClick={() => {
                    setDraft(emptyDraft);
                    setSelected(null);
                  }}
                >{tr("Cancel & clear")}</button>
              )}
            </div>
          </form>
        </Modal>
      )}
      {deleting && (
        <Modal
          title={tr("Delete ") + deleting.name}
          close={() => setDeleting(null)}
        >
          <p>{tr("Are you sure you want to permanently delete the account for")}{" "}
            <strong>{deleting.name}</strong> ({deleting.email})?
          </p>
          {error && (
            <p role="alert" className="error">
              {tr(error)}
            </p>
          )}
          <div className="dialog-actions" style={{ display: "flex", gap: "8px", marginTop: "16px" }}>
            <button
              className="primary"
              type="button"
              onClick={async () => {
                try {
                  await request("/users", { id: deleting.id }, "DELETE");
                  await refresh();
                  setDeleting(null);
                  notify("Account deleted.");
                } catch (e) {
                  setError((e as Error).message);
                }
              }}
            >{tr("Confirm delete")}</button>
            <button type="button" onClick={() => setDeleting(null)}>{tr("Cancel")}</button>
          </div>
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
            (Date.parse(r.updatedAt) - Date.parse(r.createdAt)) / 86400000,
          0,
        ) / done.length,
      )
    : null;
  return (
    <>
      <Header
        title={tr("Community reports, in perspective.")}
        description={tr("Derived from fictional local records · no official repair statistics.")}
        action={
          <Link className="button" to={base + "/exports"}>{tr("Export summary")}<Download size={15} />
          </Link>
        }
      />
      <Stats reports={rs} />
      <div className="two-columns">
        <Panel title={tr("Reports over time")}>
          <Chart reports={rs} kind="time" />
        </Panel>
        <Panel title={tr("Reports by status")}>
          <Chart reports={rs} />
        </Panel>
        <Panel title={tr("Reported severity")}>
          <Chart reports={rs} kind="severity" />
        </Panel>
        <Panel title={tr("Barangay distribution")}>
          <Chart reports={rs} kind="area" />
        </Panel>
        <Panel title={tr("Maintenance workload")}>
          {data.teams.map((t) => (
            <div className="breakdown" key={t.id}>
              <span>{t.name}</span>
              <strong>
                {
                  rs.filter((r) => r.teamId === t.id && r.status !== "Resolved")
                    .length
                }{" "}{tr("open")}</strong>
            </div>
          ))}
        </Panel>
        <Panel title={tr("Resolution summary")}>
          <div className="breakdown">
            <span>{tr("Verified repairs")}</span>
            <strong>{done.length}</strong>
          </div>
          <div className="breakdown">
            <span>{tr("Unresolved reports")}</span>
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
            <span>{tr("Mean elapsed time (demo timestamps)")}</span>
            <strong>{avg === null ? "—" : avg + tr(" days")}</strong>
          </div>
        </Panel>
      </div>
    </>
  );
}
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
      (!from || localDay(r.createdAt) >= from) &&
      (!to || localDay(r.createdAt) <= to),
  );
  function value(r: Report, f: string) {
    return (
      {
        Reference: r.id,
        Road: r.location.road,
        Barangay: r.location.barangay,
        Severity: r.severity,
        Status: r.status,
        Submitted: localDay(r.createdAt),
      }[f] || ""
    );
  }
  async function exportFile(kind: string) {
    try {
      if (!fields.length) throw Error("Select at least one report field.");
      if (from && to && from > to)
        throw Error("The end date must be after the start date.");
      if (kind === "CSV") {
        const quote = (v: string) =>
          '"' + (/^[=+@\-]/.test(v) ? "'" + v : v).replaceAll('"', '""') + '"';
        const csv =
          "\uFEFF" +
          [fields, ...rs.map((r) => fields.map((f) => value(r, f)))]
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
          "FICTIONAL DEMONSTRATION DATA - " + rs.length + " reports",
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
        rs.forEach((r) => {
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
        title={tr("Export center")}
        description={tr("Choose the reports and fields for a downloadable summary.")}
      />
      <div className="export-layout">
        <Panel title={tr("Report selection")}>
          <label>{tr("Status")}<select value={status} onChange={(e) => setStatus(e.target.value)}>
              <option value="All">{tr("All statuses")}</option>
              {statuses.map((s) => (
                <option key={s} value={s}>{tr(s)}</option>
              ))}
            </select>
          </label>
          <label>{tr("Severity")}<select
              value={severity}
              onChange={(e) => setSeverity(e.target.value)}
            >
              <option value="All">{tr("All severities")}</option>
              <option value="High">{tr("High")}</option>
              <option value="Medium">{tr("Medium")}</option>
              <option value="Low">{tr("Low")}</option>
            </select>
          </label>
          <label>{tr("Barangay")}<select value={area} onChange={(e) => setArea(e.target.value)}>
              <option value="All">{tr("All barangays")}</option>
              {[...new Set(data.reports.map((r) => r.location.barangay))].map(
                (s) => (
                  <option key={s} value={s}>{s}</option>
                ),
              )}
            </select>
          </label>
          <div className="two-columns">
            <label>{tr("From date")}<input
                type="date"
                value={from}
                onChange={(e) => setFrom(e.target.value)}
              />
            </label>
            <label>{tr("To date")}<input
                type="date"
                value={to}
                onChange={(e) => setTo(e.target.value)}
              />
            </label>
          </div>
          <fieldset>
            <legend>{tr("Include fields")}</legend>
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
                {tr(f)}
              </label>
            ))}
          </fieldset>
        </Panel>
        <Panel title={tr("Ready for your records")}>
          <Download size={32} />
          <h3>{rs.length}{" "}{tr("reports selected")}</h3>
          <p>{tr("Downloads include a demonstration label. Reporter personal information is excluded.")}</p>
          {error && (
            <p className="error" role="alert">
              {tr(error)}
            </p>
          )}
          <div className="action-stack">
            <button className="primary" onClick={() => exportFile("CSV")}>{tr("Download CSV")}<Download size={16} />
            </button>
            <button onClick={() => exportFile("PDF")}>{tr("Download PDF")}<Download size={16} />
            </button>
          </div>
        </Panel>
      </div>
    </>
  );
}
function Notifications() {
  const { data, refresh, notify } = useData();
  return (
    <>
      <Header
        title={tr("Notifications")}
        description={tr("Report and repair updates from the local demonstration service.")}
        action={
          <button
            onClick={async () => {
              try {
                await request("/notifications/read", { id: "all" });
                await refresh();
              } catch (e) {
                notify((e as Error).message);
              }
            }}
          >{tr("Mark all as read")}<Check size={16} />
          </button>
        }
      />
      <Panel title={tr("Workspace activity")}>
        {data.notifications.length ? (data.notifications.map((n) => (
            <div
              className={"notice-row " + (!n.read ? "unread" : "")}
              key={n.id}
            >
              <Bell size={18} />
              <Link
                to={base + (admin ? "/reports/" : "/assignments/") + n.reportId}
                onClick={async () => {
                  try {
                    await request("/notifications/read", { id: n.id });
                    await refresh();
                  } catch (e) {
                    notify((e as Error).message);
                  }
                }}
              >
                <strong>{n.title}</strong>
                <small>
                  {n.reportId} · {date(n.at)}
                </small>
              </Link>
              {!n.read && <span className="unread-dot" />}
            </div>
          ))) : (<Empty
            title={tr("All quiet for now")}
            text={tr("Status updates and assignments will appear here.")}
          />)}
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
      (h.reportId + " " + actorLabel(h) + " " + h.action + " " + h.note)
        .toLowerCase()
        .includes(q.toLowerCase()),
    )
    .sort((a, b) => b.at.localeCompare(a.at));
  return (
    <>
      <Header
        title={tr("Report history")}
        description={tr("Local demonstration history. This is not a tamper-proof production audit log.")}
      />
      <label className="search">
        <Search size={16} />
        <input
          aria-label={tr("Search history")}
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder={tr("Search report, action or actor")}
        />
      </label>
      <Panel title={`${entries.length} ${tr("recorded events")}`}>
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>{tr("Report")}</th>
                <th>{tr("Actor")}</th>
                <th>{tr("Action")}</th>
                <th>{tr("Previous status")}</th>
                <th>{tr("New status")}</th>
                <th className="numeric">{tr("Date")}</th>
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
                  <td>{actorLabel(h)}</td>
                  <td>
                    {tr(h.action)}
                    <small className="sub-state">{h.note}</small>
                  </td>
                  <td>{h.from ? tr(h.from) : "—"}</td>
                  <td>{tr(h.to)}</td>
                  <td className="numeric">{dateTime(h.at)}</td>
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
  const language = useLanguage();
  const [languageError, setLanguageError] = useState("");
  const navigate = useNavigate();
  const { data, refresh, notify } = useData();
  const [error, setError] = useState(""),
    [enabled, setEnabled] = useState(
      localStorage.getItem("patag-notification-preference") !== "off",
    );
  return (
    <>
      <Header
        title={admin ? tr("Workspace settings") : tr("Profile & settings")}
        description={tr("Profile and preferences for this demonstration workspace.")}
      />

      <button className="button" onClick={async()=>{try{await request('/auth/logout',{});}finally{sessionStorage.removeItem('patag-token');navigate(base+'/login',{replace:true});}}}>{tr("Log out")}</button>
      <section className="settings-row">
        <div><h2>{tr("Language")}</h2><p>{tr("Choose the interface language. Saved on this browser.")}</p></div>
        <div className="panel">
          <label>{tr("Language")}<select aria-label={tr("Language")} value={language} onChange={e => {
            try { setLanguage(e.target.value as Language); setLanguageError(""); notify("Language saved on this browser."); }
            catch { setLanguageError("Could not save the language preference. Please allow browser storage and retry."); }
          }}>{languages.map(option => <option key={option.value} value={option.value}>{option.label}</option>)}</select></label>
          {languageError && <p className="error" role="alert">{tr(languageError)}</p>}
        </div>
      </section>
      <section className="settings-row">
        <div>
          <h2>{tr("Your profile")}</h2>
          <p>{tr("Used on review notes and task activity.")}</p>
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
          <label>{tr("Full name")}<input name="name" defaultValue={data.user.name} required />
          </label>
          <label>{tr("Email address")}<input
              name="email"
              type="email"
              defaultValue={data.user.email}
              readOnly
              required
            />
          </label>
          <p>{tr("Role:")}{" "}{tr(data.user.role)}
            {!admin ? " · " + (data.teams.find(t=>t.id===data.user.teamId)?.name || tr("No team")) : ""}
          </p>
          {error && (
            <p className="error" role="alert">
              {tr(error)}
            </p>
          )}
          <button className="primary">{tr("Save profile")}<Check size={15} />
          </button>
        </form>
      </section>
      <section className="settings-row">
        <div>
          <h2>{tr("Notification preference")}</h2>
          <p>{tr("Saved on this browser. In-app history stays available.")}</p>
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
            />{tr("Show unread notification indicators")}</label>
          <p className="muted">{tr("System push and email delivery require a production notification service.")}</p>
        </div>
      </section>
      {admin && (
        <section className="settings-row">
          <div>
            <h2>{tr("Agency & jurisdiction")}</h2>
            <p>{tr("Shared by all roles in this workspace. New reports use this agency; existing reports keep their assigned jurisdiction.")}</p>
          </div>
          <form
            className="panel"
            onSubmit={async(e) => {
              e.preventDefault();const f=new FormData(e.currentTarget);
              try {await request("/settings",{agency:f.get("agency"),city:f.get("city"),province:f.get("province")},"PATCH");await refresh();notify("Workspace settings saved.");setError("");}catch(e){setError((e as Error).message);}
            }}
          >
            <label>{tr("Agency label")}<input
                name="agency"
                defaultValue={
                  data.settings?.agency || "Malolos demo jurisdiction"
                }
                required
              />
            </label>
            <label>{tr("City")}<input name="city" defaultValue={data.settings?.city || "Malolos"} required/></label>
            <label>{tr("Province")}<input name="province" defaultValue={data.settings?.province || "Bulacan"} required/></label>
            {error && <p className="error" role="alert">{tr(error)}</p>}
            <button className="primary">{tr("Save workspace settings")}</button>
            <Link className="back-link" to={base + "/users"}>{tr("Manage user accounts")}<ArrowRight size={16} />
            </Link>
          </form>
        </section>
      )}
      <section className="settings-row">
        <div>
          <h2>{tr("About PATAG")}</h2>
          <p>{tr("Pa-tag lubak, lubak patag.")}</p>
        </div>
        <div className="panel">
          <p>{tr("A Philippine civic platform connecting community reports, LGU verification and maintenance action.")}</p>
          <p>{tr("IT 305 · Bulacan State University")}<br />{tr("Academic final project · Local development API")}</p>
          <p className="muted">{tr("Never use real personal data in this demonstration.")}</p>
        </div>
      </section>
    </>
  );
}
function Success() {
  const { id } = useParams();
  return (
    <section className="success">
      <img src="/assets/patag-mascot.png" alt={tr("PATAG mascot")} />
      <Badge value="Awaiting Verification" />
      <h1>{tr("Work submitted.")}<br />{tr("One step closer to patag.")}</h1>
      <p>
        {id}{" "}{tr("· The LGU will review your repair evidence before closing the report.")}</p>
      <Link className="primary" to={base + "/assignments/" + id}>{tr("View task")}<ArrowRight size={16} />
      </Link>
      <Link to={base + "/dashboard"}>{tr("Return to overview")}</Link>
    </section>
  );
}
export default function App() {
  const language = useLanguage();
  useEffect(() => {
    document.documentElement.lang = language;
    document.title = language === "tl" ? "PATAG · Mga operasyon ng LGU" : "PATAG · LGU operations";
  }, [language]);
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
