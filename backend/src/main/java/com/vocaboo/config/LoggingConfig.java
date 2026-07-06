package com.vocaboo.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

/**
 * Logging configuration: attaches a unique requestId and the authenticated
 * userId to the SLF4J MDC (Mapped Diagnostic Context) for every request.
 * These values appear automatically in every log line via logback-spring.xml.
 */
@Component
public class LoggingConfig extends OncePerRequestFilter {

    private static final String REQUEST_ID_KEY = "requestId";
    private static final String USER_ID_KEY    = "userId";

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String requestId = UUID.randomUUID().toString().replace("-", "").substring(0, 12);

        // Extract userId from the X-User-Id header (set downstream by JwtAuthFilter if desired)
        // or fall back to "anonymous"
        String userId = request.getHeader("X-User-Id");
        if (userId == null || userId.isBlank()) userId = "anonymous";

        MDC.put(REQUEST_ID_KEY, requestId);
        MDC.put(USER_ID_KEY, userId);

        // Expose requestId in response header so clients can correlate logs
        response.setHeader("X-Request-Id", requestId);

        try {
            filterChain.doFilter(request, response);
        } finally {
            MDC.remove(REQUEST_ID_KEY);
            MDC.remove(USER_ID_KEY);
        }
    }
}
