# ============================================================
# Student Management System - Windows Environment Checker
# Non-destructive. Does NOT install software, delete DBs,
# remove Docker images, or reset Git.
# ============================================================

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

function Write-Section($title) {
    Write-Host ""
    Write-Host "==== $title ====" -ForegroundColor Cyan
}

function Test-CommandExists($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Show-Result($ok, $label, $detail) {
    if ($ok) {
        Write-Host "[OK]   $label" -ForegroundColor Green
        if ($detail) { Write-Host "       $detail" }
    } else {
        Write-Host "[FAIL] $label" -ForegroundColor Red
        if ($detail) { Write-Host "       $detail" }
    }
}

Write-Host "Student Management - setup verification"
Write-Host "Project root: $projectRoot"
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# ------------------------------------------------------------
Write-Section "1) Required tools"
# ------------------------------------------------------------

$javaOk = $false
if (Test-CommandExists "java") {
    $javaOut = & java -version 2>&1 | Out-String
    $javaOk = $javaOut -match 'version "17\.'
    Show-Result $javaOk "Java 17" ($javaOut.Trim() -replace "`r?`n", " | ")
} else {
    Show-Result $false "Java 17" "java not found on PATH"
}

$mvnOk = $false
if (Test-CommandExists "mvn") {
    $mvnOut = & mvn -version 2>&1 | Out-String
    $mvnOk = $mvnOut -match "Apache Maven 3\.5\.4"
    Show-Result $mvnOk "Maven 3.5.4" ($mvnOut.Split("`n")[0].Trim())
    if (-not $mvnOk -and $mvnOut -match "Apache Maven") {
        Write-Host "       Detected Maven, but required exact version is 3.5.4" -ForegroundColor Yellow
    }
} else {
    Show-Result $false "Maven 3.5.4" "mvn not found on PATH"
}

$nodeOk = $false
if (Test-CommandExists "node") {
    $nodeVer = (& node -v 2>&1).ToString().Trim()
    $nodeOk = $true
    Show-Result $true "Node.js" $nodeVer
} else {
    Show-Result $false "Node.js" "node not found on PATH"
}

$npmOk = $false
if (Test-CommandExists "npm") {
    $npmVer = (& npm -v 2>&1).ToString().Trim()
    $npmOk = $true
    Show-Result $true "npm" $npmVer
} else {
    Show-Result $false "npm" "npm not found on PATH"
}

$gitOk = $false
if (Test-CommandExists "git") {
    $gitVer = (& git --version 2>&1).ToString().Trim()
    $gitOk = $true
    Show-Result $true "Git" $gitVer
} else {
    Show-Result $false "Git" "git not found on PATH"
}

$dockerOk = $false
if (Test-CommandExists "docker") {
    $dockerVer = (& docker --version 2>&1).ToString().Trim()
    Show-Result $true "Docker CLI" $dockerVer
    $dockerInfo = & docker info 2>&1 | Out-String
    $dockerOk = $LASTEXITCODE -eq 0
    Show-Result $dockerOk "Docker daemon" $(if ($dockerOk) { "Docker Desktop is running" } else { "Docker Desktop is not running or not accessible" })
} else {
    Show-Result $false "Docker" "docker not found on PATH"
}

$psqlOk = $false
$psqlCmd = $null
if (Test-CommandExists "psql") {
    $psqlCmd = "psql"
} elseif (Test-Path "C:\Program Files\PostgreSQL\18\bin\psql.exe") {
    $psqlCmd = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
}

if ($psqlCmd) {
    $psqlVer = (& $psqlCmd --version 2>&1).ToString().Trim()
    $psqlOk = $psqlVer -match "18"
    Show-Result $true "psql" $psqlVer
    if (-not $psqlOk) {
        Write-Host "       PostgreSQL 18 is preferred for this project" -ForegroundColor Yellow
    }
} else {
    Show-Result $false "PostgreSQL/psql" "psql not found (install PostgreSQL 18 and add bin to PATH)"
}

# ------------------------------------------------------------
Write-Section "2) Environment variables / PATH helpers"
# ------------------------------------------------------------

Show-Result ([bool]$env:JAVA_HOME) "JAVA_HOME" $(if ($env:JAVA_HOME) { $env:JAVA_HOME } else { "Not set (recommended for local Maven builds)" })
Show-Result ([bool]$env:MAVEN_HOME) "MAVEN_HOME" $(if ($env:MAVEN_HOME) { $env:MAVEN_HOME } else { "Optional if mvn is already on PATH" })

Write-Host "where java :"
where.exe java 2>$null
Write-Host "where mvn  :"
where.exe mvn 2>$null
Write-Host "where node :"
where.exe node 2>$null
Write-Host "where git  :"
where.exe git 2>$null
Write-Host "where docker :"
where.exe docker 2>$null

# ------------------------------------------------------------
Write-Section "3) Project files"
# ------------------------------------------------------------

$required = @(
    ".gitignore",
    "README.md",
    "backend\pom.xml",
    "backend\Dockerfile",
    "backend\src\main\resources\application.properties",
    "backend\src\main\java\com\example\studentmanagement\StudentManagementApplication.java",
    "frontend\package.json",
    "frontend\Dockerfile",
    "frontend\nginx.conf",
    "frontend\src\services\studentService.js",
    "frontend\src\App.jsx"
)

$filesOk = $true
foreach ($rel in $required) {
    $full = Join-Path $projectRoot $rel
    $exists = Test-Path $full
    if (-not $exists) { $filesOk = $false }
    Show-Result $exists $rel ""
}

# ------------------------------------------------------------
Write-Section "4) Git branch"
# ------------------------------------------------------------

$branchOk = $false
if ($gitOk -and (Test-Path (Join-Path $projectRoot ".git"))) {
    $branch = (& git -C $projectRoot branch --show-current 2>&1).ToString().Trim()
    $branchOk = $branch -eq "feature/Student-Management"
    Show-Result $branchOk "Current branch" $branch
    if (-not $branchOk) {
        Write-Host "       Expected: feature/Student-Management" -ForegroundColor Yellow
        Write-Host "       Run: git checkout feature/Student-Management" -ForegroundColor Yellow
    }
} else {
    Show-Result $false "Git repository" "Not a git checkout or git unavailable"
}

# ------------------------------------------------------------
Write-Section "5) Application configuration (read-only)"
# ------------------------------------------------------------

$appProps = Join-Path $projectRoot "backend\src\main\resources\application.properties"
if (Test-Path $appProps) {
    Write-Host "application.properties datasource settings:"
    Select-String -Path $appProps -Pattern "spring.datasource|ddl-auto|server.port" | ForEach-Object { Write-Host "  $($_.Line)" }
}

$studentService = Join-Path $projectRoot "frontend\src\services\studentService.js"
if (Test-Path $studentService) {
    Write-Host "Axios baseURL:"
    Select-String -Path $studentService -Pattern "baseURL" | ForEach-Object { Write-Host "  $($_.Line.Trim())" }
}

# ------------------------------------------------------------
Write-Section "6) PostgreSQL reachability (optional check)"
# ------------------------------------------------------------

if ($psqlCmd) {
    $env:PGPASSWORD = "postgres"
    $dbCheck = & $psqlCmd -U postgres -h localhost -p 5432 -d studentdb -c "SELECT current_database();" 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Show-Result $true "Database studentdb" "Reachable on localhost:5432"
    } else {
        Show-Result $false "Database studentdb" "Cannot connect. Create DB or start PostgreSQL service."
        Write-Host $dbCheck
    }
} else {
    Write-Host "Skipped (psql not available)"
}

# ------------------------------------------------------------
Write-Section "Summary"
# ------------------------------------------------------------

$allCore = $javaOk -and $mvnOk -and $nodeOk -and $npmOk -and $gitOk -and $filesOk
Show-Result $allCore "Core local-dev readiness" $(if ($allCore) { "Ready to build/run without Docker" } else { "Fix FAIL items above first" })
Show-Result $dockerOk "Docker readiness" $(if ($dockerOk) { "Ready for container builds/runs" } else { "Optional until you reach Docker steps" })

Write-Host ""
Write-Host "This script did not install software, change Git, or modify databases."
Write-Host "Next: follow README.md section 'Running the Application on a New Windows Machine'"
