# Student Management System

## 1. Project title

**Student Management System** — a localhost-only full-stack CRUD web application for learning Spring Boot, React, PostgreSQL, and Docker (without Docker Compose).

## 2. Project overview

This project manages student records through a React user interface and a Spring Boot REST API backed by PostgreSQL running on Windows.

It is designed for local development and learning. It does **not** use authentication, cloud services, Kubernetes, or Docker Compose.

## 3. Features

- Create a student
- View all students
- View a student by ID
- Update a student
- Delete a student
- Bean Validation on create/update
- React UI with loading, error, and success feedback
- Client-side form validation
- Multi-stage Docker images for backend and frontend
- Independent container runs (no Compose)

## 4. Architecture

### Runtime architecture (Docker)

```text
                         Browser
                            |
                            |
                  http://localhost:3000
                            |
                            v
                 React + Nginx Container
                         Port 80
                            |
                            |
                            v
                 Spring Boot Container
                       Port 8080
                            |
                            |
                  host.docker.internal
                            |
                            v
              PostgreSQL on Windows Host
                       Port 5432
```

### Backend layered architecture

```text
React
  |
  | Axios
  v
REST API
  |
  v
Controller
  |
  v
Service
  |
  v
Repository
  |
  v
PostgreSQL
```

### Package flow

```text
Controller → Service → Repository → PostgreSQL
```

The Controller never accesses the Repository directly.

## 5. Technology stack

### Frontend

- React (Vite)
- JavaScript
- Axios
- React Router
- Plain CSS
- Nginx (production container)

### Backend

- Java 17
- Spring Boot 3.2.x
- Maven 3.5.4
- Spring Web
- Spring Data JPA
- Hibernate
- Bean Validation

### Database

- PostgreSQL 18 (installed and running on Windows)

### Containerization

- Docker
- Multi-stage Dockerfiles
- **THIS PROJECT DOES NOT USE DOCKER COMPOSE**

## 6. Required software

- JDK **17**
- Apache Maven **3.5.4**
- Node.js LTS + npm
- PostgreSQL **18**
- Docker Desktop
- Git
- GitHub CLI (`gh`) optional but useful

## 7. Exact Java version

**Java 17**

Verify:

```powershell
java -version
```

Expected example:

```text
openjdk version "17.0.x"
```

Do **not** use Java 21 for this project.

Recommended Windows setup:

```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:PATH = "$env:JAVA_HOME\bin;D:\apache-maven-3.5.4\bin;" + $env:PATH
```

## 8. Exact Maven version

**Apache Maven 3.5.4**

Verify:

```powershell
mvn -version
```

Expected:

```text
Apache Maven 3.5.4
Java version: 17.x
```

## 9. PostgreSQL setup

1. Install PostgreSQL 18 on Windows.
2. Ensure the service is running.
3. Create the database:

```sql
CREATE DATABASE studentdb;
```

PowerShell example:

```powershell
$env:PGPASSWORD = "postgres"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -c "CREATE DATABASE studentdb;"
```

Default credentials used by this project:

| Setting  | Value      |
|----------|------------|
| Host     | localhost  |
| Port     | 5432       |
| Database | studentdb  |
| Username | postgres   |
| Password | postgres   |

## 10. Database configuration

File: `backend/src/main/resources/application.properties`

```properties
spring.datasource.url=jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:studentdb}
spring.datasource.username=${DB_USERNAME:postgres}
spring.datasource.password=${DB_PASSWORD:postgres}
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

### Local Windows defaults

- `DB_HOST=localhost`

### Docker overrides

- `DB_HOST=host.docker.internal`

This single configuration works for both:

1. Direct Spring Boot on Windows
2. Spring Boot inside Docker

## 11. Project structure

```text
student-app/
├── backend/
│   ├── src/
│   ├── pom.xml
│   ├── Dockerfile
│   └── .dockerignore
│
├── frontend/
│   ├── src/
│   ├── package.json
│   ├── Dockerfile
│   ├── nginx.conf
│   └── .dockerignore
│
├── .gitignore
└── README.md
```

### Backend Java packages

```text
com.example.studentmanagement
├── StudentManagementApplication.java
├── config/CorsConfig.java
├── controller/StudentController.java
├── service/StudentService.java
├── service/StudentServiceImpl.java
├── repository/StudentRepository.java
├── entity/Student.java
├── dto/StudentRequest.java
├── dto/StudentResponse.java
└── exception/
    ├── StudentNotFoundException.java
    └── GlobalExceptionHandler.java
```

## 12. Backend setup

```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:PATH = "$env:JAVA_HOME\bin;D:\apache-maven-3.5.4\bin;" + $env:PATH

