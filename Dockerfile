# Build stage: Maven + Temurin 26 JDK
FROM eclipse-temurin:26-jdk-noble AS builder
WORKDIR /app

# Descargar dependencias primero (aprovecha caché de capas)
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x ./mvnw && ./mvnw dependency:go-offline -B

# Copiar fuentes y compilar (sin tests — se ejecutan en el pipeline CI)
COPY src ./src
RUN ./mvnw clean package -DskipTests -B

# ─────────────────────────────────────────────
# Runtime stage: imagen mínima con solo el JAR
# ─────────────────────────────────────────────
FROM eclipse-temurin:26-jre-noble
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8096
ENTRYPOINT ["java", "-jar", "app.jar"]
# Build stage: Maven + Temurin 26 JDK
