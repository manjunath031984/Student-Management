# Student Management System

## 1. Project title

**Student Management System** — a localhost-only full-stack CRUD web application for learning Spring Boot, React, PostgreSQL, and Docker (without Docker Compose).

## 2. Project overview

This project manages student records through a React user interface and a Spring Boot REST API backed by PostgreSQL running on Windows.

It is designed for local development and learning. Local Docker still does **not** use Docker Compose. GCP/GKE deployment is documented in [`terraform/README.md`](terraform/README.md) and orchestrated by the root `Jenkinsfile`.

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

# Running the Application on a New Windows Machine

This section is a complete from-scratch guide for another Windows PC that has **nothing installed except Windows**.

**Goals**

- Clone this repository
- Run on localhost without rewriting the app
- Support both:
  1. Direct Windows run (`mvn` + `npm`)
  2. Docker containers (no Compose)
- Keep PostgreSQL on Windows (not in Docker)

**Important naming facts from this repository**

| Item | Actual value |
|------|----------------|
| GitHub repo | `https://github.com/manjunath031984/Student-Management` |
| Default branch | `main` |
| Development branch | `feature/Student-Management` |
| Local folder after clone | `Student-Management` |
| Backend API base | `http://localhost:8080/api` |
| Axios `baseURL` | hard-coded in `frontend/src/services/studentService.js` as `http://localhost:8080/api` |
| CORS origins | `http://localhost:5173`, `http://localhost:3000` |
| DB defaults | `localhost:5432/studentdb`, user/password `postgres`/`postgres` |
| Table name | `students` |
| ID strategy | `GenerationType.IDENTITY` + PostgreSQL sequence |

> Git does **not** allow spaces in branch names. Use `feature/Student-Management` (not `feature/Student Management`).

**THIS PROJECT DOES NOT USE DOCKER COMPOSE.**

---

## A. System requirements and installs

### 1) Git

- **Why:** Clone the GitHub repository
- **Version:** Latest stable
- **Download:** https://git-scm.com/download/win
- **Install:** Next → include Git from command line
- **Verify:**

```powershell
git --version
```

Expected:

```text
git version 2.x.x
```

### 2) Java 17 JDK

- **Why:** Compile/run Spring Boot
- **Version:** **17 only** (not 21)
- **Download:** Eclipse Temurin 17 JDK  
  https://adoptium.net/temurin/releases/?version=17
- **Install:** Install JDK 17 and note path, example:  
  `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot`
- **Verify:**

```powershell
java -version
```

Expected:

```text
openjdk version "17.0.x"
```

### 3) Maven 3.5.4

- **Why:** Build backend exactly as this project requires
- **Version:** **3.5.4 exactly**
- **Download:**  
  https://archive.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.zip
- **Install:**
  1. Extract to e.g. `C:\apache-maven-3.5.4` or `D:\apache-maven-3.5.4`
  2. Add `...\apache-maven-3.5.4\bin` to PATH
- **Verify:**

```powershell
mvn -version
```

Expected:

```text
Apache Maven 3.5.4
Java version: 17.x
```

### 4) PostgreSQL 18

- **Why:** Application database
- **Version:** 18
- **Download:** https://www.postgresql.org/download/windows/
- **During install set:**
  - Port: `5432`
  - Superuser: `postgres`
  - Password: `postgres` (to match this project defaults)
