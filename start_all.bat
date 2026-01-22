@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo   E-commerce 项目一键启动脚本
echo ========================================
echo.

:: 步骤 1: 启动 Docker 基础服务
echo [1/5] 启动 Docker 基础服务 (MySQL, Redis, Consul, NATS)...
call start.bat
if %errorlevel% neq 0 (
    echo 错误: 基础服务启动失败
    pause
    exit /b 1
)
echo.

:: 步骤 2: 启动 Frontend 服务
echo [2/5] 启动 Frontend 服务...
start "Frontend Service" cmd /k "cd /d d:\goProjects\github\E-commerce\app\frontend && go run . || pause"
timeout /t 3 /nobreak >nul
echo ✓ Frontend 服务已启动
echo.

:: 步骤 3: 启动 Product 服务
echo [3/5] 启动 Product 服务...
start "Product Service" cmd /k "cd /d d:\goProjects\github\E-commerce\app\product && go run . || pause"
timeout /t 3 /nobreak >nul
echo ✓ Product 服务已启动
echo.

:: 步骤 4: 初始化商品数据
echo.
echo [4/5] Initializing product data...
timeout /t 2 /nobreak >nul
docker exec -i e-commerce-mysql-1 mysql -uroot -p041212 < app\product\default.sql
if %errorlevel% neq 0 (
    echo WARNING: Product data initialization failed
) else (
    echo OK: Product data initialized
)
echo.

:: 步骤 5: 启动其他微服务
echo.
echo [5/5] Starting other services...
echo.

echo   启动 User 服务...
start "User Service" cmd /k "cd /d d:\goProjects\github\E-commerce\app\user && go run . || pause"
timeout /t 2 /nobreak >nul

echo   启动 Cart 服务...
start "Cart Service" cmd /k "cd /d d:\goProjects\github\E-commerce\app\cart && go run . || pause"
timeout /t 2 /nobreak >nul

echo   启动 Order 服务...
start "Order Service" cmd /k "cd /d d:\goProjects\github\E-commerce\app\order && go run . || pause"
timeout /t 2 /nobreak >nul

echo   启动 Payment 服务...
start "Payment Service" cmd /k "cd /d d:\goProjects\github\E-commerce\app\payment && go run . || pause"
timeout /t 2 /nobreak >nul

echo   启动 Checkout 服务...
start "Checkout Service" cmd /k "cd /d d:\goProjects\github\E-commerce\app\checkout && go run . || pause"
timeout /t 2 /nobreak >nul

echo   启动 Email 服务...
start "Email Service" cmd /k "cd /d d:\goProjects\github\E-commerce\app\email && go run . || pause"
timeout /t 2 /nobreak >nul

echo   启动 Casbin 服务...
start "Casbin Service" cmd /k "cd /d d:\goProjects\github\E-commerce\app\casbin && go run . || pause"
timeout /t 2 /nobreak >nul

echo   启动 Eino 服务...
start "Eino Service" cmd /k "cd /d d:\goProjects\github\E-commerce\app\eino && go run . || pause"
timeout /t 2 /nobreak >nul

echo.
echo ========================================
echo   所有服务启动完成！
echo ========================================
echo.
echo 等待所有服务完全启动... (约30秒)
timeout /t 30 /nobreak >nul
echo.
echo Service URLs:
echo   - Frontend: http://localhost:8080
echo   - Consul: http://localhost:8500
echo   - MySQL: localhost:3306 (root / 041212)
echo.
echo Tips: 
echo   - All services are running in separate windows
echo   - Run stop_all.bat to stop all services
echo   - Check service logs in corresponding windows
echo.
