package com.vocaboo.config;

import com.vocaboo.security.JwtAuthFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Public learner endpoints
                .requestMatchers("/api/v1/learners/register", "/api/v1/learners/login", "/api/v1/learners/check-name").permitAll()
                // Public admin login and registration
                .requestMatchers(HttpMethod.POST, "/api/admin/login", "/api/admin/register").permitAll()
                // Public teacher self-registration
                .requestMatchers(HttpMethod.POST, "/api/teachers/register").permitAll()
                // Public teacher password reset
                .requestMatchers(HttpMethod.POST, "/api/teachers/request-reset").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/teachers/complete-reset").permitAll()
                // Password reset — both endpoints must be public (user is not logged in)
                .requestMatchers(HttpMethod.POST, "/api/admin/accounts/complete-reset").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/admin/accounts/request-reset").permitAll()
                // Token refresh and logout (learner — bearer token required but role-agnostic)
                .requestMatchers("/api/auth/refresh", "/api/auth/logout").permitAll()
                // Uploaded asset files — publicly readable (audio & images for mobile app)
                .requestMatchers("/uploads/**").permitAll()
                // Health check endpoint — publicly accessible for Render monitoring
                .requestMatchers("/health").permitAll()

                // ── Admin-only routes (account management, logs, admin logout) ──
                // Teachers must NOT access these.
                .requestMatchers("/api/admin/accounts/**").hasRole("ADMIN")
                .requestMatchers("/api/admin/logs/**").hasRole("ADMIN")
                .requestMatchers("/api/admin/logout-everywhere").hasRole("ADMIN")

                // ── Content routes — both ADMIN and TEACHER can access ──────────
                // Lessons, categories, vocabulary, dashboard, diagnostics, etc.
                .requestMatchers("/api/admin/lessons", "/api/admin/lessons/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/categories", "/api/admin/categories/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/vocabulary", "/api/admin/vocabulary/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/confusable-pairs", "/api/admin/confusable-pairs/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/difficulty", "/api/admin/difficulty/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/dashboard", "/api/admin/dashboard/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/diagnostics", "/api/admin/diagnostics/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/learners", "/api/admin/learners/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/classes", "/api/admin/classes/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/sections", "/api/admin/sections/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/analytics", "/api/admin/analytics/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/assets", "/api/admin/assets/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/sandbox", "/api/admin/sandbox/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/reviews", "/api/admin/reviews/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/reports", "/api/admin/reports/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/admin/cross-lesson-sentences", "/api/admin/cross-lesson-sentences/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/teacher/classes", "/api/teacher/classes/**").hasAnyRole("ADMIN", "TEACHER")
                .requestMatchers("/api/learner/classes", "/api/learner/classes/**", "/api/v1/learner/classes", "/api/v1/learner/classes/**").hasRole("LEARNER")
                .requestMatchers("/api/cumulative-review/**", "/api/v1/cumulative-review/**").authenticated()

                // Remaining /api/admin/** (catch-all) — require at least ADMIN
                .requestMatchers("/api/admin/**").hasRole("ADMIN")

                // Everything else requires authentication
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * CORS configuration — allows the React admin panel (localhost:5173) and
     * any deployed admin domain to communicate with the backend.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of(
                "http://localhost:*",
                "http://127.0.0.1:*",
                "http://10.*:*",
                "http://192.168.*:*",
                "https://*.vocaboo-admin.app",
                "https://vocaboo-admin.app",
                "https://*.vercel.app",
                "https://*.onrender.com",
                "https://*.netlify.app",
                "*"
        ));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        // PIN is BCrypt-hashed (strength 12) before storage. Never stored or transmitted in plaintext.
        return new BCryptPasswordEncoder(12);
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}