- **Verify:**

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" --version
```

Expected:

```text
psql (PostgreSQL) 18.x
```

### 5) Node.js LTS (+ npm)

- **Why:** Run React/Vite locally
- **Version:** Current Node LTS (npm included)
- **Download:** https://nodejs.org/
- **Verify:**

```powershell
node -v
npm -v
```

### 6) Docker Desktop

- **Why:** Build/run backend and frontend images
- **Download:** https://www.docker.com/products/docker-desktop/
- **Install:** Enable WSL2 backend if prompted, then start Docker Desktop
- **Verify:**

```powershell
docker --version
docker info
```

### 7) Optional tools

| Tool | Why |
|------|-----|
| IntelliJ IDEA | Backend editing |
| VS Code / Cursor | Frontend editing |
| pgAdmin | PostgreSQL GUI |
| Postman | API testing |

---

## B. Windows environment variables

This project needs:

1. `JAVA_HOME` → JDK 17 path (recommended)
2. Maven `bin` on `PATH`
3. Java `bin` on `PATH`
4. Node/npm/Git/Docker on `PATH`

`MAVEN_HOME` is optional if `mvn` already works.

### Set for current PowerShell session

```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:PATH = "$env:JAVA_HOME\bin;D:\apache-maven-3.5.4\bin;" + $env:PATH
```

Adjust paths to match your machine.

### Permanent setup (GUI)

1. Start → search **Environment Variables**
2. System variables → New/Edit:
   - `JAVA_HOME` = JDK 17 folder
3. Edit `Path` and add:
   - `%JAVA_HOME%\bin`
   - `C:\apache-maven-3.5.4\bin` (or your Maven path)
   - PostgreSQL `bin` if desired: `C:\Program Files\PostgreSQL\18\bin`

### Verify

```powershell
echo $env:JAVA_HOME
echo $env:MAVEN_HOME
where.exe java
where.exe mvn
where.exe node
where.exe git
where.exe docker
```

---

## C. Clone GitHub repository and checkout feature branch

```powershell
cd D:\
git clone https://github.com/manjunath031984/Student-Management.git
cd Student-Management
git branch -a
git checkout feature/Student-Management
git status
git branch --show-current
```

Expected current branch:

```text
feature/Student-Management
```

Do **not** develop on `main`.

### Quick environment check script

From project root:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

`setup.ps1` only checks tools/files/config. It does **not** install software or delete data.

---

## D. Verify project files (actual structure)

After clone you should see:

```text
Student-Management/
├── backend/
│   ├── src/
│   ├── pom.xml
│   ├── Dockerfile
│   └── .dockerignore
├── frontend/
│   ├── src/
│   ├── public/
│   ├── package.json
│   ├── package-lock.json
│   ├── vite.config.js
│   ├── index.html
│   ├── Dockerfile
│   ├── nginx.conf
│   └── .dockerignore
├── .gitignore
├── README.md
└── setup.ps1
```

Confirm key files:

```powershell
Test-Path .\backend\pom.xml
Test-Path .\backend\Dockerfile
Test-Path .\frontend\package.json
Test-Path .\frontend\Dockerfile
Test-Path .\frontend\nginx.conf
Test-Path .\README.md
```

All should return `True`.

---

## E. PostgreSQL setup and `studentdb`

### Start service

```powershell
Get-Service -Name "*postgres*"
# If stopped:
Start-Service postgresql-x64-18
```

### Create database (psql)

```powershell
$env:PGPASSWORD = "postgres"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -c "CREATE DATABASE studentdb;"
```

If it already exists, that is fine.

### Verify database

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -c "\l studentdb"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -d studentdb -c "\dn"
```

### pgAdmin method

1. Open pgAdmin
2. Connect to local server (`localhost:5432`, user `postgres`)
3. Right-click **Databases** → **Create** → **Database**
4. Name: `studentdb`
5. Save

### Connect

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -d studentdb
```

---

## F. Database configuration used by this app

Inspected file: `backend/src/main/resources/application.properties`

Actual settings:

```properties
server.port=8080
spring.datasource.url=jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:studentdb}
spring.datasource.username=${DB_USERNAME:postgres}
spring.datasource.password=${DB_PASSWORD:postgres}
spring.jpa.hibernate.ddl-auto=update
```

### Meaning

| Mode | Values |
|------|--------|
| Direct Windows (`mvn spring-boot:run`) | defaults → `localhost:5432/studentdb` |
| Docker backend | set `DB_HOST=host.docker.internal` (and other `DB_*` as needed) |

No `.env` file is required for local Windows run.

---

## G. Backend setup (without Docker)

```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:PATH = "$env:JAVA_HOME\bin;C:\apache-maven-3.5.4\bin;" + $env:PATH

cd D:\Student-Management\backend
mvn clean
mvn clean package
mvn spring-boot:run
```

Backend URL: http://localhost:8080

Verify:

```powershell
curl.exe http://localhost:8080/api/students
```

Empty DB expected response:

```json
[]
```

---

## H. When the `students` table is created

This app uses:

```properties
spring.jpa.hibernate.ddl-auto=update
```

So Hibernate creates/updates the `students` table **when Spring Boot starts successfully** and connects to PostgreSQL.

Entity mapping:

- Table: `students`
- PK: `id` (`GenerationType.IDENTITY`)
- Sequence typically: `students_id_seq`

### Verify after backend start

```powershell
$env:PGPASSWORD = "postgres"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -d studentdb -c "\dt"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -d studentdb -c "\d students"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -d studentdb -c "SELECT * FROM students;"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -d studentdb -c "SELECT pg_get_serial_sequence('students','id');"
```

Also:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';
```

---

## I. Backend API testing (before React)

Base URL: `http://localhost:8080/api/students`  
Header: `Content-Type: application/json`

### 1) POST create (201)

```powershell
curl.exe -X POST http://localhost:8080/api/students `
  -H "Content-Type: application/json" `
  -d "{\"name\":\"Rahul Sharma\",\"email\":\"rahul.sharma@example.com\",\"course\":\"Computer Science\",\"age\":21}"
```

Expected response shape:

```json
{
  "id": 1,
  "name": "Rahul Sharma",
  "email": "rahul.sharma@example.com",
  "course": "Computer Science",
  "age": 21
}
```

