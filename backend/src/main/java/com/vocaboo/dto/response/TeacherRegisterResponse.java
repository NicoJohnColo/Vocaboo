package com.vocaboo.dto.response;

import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TeacherRegisterResponse {

    private UUID teacherId;
    private String username;
    private String email;
    private String firstname;
    private String middlename;
    private String lastname;
    private String gender;
    private String school;
    private String message;
}
