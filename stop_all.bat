@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo   E-commerce One-Click Shutdown Script
echo ========================================
echo.

echo Stopping all services...
echo.

REM Step 1: Stop backend services first (keep Frontend running)
echo [1/3] Stopping backend services (keeping Frontend)...
echo.

echo   Stopping User service...
taskkill /FI "WINDOWTITLE eq User Service*" /F >nul 2>&1

echo   Stopping Product service...
taskkill /FI "WINDOWTITLE eq Product Service*" /F >nul 2>&1

echo   Stopping Cart service...
taskkill /FI "WINDOWTITLE eq Cart Service*" /F >nul 2>&1

echo   Stopping Order service...
taskkill /FI "WINDOWTITLE eq Order Service*" /F >nul 2>&1

echo   Stopping Payment service...
taskkill /FI "WINDOWTITLE eq Payment Service*" /F >nul 2>&1

echo   Stopping Checkout service...
taskkill /FI "WINDOWTITLE eq Checkout Service*" /F >nul 2>&1

echo   Stopping Email service...
taskkill /FI "WINDOWTITLE eq Email Service*" /F >nul 2>&1

echo   Stopping Casbin service...
taskkill /FI "WINDOWTITLE eq Casbin Service*" /F >nul 2>&1

echo   Stopping Eino service...
taskkill /FI "WINDOWTITLE eq Eino Service*" /F >nul 2>&1

timeout /t 2 /nobreak >nul

REM Force-clean remaining Go processes (exclude frontend-related tree)
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq go.exe" /FO LIST ^| find "PID:"') do (
    set "pid=%%a"
    wmic process where "ParentProcessId=!pid!" get CommandLine 2>nul | find /I "frontend" >nul
    if errorlevel 1 (
        taskkill /F /PID %%a >nul 2>&1
    )
)

REM Clean compiled service binaries (excluding frontend)
taskkill /F /IM product.exe >nul 2>&1
taskkill /F /IM user.exe >nul 2>&1
taskkill /F /IM cart.exe >nul 2>&1
taskkill /F /IM order.exe >nul 2>&1
taskkill /F /IM payment.exe >nul 2>&1
taskkill /F /IM checkout.exe >nul 2>&1
taskkill /F /IM email.exe >nul 2>&1
taskkill /F /IM casbin.exe >nul 2>&1
taskkill /F /IM eino.exe >nul 2>&1

echo OK: Backend services stopped
echo.

REM Step 2: Stop Frontend service last
echo [2/3] Stopping Frontend service...
echo.
taskkill /FI "WINDOWTITLE eq Frontend Service*" /F >nul 2>&1
timeout /t 1 /nobreak >nul
taskkill /F /IM frontend.exe >nul 2>&1

REM Final cleanup for any leftover go.exe
taskkill /F /IM go.exe >nul 2>&1

echo OK: Frontend service stopped
echo.

REM Step 3: Stop Docker services
echo [3/3] Stopping Docker services...
echo.
docker compose down
if %errorlevel% equ 0 (
    echo OK: Docker services stopped
) else (
    echo WARNING: Docker service shutdown error
)

echo.
echo ========================================
echo   All services stopped!
echo ========================================
echo.
echo Tips:
echo   - All service processes terminated
echo   - All service windows closed
echo   - Docker containers stopped
echo   - Run start_all.bat to restart
echo.
pause