cd D:\student-app\backend
mvn clean package
mvn spring-boot:run
```

Backend URL:

- http://localhost:8080

API base:

- http://localhost:8080/api/students

## 13. Frontend setup

```powershell
cd D:\student-app\frontend
npm install
npm run dev
```

Frontend URL:

- http://localhost:5173

Axios base URL:

- `http://localhost:8080/api`

## 14. REST API documentation

| Method | Endpoint | Description | Success status |
|--------|----------|-------------|----------------|
| GET | `/api/students` | List all students | 200 OK |
| GET | `/api/students/{id}` | Get student by ID | 200 OK |
| POST | `/api/students` | Create student | 201 CREATED |
| PUT | `/api/students/{id}` | Update student | 200 OK |
| DELETE | `/api/students/{id}` | Delete student | 204 NO CONTENT |

Error statuses:

| Case | Status |
|------|--------|
| Validation error | 400 BAD REQUEST |
| Student not found | 404 NOT FOUND |

## 15. API request examples

### Create student

```powershell
curl.exe -X POST http://localhost:8080/api/students `
  -H "Content-Type: application/json" `
  -d "{\"name\":\"John Doe\",\"email\":\"john.doe@example.com\",\"course\":\"Computer Science\",\"age\":21}"
```

### Get all students

```powershell
curl.exe http://localhost:8080/api/students
```

### Get by ID

```powershell
curl.exe http://localhost:8080/api/students/1
```

### Update student

```powershell
curl.exe -X PUT http://localhost:8080/api/students/1 `
  -H "Content-Type: application/json" `
  -d "{\"name\":\"John Updated\",\"email\":\"john.updated@example.com\",\"course\":\"Information Technology\",\"age\":22}"
```

### Delete student

```powershell
curl.exe -X DELETE http://localhost:8080/api/students/1 -i
```

## 16. API response examples

### Successful create (201)

```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john.doe@example.com",
  "course": "Computer Science",
  "age": 21
}
```

### Validation error (400)

```json
{
  "timestamp": "2026-08-14T10:54:43.492144",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "errors": [
    "email: Email must be a valid email address",
    "name: Name is required",
    "course: Course is required",
    "age: Age must be at least 1"
  ]
}
```

### Not found (404)

```json
{
  "timestamp": "2026-08-14T10:54:43.577095100",
  "status": 404,
  "error": "Not Found",
  "message": "Student not found with id: 99999"
}
```

## 17. Validation rules

| Field | Rules |
|-------|--------|
| name | required, max 100 characters |
| email | required, valid email, max 150 characters |
| course | required, max 100 characters |
| age | required, minimum 1, maximum 100 |

## 18. CORS configuration

Backend allows:

- `http://localhost:5173` (Vite development)
- `http://localhost:3000` (Nginx Docker frontend)

Configured in `CorsConfig.java` for `/api/**` with methods:

- GET, POST, PUT, DELETE, OPTIONS

## 19. Local development instructions

### Terminal 1 — PostgreSQL

Ensure PostgreSQL 18 is running and `studentdb` exists.

### Terminal 2 — Backend

```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:PATH = "$env:JAVA_HOME\bin;D:\apache-maven-3.5.4\bin;" + $env:PATH
cd D:\student-app\backend
mvn spring-boot:run
```

### Terminal 3 — Frontend

```powershell
cd D:\student-app\frontend
npm run dev
```

Open:

- UI: http://localhost:5173
- API: http://localhost:8080/api/students

## 20. Backend Dockerfile explanation

File: `backend/Dockerfile`

Multi-stage build:

1. **Build stage** — `eclipse-temurin:17-jdk-jammy`
   - Installs Maven **3.5.4**
   - Copies `pom.xml`
   - Downloads dependencies
   - Copies source
   - Runs `mvn clean package`
2. **Runtime stage** — `eclipse-temurin:17-jre-jammy`
   - Copies only the generated JAR
   - Exposes port `8080`
   - Runs `java -jar app.jar`

Final image does **not** contain Maven, source code, or build tools.

## 21. Frontend Dockerfile explanation

File: `frontend/Dockerfile`

Multi-stage build:

1. **Build stage** — `node:22-alpine`
   - `npm ci`
   - `npm run build` → `/app/dist`
2. **Runtime stage** — `nginx:1.27-alpine`
   - Copies production build into Nginx html directory
   - Copies `nginx.conf`
   - Exposes port `80`

Final image does **not** contain Node.js, npm, `node_modules`, or React source.

## 22. Multi-stage Docker build explanation

A multi-stage Dockerfile uses multiple `FROM` instructions:

- Earlier stages build artifacts
- The final stage copies only what is required to run

Benefits:

- Smaller production images
- No compilers/package managers in runtime
- Better security posture for learning/deployment demos

