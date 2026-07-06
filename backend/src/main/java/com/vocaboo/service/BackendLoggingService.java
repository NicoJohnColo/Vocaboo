package com.vocaboo.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.UUID;

/**
 * Centralized structured logging service for the Vocaboo backend.
 *
 * Usage:
 *   loggingService.logError(e, "PronunciationService.evaluate", Map.of("wordId", wordId));
 *   loggingService.logInfo("Learner registered", Map.of("learnerId", id));
 *   loggingService.logMetric("stt_latency_ms", 432);
 */
@Service
public class BackendLoggingService {

    private static final Logger log = LoggerFactory.getLogger(BackendLoggingService.class);

    // ── Context attachment ──────────────────────────────────────────────────

    /**
     * Attaches user context to the SLF4J MDC for the current thread.
     * Call this early in a request handler when the authenticated user is known.
     */
    public void attachContext(UUID userId, String requestId, String timestamp) {
        if (userId != null)    MDC.put("userId", userId.toString());
        if (requestId != null) MDC.put("requestId", requestId);
        if (timestamp != null) MDC.put("timestamp", timestamp);
    }

    // ── Logging methods ─────────────────────────────────────────────────────

    /**
     * Logs an exception with full stack trace and structured context.
     *
     * @param exception the caught exception
     * @param context   a short descriptor like "ClassName.methodName"
     * @param extra     optional key-value pairs for structured context
     */
    public void logError(Throwable exception, String context, Map<String, Object> extra) {
        String msg = buildMessage("ERROR", context, extra);
        log.error(msg, exception);
    }

    public void logError(Throwable exception, String context) {
        logError(exception, context, Map.of());
    }

    /**
     * Logs a non-fatal warning.
     */
    public void logWarning(String message, Map<String, Object> extra) {
        String msg = buildMessage("WARN", message, extra);
        log.warn(msg);
    }

    public void logWarning(String message) {
        logWarning(message, Map.of());
    }

    /**
     * Logs general information (logins, key lifecycle events).
     */
    public void logInfo(String message, Map<String, Object> extra) {
        String msg = buildMessage("INFO", message, extra);
        log.info(msg);
    }

    public void logInfo(String message) {
        logInfo(message, Map.of());
    }

    /**
     * Logs a named performance metric value.
     *
     * @param metricName  e.g. "stt_api_latency_ms", "db_query_duration_ms"
     * @param value       numeric value
     */
    public void logMetric(String metricName, Number value) {
        log.info("[METRIC] {}={}", metricName, value);
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private String buildMessage(String level, String context, Map<String, Object> extra) {
        if (extra == null || extra.isEmpty()) {
            return String.format("[%s] %s", level, context);
        }
        StringBuilder sb = new StringBuilder();
        sb.append("[").append(level).append("] ").append(context).append(" |");
        extra.forEach((k, v) -> sb.append(" ").append(k).append("=").append(v));
        return sb.toString();
    }
}
