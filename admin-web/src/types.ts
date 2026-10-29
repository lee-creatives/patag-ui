export const statuses = [
  "Submitted",
  "Under Review",
  "Verified",
  "Assigned",
  "In Progress",
  "Resolved",
  "Rejected",
  "Duplicate",
] as const;
export type Status = (typeof statuses)[number];
export type Role = "admin" | "maintenance" | "citizen";
export interface Coordinates {
  lat: number;
  lng: number;
}
export interface Photo {
  id: string;
  url: string;
  name: string;
  kind: string;
  demo?: boolean;
}
export interface History {
  id: string;
  at: string;
  actor: string;
  actorId?: string;
  actorName?: string;
  action: string;
  from: Status | null;
  to: Status;
  note: string;
}
export interface Report {
  id: string;
  title: string;
  description: string;
  hazards: string;
  severity: "Low" | "Medium" | "High";
  status: Status;
  createdAt: string;
  updatedAt: string;
  location: {
    road: string;
    barangay: string;
    city: string;
    province: string;
    landmark: string;
    coordinates: Coordinates;
  };
  photos: Photo[];
  teamId: string | null;
  reporterId: string;
  jurisdiction: string;
  history: History[];
  flagged: boolean;
  publicPhotosApproved?: boolean;
  duplicateOf?: string;
  assignment: {
    teamId: string;
    priority: string;
    note: string;
    targetDate: string | null;
    at: string;
  } | null;
  updates: { at: string; note: string; phase: string; photos: Photo[] }[];
  completion: {
    state: string;
    note: string;
    photos: Photo[];
    at: string;
  } | null;
  feedback: { rating: number; text: string } | null;
}
export interface User {
  id: string;
  name: string;
  email: string;
  role: Role;
  teamId?: string;
  active: boolean;
}
export interface Team {
  id: string;
  name: string;
  members: string[];
  active: boolean;
}
export interface Notice {
  id: string;
  reportId: string;
  title: string;
  read: boolean;
  at: string;
}
export interface Bootstrap {
  settings?: {agency:string;city:string;province:string};
  demo?: boolean;
  reports: Report[];
  teams: Team[];
  users: User[];
  notifications: Notice[];
  user: User;
}
export interface Citizen extends User {
  role: "citizen";
}
export interface LGUPersonnel extends User {
  role: "admin";
}
export type MaintenanceTeam = Team;
export type PotholeReport = Report;
export type ReportPhoto = Photo;
export type LocationDetails = Report["location"];
export type Severity = Report["severity"];
export type ReportStatus = Status;
export type ReportHistoryEntry = History;
export type Assignment = NonNullable<Report["assignment"]>;
export type RepairProgressUpdate = Report["updates"][number];
export interface RepairDocumentation {
  before: ReportPhoto[];
  after: ReportPhoto[];
  note: string;
}
export type CompletionVerification = NonNullable<Report["completion"]>;
export type Notification = Notice;
export type ReportFeedback = NonNullable<Report["feedback"]>;
export interface DuplicateCandidate {
  report: PotholeReport;
  distance: number;
}
export interface AgencyJurisdiction {
  id: string;
  name: string;
  municipalities: string[];
}
