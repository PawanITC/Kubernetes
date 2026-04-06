# ─── Stage 1: Build ──────────────────────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-17-alpine AS build
WORKDIR /app

# Download dependencies first (cached layer if pom.xml unchanged)
COPY pom.xml .
RUN mvn dependency:go-offline -q

# Build the application
COPY src ./src
RUN mvn package -DskipTests -q

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine

# Create a non-root user for security (principle of least privilege)
RUN addgroup -S -g 1001 spring && adduser -S -u 1001 -G spring spring

WORKDIR /app

# Copy only the fat JAR from the build stage
COPY --from=build --chown=spring:spring /app/target/*.jar app.jar

# Switch to non-root user
USER spring

EXPOSE 8081

ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