### 2) GET all (200)

```powershell
curl.exe http://localhost:8080/api/students
```

### 3) GET by ID (200)

```powershell
curl.exe http://localhost:8080/api/students/1
```

### 4) PUT update (200)

```powershell
curl.exe -X PUT http://localhost:8080/api/students/1 `
  -H "Content-Type: application/json" `
  -d "{\"name\":\"Priya Reddy\",\"email\":\"priya.reddy@example.com\",\"course\":\"Information Technology\",\"age\":22}"
```

### 5) DELETE (204)

```powershell
curl.exe -X DELETE http://localhost:8080/api/students/1 -i
```

### Invalid body (400) / missing ID (404)

```powershell
curl.exe -X POST http://localhost:8080/api/students -H "Content-Type: application/json" -d "{\"name\":\"\",\"email\":\"bad\",\"course\":\"\",\"age\":0}"
curl.exe http://localhost:8080/api/students/99999
```

---

## J. Frontend setup (without Docker)

Axios is configured in:

`frontend/src/services/studentService.js`

Actual value:

```javascript
baseURL: 'http://localhost:8080/api'
```

No `VITE_API_BASE_URL` file is required.

```powershell
cd D:\Student-Management\frontend
npm install
npm run dev
```

Open: http://localhost:5173

---

## K. CORS (already configured)

File: `backend/.../config/CorsConfig.java`

Allowed origins:

- `http://localhost:5173` (Vite)
- `http://localhost:3000` (Nginx Docker UI)

No change needed for standard localhost setup.

---

## L. Run complete app without Docker

| Terminal | What to run |
|----------|-------------|
| 1 | PostgreSQL service running |
| 2 | `cd backend` → `mvn spring-boot:run` |
| 3 | `cd frontend` → `npm run dev` |

Architecture:

```text
Browser
  ↓
React  http://localhost:5173
  ↓ Axios
Spring Boot  http://localhost:8080
  ↓
PostgreSQL  localhost:5432 / studentdb
```

---

## M. Docker setup (no Compose)

PostgreSQL stays on Windows.  
Backend/frontend are separate images and separate `docker run` commands.

### Build backend

Inspected `backend/Dockerfile`: multi-stage, Maven **3.5.4** + JDK **17** → JRE **17**.

```powershell
cd D:\Student-Management\backend
docker build -t student-management-backend:1.0 .
docker images student-management-backend
```

### Build frontend

Inspected `frontend/Dockerfile`: Node build → Nginx runtime + `nginx.conf`.

```powershell
cd D:\Student-Management\frontend
docker build -t student-management-frontend:1.0 .
docker images student-management-frontend
```

If registry timeout occurs:

```powershell
docker build --pull=false -t student-management-backend:1.0 .
docker build --pull=false -t student-management-frontend:1.0 .
```

### Run backend container

Stop local `mvn spring-boot:run` first if port 8080 is busy.

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

Why `host.docker.internal`? Inside Docker, `localhost` is the container, not Windows PostgreSQL.

### Run frontend container

```powershell
docker run -d `
  --name student-management-frontend `
  -p 3000:80 `
  student-management-frontend:1.0
```

Open: http://localhost:3000

### Why frontend API still works from Docker UI

The browser (on Windows) calls `http://localhost:8080/api`.  
Nginx only serves static files; API calls are browser → Windows host port 8080, not Nginx → container localhost.

### Verify Docker

```powershell
docker ps
docker images
docker logs student-management-backend
docker logs student-management-frontend
docker inspect student-management-backend
curl.exe http://localhost:8080/api/students
curl.exe http://localhost:3000/
```

Cleanup:

```powershell
docker rm -f student-management-backend student-management-frontend
```

---

## N. Troubleshooting (common problems)

