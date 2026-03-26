@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
set "ROOT=%~dp0"

echo ========================================
echo   E-commerce One-Click Bootstrap Script
echo ========================================
echo.

echo [1/3] Starting Docker base services (MySQL, Redis, Consul, NATS)...
docker compose up -d
if %errorlevel% neq 0 (
    echo ERROR: Failed to start Docker base services
    pause
    exit /b 1
)
echo OK: Docker base services started
echo.

echo [2/3] Waiting for MySQL to become ready...
set "MYSQL_READY=0"
for /l %%i in (1,1,30) do (
    docker compose exec -T mysql mysqladmin ping -h127.0.0.1 -uroot -p041212 --silent >nul 2>&1
    if !errorlevel! equ 0 (
        set "MYSQL_READY=1"
        goto :mysql_ready
    )
    timeout /t 2 /nobreak >nul
)

:mysql_ready
if "!MYSQL_READY!" neq "1" (
    echo ERROR: MySQL startup timed out
    pause
    exit /b 1
)
echo OK: MySQL is ready
echo.

echo [3/3] Initializing databases...
docker compose exec -T mysql mysql --protocol=TCP -h127.0.0.1 -P3306 -uroot -p041212 < "%ROOT%init_databases.sql"
if %errorlevel% neq 0 (
    echo ERROR: Database initialization failed
    pause
    exit /b 1
)
echo OK: Database initialization completed
echo.

echo ========================================
echo   Base environment is ready
echo ========================================
echo.
echo Next, run the following commands in separate terminals to start each microservice:
echo.
echo   1. make user_run
echo   2. make product_run
echo   3. make cart_run
echo   4. make order_run
echo   5. make payment_run
echo   6. make checkout_run
echo   7. make email_run
echo   8. make casbin_run
echo   9. make eino_run
echo  10. make frontend_run
echo.
echo After all services are up, open: http://localhost:8080
echo.
echo Useful dashboards:
echo   - Consul: http://localhost:8500
echo   - MySQL: localhost:3306 (user: root, password: 041212)
echo.
