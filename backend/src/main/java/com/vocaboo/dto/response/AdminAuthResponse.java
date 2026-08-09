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
}
