package com.vocaboo.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Admin endpoint to query application logs.
 * GET /api/admin/logs?level=ERROR&from_date=2025-01-01&to_date=2025-01-31&limit=100
 *
 * Reads from the rolling log files in the configured LOG_PATH directory.
 * ROLE_ADMIN required.
 */
@RestController
@RequestMapping("/api/admin/logs")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
public class AdminLogsController {

    private static final String LOG_DIR = System.getProperty("LOG_PATH", "logs");
    private static final int MAX_LIMIT  = 1000;

    @GetMapping
    public ResponseEntity<Map<String, Object>> getLogs(
            @RequestParam(required = false) String level,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from_date,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to_date,
            @RequestParam(defaultValue = "200") int limit
    ) {
        int safeLimit = Math.min(Math.max(limit, 1), MAX_LIMIT);
        List<String> matchedLines = new ArrayList<>();

        try {
            Path logDir = Paths.get(LOG_DIR);
            if (!Files.exists(logDir)) {
                return ResponseEntity.ok(Map.of(
                        "lines", List.of(),
                        "total", 0,
                        "note", "Log directory not found: " + LOG_DIR
                ));
            }

            // Collect all .log files (current + archived)
            try (Stream<Path> paths = Files.list(logDir)) {
                List<Path> logFiles = paths
                        .filter(p -> p.getFileName().toString().contains("app."))
                        .sorted()
                        .collect(Collectors.toList());

                for (Path file : logFiles) {
                    if (file.toString().endsWith(".gz")) {
                        try (java.util.zip.GZIPInputStream gzip = new java.util.zip.GZIPInputStream(Files.newInputStream(file));
                             java.io.BufferedReader br = new java.io.BufferedReader(new java.io.InputStreamReader(gzip, java.nio.charset.StandardCharsets.UTF_8))) {
                            br.lines().filter(line -> matchesFilters(line, level, from_date, to_date))
                                 .forEach(matchedLines::add);
                        } catch (Exception e) {
                            // Skip unreadable files
                        }
                    } else {
                        try (Stream<String> lines = Files.lines(file, java.nio.charset.StandardCharsets.UTF_8)) {
                            lines.filter(line -> matchesFilters(line, level, from_date, to_date))
                                 .forEach(matchedLines::add);
                        } catch (Exception e) {
                            // Skip unreadable files
                        }
                    }
                }
            }
        } catch (IOException e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to read logs: " + e.getMessage()));
        }

        int total = matchedLines.size();
        // Return the last N lines (most recent)
        List<String> page = matchedLines.size() > safeLimit
                ? matchedLines.subList(matchedLines.size() - safeLimit, matchedLines.size())
                : matchedLines;

        return ResponseEntity.ok(Map.of(
                "lines", page,
                "total", total,
                "returned", page.size()
        ));
    }

    private boolean matchesFilters(String line, String level, LocalDate from, LocalDate to) {
        if (level != null && !level.isBlank() && !line.contains(level.toUpperCase())) {
            return false;
        }
        if (from != null || to != null) {
            // Lines start with: 2025-01-15 14:32:00.123
            if (line.length() < 10) return false;
            try {
                LocalDate lineDate = LocalDate.parse(line.substring(0, 10), DateTimeFormatter.ISO_LOCAL_DATE);
                if (from != null && lineDate.isBefore(from)) return false;
                if (to   != null && lineDate.isAfter(to))   return false;
            } catch (Exception e) {
                return false; // skip non-timestamped lines
            }
        }
        return true;
    }
}
