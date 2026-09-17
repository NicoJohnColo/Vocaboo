# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

# Copy Maven wrapper and pom first (for layer caching)
COPY backend/mvnw .
COPY backend/.mvn .mvn
COPY backend/pom.xml .

# Make mvnw executable and download dependencies (cached unless pom.xml changes)
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Copy source code and build
COPY backend/src src
RUN ./mvnw clean package -DskipTests -B

# ── Stage 2: Run ──────────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine AS runtime

WORKDIR /app

# Create uploads directory for file storage
RUN mkdir -p uploads

# Copy the built jar from builder stage
COPY --from=builder /app/target/backend-0.0.1-SNAPSHOT.jar app.jar

# Render injects PORT env var; Spring Boot reads it via server.port=${PORT:8081}
EXPOSE 8081

ENTRYPOINT ["java", "-Xmx400m", "-Xms200m", "-jar", "app.jar"]
