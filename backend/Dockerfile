# ============================================================
# Stage 1: Build — Maven 3.5.4 + JDK 17
# ============================================================
FROM eclipse-temurin:17-jdk-jammy AS build

ARG MAVEN_VERSION=3.5.4
ARG MAVEN_BASE_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates tar gzip \
    && mkdir -p /usr/share/maven /usr/share/maven/ref \
    && curl -fsSL -o /tmp/apache-maven.tar.gz \
         "${MAVEN_BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn \
    && rm -f /tmp/apache-maven.tar.gz \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1) Copy pom.xml
COPY pom.xml .

# 2) Download dependencies (cached unless pom.xml changes)
RUN mvn -B dependency:resolve dependency:resolve-plugins

# 3) Copy source code
COPY src ./src

# 4) Build the Spring Boot JAR
# 5) Generate the final JAR under target/
RUN mvn -B clean package -DskipTests \
    && mvn -version

# ============================================================
# Stage 2: Runtime — Java 17 only (no Maven, no source)
# ============================================================
FROM eclipse-temurin:17-jre-jammy AS runtime

WORKDIR /app

# Copy ONLY the generated JAR from the build stage
COPY --from=build /app/target/student-management-1.0.0.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
