export interface AdminAuthResponse {
  token: string;
  adminId: string;
  username: string;
  email: string;
  mustChangePassword?: boolean;
  role?: string; // "admin" | "teacher"
}

export interface AdminInfo {
  adminId: string;
  username: string;
  email: string;
  mustChangePassword?: boolean;
}

export interface AdminAccount {
  admin_id: string;
  username: string;
  email: string;
  is_active: boolean;
  school_id?: string;
  created_at: string;
  last_login?: string;
}
