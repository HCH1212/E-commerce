@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo   E-commerce 项目一键关闭脚本
echo ========================================
echo.

echo Stopping all services...
echo.

:: 步骤 1: 先关闭其他微服务（保留 Frontend）
echo.
echo [1/3] Stopping backend services (keeping Frontend)...
echo.

:: 关闭其他服务的窗口（通过窗口标题）
echo   Stopping User Service...
taskkill /FI "WINDOWTITLE eq User Service*" /F >NUL 2>&1

echo   Stopping Product Service...
taskkill /FI "WINDOWTITLE eq Product Service*" /F >NUL 2>&1

echo   Stopping Cart Service...
taskkill /FI "WINDOWTITLE eq Cart Service*" /F >NUL 2>&1

echo   Stopping Order Service...
taskkill /FI "WINDOWTITLE eq Order Service*" /F >NUL 2>&1

echo   Stopping Payment Service...
taskkill /FI "WINDOWTITLE eq Payment Service*" /F >NUL 2>&1

echo   Stopping Checkout Service...
taskkill /FI "WINDOWTITLE eq Checkout Service*" /F >NUL 2>&1

echo   Stopping Email Service...
taskkill /FI "WINDOWTITLE eq Email Service*" /F >NUL 2>&1

echo   Stopping Casbin Service...
taskkill /FI "WINDOWTITLE eq Casbin Service*" /F >NUL 2>&1

echo   Stopping Eino Service...
taskkill /FI "WINDOWTITLE eq Eino Service*" /F >NUL 2>&1

:: 等待服务正常关闭
timeout /t 2 /nobreak >nul

:: 强制清理可能残留的 Go 进程（排除 frontend）
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq go.exe" /FO LIST ^| find "PID:"') do (
    set pid=%%a
    wmic process where "ParentProcessId=!pid!" get CommandLine 2>NUL | find /I "frontend" >NUL
    if errorlevel 1 (
        taskkill /F /PID %%a >NUL 2>&1
    )
)

:: 清理其他编译产物（排除 frontend）
taskkill /F /IM product.exe >NUL 2>&1
taskkill /F /IM user.exe >NUL 2>&1
taskkill /F /IM cart.exe >NUL 2>&1
taskkill /F /IM order.exe >NUL 2>&1
taskkill /F /IM payment.exe >NUL 2>&1
taskkill /F /IM checkout.exe >NUL 2>&1
taskkill /F /IM email.exe >NUL 2>&1
taskkill /F /IM casbin.exe >NUL 2>&1
taskkill /F /IM eino.exe >NUL 2>&1

echo OK: Backend services stopped
echo.

:: 步骤 2: 最后关闭 Frontend 服务
echo.
echo [2/3] Stopping Frontend service...
echo.
taskkill /FI "WINDOWTITLE eq Frontend Service*" /F >NUL 2>&1
timeout /t 1 /nobreak >nul
taskkill /F /IM frontend.exe >NUL 2>&1

:: 最后强制清理所有剩余的 go.exe 进程
taskkill /F /IM go.exe >NUL 2>&1

echo OK: Frontend service stopped
echo.

:: 步骤 3: 关闭 Docker 服务
echo.
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
