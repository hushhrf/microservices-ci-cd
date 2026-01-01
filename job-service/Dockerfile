# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Copy the pre-built JAR
COPY target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-Xmx128m", "-jar", "app.jar"]