| # | Problem | Cause | Diagnose | Solution | Verify |
|---|---------|-------|----------|----------|--------|
| 1 | `java` not recognized | JDK not installed/PATH | `where java` | Install JDK 17, set PATH/`JAVA_HOME` | `java -version` |
| 2 | `mvn` not recognized | Maven not on PATH | `where mvn` | Add Maven 3.5.4 `bin` to PATH | `mvn -version` |
| 3 | Wrong Maven version | Newer Maven installed | `mvn -version` | Use 3.5.4 first on PATH | shows `3.5.4` |
| 4 | Wrong Java version | Java 21 default | `java -version` | Point `JAVA_HOME` to JDK 17 | shows `17` |
| 5 | PostgreSQL not running | Service stopped | `Get-Service *postgres*` | `Start-Service postgresql-x64-18` | service Running |
| 6 | Password incorrect | Different install password | psql login fails | Use install password or reset; project default is `postgres` | connect works |
| 7 | DB missing | Not created | `\l` | `CREATE DATABASE studentdb;` | `\l studentdb` |
| 8 | 5432 in use | Another DB/instance | `netstat -ano | findstr :5432` | Stop conflicting service or use correct port | connect on 5432 |
| 9 | 8080 in use | Another Spring/Docker process | `netstat -ano | findstr :8080` | Stop process/container | backend starts |
| 10 | 5173 in use | Another Vite app | browser/port check | `npm run dev -- --port 5174` (also update CORS if needed) | UI loads |
| 11 | 3000 in use | Old frontend container | `docker ps` | `docker rm -f student-management-frontend` | `:3000` free |
| 12 | Boot cannot connect DB | Wrong host/creds/service | backend logs | Fix PostgreSQL + defaults | API returns `[]` |
| 13 | Table not created | Boot failed before JPA | `\dt` + logs | Fix DB connection, restart Boot | `\d students` |
| 14 | 404 student not found | Bad ID | GET by id | Use existing id | 200 |
| 15 | React cannot reach API | Backend down | DevTools Network | Start backend on 8080 | GET `/api/students` 200 |
| 16 | CORS error | Origin not allowed | browser console | Use 5173/3000; rebuild backend if CORS missing | no CORS error |
| 17 | `npm install` fails | Network/node issue | npm log | Retry, use Node LTS | `node_modules` created |
| 18 | `npm run dev` fails | dependency/port | terminal error | Reinstall deps / free port | UI on 5173 |
| 19 | Docker build fails | Desktop/network | build output | Start Docker; retry `--pull=false` | image listed |
| 20 | Container exits immediately | app crash | `docker logs ...` | Fix DB env vars / port conflicts | `docker ps` shows Up |
| 21 | Docker backend DB fail | used localhost | logs show refused | use `DB_HOST=host.docker.internal` | API 200 |
| 22 | host.docker.internal issue | Docker Desktop DNS | logs/ping from container | Ensure Docker Desktop running on Windows | DB connects |
| 23 | Nginx route 404 | missing try_files | open `/add` | Ensure `nginx.conf` has SPA fallback | `/add` returns index |
| 24 | Git branch problems | wrong branch/name | `git branch --show-current` | `git checkout feature/Student-Management` | correct branch |

---

## O. Clean-start procedure (fresh Windows PC)

1. Install Git, JDK 17, Maven 3.5.4, Node LTS, PostgreSQL 18, Docker Desktop  
2. Set `JAVA_HOME` + PATH  
3. `git clone https://github.com/manjunath031984/Student-Management.git`  
4. `cd Student-Management`  
5. `git checkout feature/Student-Management`  
6. Run `powershell -ExecutionPolicy Bypass -File .\setup.ps1`  
7. Start PostgreSQL service  
8. `CREATE DATABASE studentdb;`  
9. `cd backend` → `mvn clean package` → `mvn spring-boot:run`  
10. Verify `students` table  
11. Test REST APIs with curl/Postman  
12. `cd frontend` → `npm install` → `npm run dev`  
13. Verify UI at http://localhost:5173  
14. Stop local backend/frontend if moving to Docker ports  
15. `docker build` backend + frontend images  
16. `docker run` backend with `DB_HOST=host.docker.internal`  
17. `docker run` frontend `-p 3000:80`  
18. Verify http://localhost:3000 and http://localhost:8080/api/students  

---

## P. Final verification checklist

- [ ] Windows prerequisites installed  
- [ ] Java 17 installed  
- [ ] Maven 3.5.4 installed  
- [ ] Node.js installed  
- [ ] npm installed  
- [ ] Git installed  
- [ ] Docker Desktop installed  
- [ ] PostgreSQL 18 installed  
- [ ] GitHub repository cloned  
- [ ] `feature/Student-Management` checked out  
- [ ] `studentdb` created  
- [ ] PostgreSQL running  
- [ ] Backend builds  
- [ ] Backend starts  
- [ ] Student table created  
- [ ] POST works  
- [ ] GET works  
- [ ] PUT works  
- [ ] DELETE works  
- [ ] React starts  
- [ ] React connects to backend  
- [ ] UI works  
- [ ] Backend Docker image builds  
- [ ] Frontend Docker image builds  
- [ ] Backend Docker container works  
- [ ] Frontend Docker container works  
- [ ] Docker backend connects to PostgreSQL  
- [ ] README updated  

---

## Important reminders

1. **THIS PROJECT DOES NOT USE DOCKER COMPOSE.**
2. No `docker-compose.yml` / `compose.yaml` files are part of this project.
3. Java **17** and Maven **3.5.4** only.
4. PostgreSQL only (no MySQL/MongoDB).
5. No Spring Security / JWT / authentication.
6. Localhost learning project — not designed for cloud deployment.
