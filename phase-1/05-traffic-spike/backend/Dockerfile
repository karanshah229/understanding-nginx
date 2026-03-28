# Use a multi-stage build to keep the image small
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copy the pom.xml and source code
COPY pom.xml .
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Use a lightweight JRE image for the final container
FROM eclipse-temurin:17-jre
WORKDIR /app

# Copy the JAR from the build stage
COPY --from=build /app/target/onefile-springboot-1.0.0.jar app.jar

# Expose the port the app runs on
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
