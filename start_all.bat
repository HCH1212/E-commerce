@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
set "ROOT=%~dp0"

echo ========================================
echo   E-commerce One-Click Startup Script
echo ========================================
echo.

REM Step 1: Start Docker base services
echo [1/5] Starting Docker base services (MySQL, Redis, Consul, NATS)...
call "%ROOT%start.bat"
if %errorlevel% neq 0 (
    echo ERROR: Failed to start base services
    pause
    exit /b 1
)
echo.

REM Step 2: Start Frontend service
echo [2/5] Starting Frontend service...
start "Frontend Service" cmd /k "cd /d %ROOT%app\frontend && go run . || pause"
timeout /t 3 /nobreak >nul
echo OK: Frontend service started
echo.

REM Step 3: Start Product service
echo [3/5] Starting Product service...
start "Product Service" cmd /k "cd /d %ROOT%app\product && go run . || pause"
timeout /t 3 /nobreak >nul
echo OK: Product service started
echo.

REM Step 4: Initialize product data
echo [4/5] Initializing product data...
timeout /t 2 /nobreak >nul
docker compose exec -T mysql mysql --protocol=TCP -h127.0.0.1 -P3306 -uroot -p041212 < "%ROOT%app\product\default.sql"
if %errorlevel% neq 0 (
    echo WARNING: Product data initialization failed
) else (
    echo OK: Product data initialized
)
echo.

REM Step 5: Start other microservices
echo [5/5] Starting other services...
echo.

echo   Starting User service...
start "User Service" cmd /k "cd /d %ROOT%app\user && go run . || pause"
timeout /t 2 /nobreak >nul

echo   Starting Cart service...
start "Cart Service" cmd /k "cd /d %ROOT%app\cart && go run . || pause"
timeout /t 2 /nobreak >nul

echo   Starting Order service...
start "Order Service" cmd /k "cd /d %ROOT%app\order && go run . || pause"
timeout /t 2 /nobreak >nul

echo   Starting Payment service...
start "Payment Service" cmd /k "cd /d %ROOT%app\payment && go run . || pause"
timeout /t 2 /nobreak >nul

echo   Starting Checkout service...
start "Checkout Service" cmd /k "cd /d %ROOT%app\checkout && go run . || pause"
timeout /t 2 /nobreak >nul

echo   Starting Email service...
start "Email Service" cmd /k "cd /d %ROOT%app\email && go run . || pause"
timeout /t 2 /nobreak >nul

echo   Starting Casbin service...
start "Casbin Service" cmd /k "cd /d %ROOT%app\casbin && go run . || pause"
timeout /t 2 /nobreak >nul

echo   Starting Eino service...
start "Eino Service" cmd /k "cd /d %ROOT%app\eino && go run . || pause"
timeout /t 2 /nobreak >nul

echo.
echo ========================================
echo   All services started successfully!
echo ========================================
echo.
echo Waiting for all services to become ready... (about 30s)
timeout /t 30 /nobreak >nul
echo.
echo Service URLs:
echo   - Frontend: http://localhost:8080
echo   - Consul: http://localhost:8500
echo   - Admin: http://localhost:8080/admin/products
echo   - MySQL: localhost:3306 (root / 041212)
echo.
echo Tips:
echo   - All services are running in separate windows
echo   - Run stop_all.bat to stop all services
echo   - Check service logs in corresponding windows
echo.