## 23. Docker build commands

```powershell
cd D:\student-app\backend
docker build -t student-management-backend:1.0 .

cd D:\student-app\frontend
docker build -t student-management-frontend:1.0 .

docker images
```

Expected images:

- `student-management-backend:1.0`
- `student-management-frontend:1.0`

If registry pulls time out, retry with:

```powershell
docker build --pull=false -t student-management-backend:1.0 .
docker build --pull=false -t student-management-frontend:1.0 .
```

## 24. Docker run commands

**IMPORTANT: THIS PROJECT DOES NOT USE DOCKER COMPOSE.**

PostgreSQL continues to run on Windows (not in Docker).

### Backend container

```powershell
docker run -d `
  --name student-management-backend `
  -p 8080:8080 `
  -e DB_HOST=host.docker.internal `
  -e DB_PORT=5432 `
  -e DB_NAME=studentdb `
  -e DB_USERNAME=postgres `
  -e DB_PASSWORD=postgres `
  student-management-backend:1.0
```

### Frontend container

```powershell
docker run -d `
  --name student-management-frontend `
  -p 3000:80 `
  student-management-frontend:1.0
```

URLs:

- Frontend: http://localhost:3000
- Backend API: http://localhost:8080/api/students

## 25. Docker verification commands

```powershell
docker ps
docker images
docker logs student-management-backend
docker logs student-management-frontend
docker inspect student-management-backend
```

Cleanup:

```powershell
docker stop student-management-backend
docker rm student-management-backend
docker stop student-management-frontend
docker rm student-management-frontend
```

Or:

```powershell
docker rm -f student-management-backend student-management-frontend
```

## 26. Docker troubleshooting

| Problem | Solution |
|---------|----------|
| `failed to connect to the docker API` | Start Docker Desktop and wait until it is ready |
| Backend cannot connect to PostgreSQL | Use `DB_HOST=host.docker.internal` (not `localhost`) |
| Port 8080 already in use | Stop local `mvn spring-boot:run` or other process on 8080 |
| Port 3000 already in use | Remove old frontend container: `docker rm -f student-management-frontend` |
| CORS errors from UI on `:3000` | Ensure backend image includes CORS for `http://localhost:3000` |
| Registry TLS timeout during build | Retry later or use `docker build --pull=false` |
| Frontend shows Network Error | Confirm backend container is healthy on `:8080` |

## 27. PostgreSQL Docker networking explanation

PostgreSQL runs on the Windows host, not inside Docker.

- Backend on Windows uses `localhost:5432`
- Backend in Docker cannot use container `localhost` to reach Windows PostgreSQL

Therefore Docker backend must reach the host network alias.

## 28. host.docker.internal explanation

`host.docker.internal` is a special DNS name provided by Docker Desktop on Windows/Mac that resolves to the host machine.

Flow:

```text
Spring Boot container
        |
        | JDBC
        v
host.docker.internal:5432
        |
        v
PostgreSQL on Windows
```

Without this, the container tries its own loopback interface and connection is refused.

## 29. Git branching strategy

```text
main
  |
  └── feature/Student-Management
          |
          └── all development work
```

Rules:

- Default branch: `main`
- All application development happens on `feature/Student-Management`
- Do **not** push application development directly to `main`
- Do **not** merge feature → main unless explicitly requested

> Note: Git does not allow spaces in branch names.  
> Requested name `feature/Student Management` is represented as `feature/Student-Management`.

## 30. Git commands

```powershell
cd D:\student-app
git status
git branch
git branch --show-current

# Ensure you are on the feature branch before committing
git checkout feature/Student-Management

git add .
git commit -m "feat: your message"
git push origin feature/Student-Management
```

## 31. Feature branch information

- Repository: https://github.com/manjunath031984/Student-Management
- Feature branch: `feature/Student-Management`
- Branch URL: https://github.com/manjunath031984/Student-Management/tree/feature/Student-Management
- Account: https://github.com/manjunath031984

## 32. Future enhancements

Possible next improvements (not implemented yet):

- Reset PostgreSQL ID sequence when all students are deleted (`TRUNCATE ... RESTART IDENTITY`)
- Search/filter students by name or course
- Pagination for large student lists
- Unit and integration tests
- OpenAPI/Swagger documentation
- Soft delete
- Unique email constraint

---

## Important reminders

1. **THIS PROJECT DOES NOT USE DOCKER COMPOSE.**
2. No `docker-compose.yml` / `compose.yaml` files are part of this project.
3. Java **17** and Maven **3.5.4** only.
4. PostgreSQL only (no MySQL/MongoDB).
5. No Spring Security / JWT / authentication.
6. Localhost learning project — not designed for cloud deployment.
