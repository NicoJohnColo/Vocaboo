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

    public static TeacherRegisterResponseBuilder builder() { return new TeacherRegisterResponseBuilder(); }

    public static class TeacherRegisterResponseBuilder {
        private UUID teacherId;
        private String username;
        private String email;
        private String firstname;
        private String middlename;
        private String lastname;
        private String gender;
        private String school;
        private String message;

        public TeacherRegisterResponseBuilder teacherId(UUID teacherId) { this.teacherId = teacherId; return this; }
        public TeacherRegisterResponseBuilder username(String username) { this.username = username; return this; }
        public TeacherRegisterResponseBuilder email(String email) { this.email = email; return this; }
        public TeacherRegisterResponseBuilder firstname(String firstname) { this.firstname = firstname; return this; }
        public TeacherRegisterResponseBuilder middlename(String middlename) { this.middlename = middlename; return this; }
        public TeacherRegisterResponseBuilder lastname(String lastname) { this.lastname = lastname; return this; }
        public TeacherRegisterResponseBuilder gender(String gender) { this.gender = gender; return this; }
        public TeacherRegisterResponseBuilder school(String school) { this.school = school; return this; }
        public TeacherRegisterResponseBuilder message(String message) { this.message = message; return this; }

        public TeacherRegisterResponse build() {
            TeacherRegisterResponse r = new TeacherRegisterResponse();
            r.teacherId = this.teacherId;
            r.username = this.username;
            r.email = this.email;
            r.firstname = this.firstname;
            r.middlename = this.middlename;
            r.lastname = this.lastname;
            r.gender = this.gender;
            r.school = this.school;
            r.message = this.message;
            return r;
        }
    }
}
