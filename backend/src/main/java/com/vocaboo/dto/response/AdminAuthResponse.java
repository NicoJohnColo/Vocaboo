package com.vocaboo.dto.response;

import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminAuthResponse {
    private String token;
    private UUID adminId;
    private String username;
    private String email;
    private boolean mustChangePassword;
    /** "admin" or "teacher" — set by the auth service so the frontend can differentiate. */
    private String role;

    public static AdminAuthResponseBuilder builder() { return new AdminAuthResponseBuilder(); }

    public static class AdminAuthResponseBuilder {
        private String token;
        private UUID adminId;
        private String username;
        private String email;
        private boolean mustChangePassword;
        private String role;

        public AdminAuthResponseBuilder token(String token) { this.token = token; return this; }
        public AdminAuthResponseBuilder adminId(UUID adminId) { this.adminId = adminId; return this; }
        public AdminAuthResponseBuilder username(String username) { this.username = username; return this; }
        public AdminAuthResponseBuilder email(String email) { this.email = email; return this; }
        public AdminAuthResponseBuilder mustChangePassword(boolean mustChangePassword) { this.mustChangePassword = mustChangePassword; return this; }
        public AdminAuthResponseBuilder role(String role) { this.role = role; return this; }

        public AdminAuthResponse build() {
            AdminAuthResponse r = new AdminAuthResponse();
            r.token = this.token;
            r.adminId = this.adminId;
            r.username = this.username;
            r.email = this.email;
            r.mustChangePassword = this.mustChangePassword;
            r.role = this.role;
            return r;
        }
    }
}
