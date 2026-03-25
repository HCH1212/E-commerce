@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo   E-commerce 椤圭洰涓€閿惎鍔ㄨ剼鏈?
echo ========================================
echo.

:: 姝ラ 1: 鍚姩 Docker 鍩虹鏈嶅姟
echo [1/5] 鍚姩 Docker 鍩虹鏈嶅姟 (MySQL, Redis, Consul, NATS)...
call start.bat
if %errorlevel% neq 0 (
    echo 閿欒: 鍩虹鏈嶅姟鍚姩澶辫触
    pause
    exit /b 1
)
echo.

:: 姝ラ 2: 鍚姩 Frontend 鏈嶅姟
echo [2/5] 鍚姩 Frontend 鏈嶅姟...
start "Frontend Service" cmd /k "cd /d %~dp0app\frontend && go run . || pause"
timeout /t 3 /nobreak >nul
echo 鉁?Frontend 鏈嶅姟宸插惎鍔?
echo.

:: 姝ラ 3: 鍚姩 Product 鏈嶅姟
echo [3/5] 鍚姩 Product 鏈嶅姟...
start "Product Service" cmd /k "cd /d %~dp0app\product && go run . || pause"
timeout /t 3 /nobreak >nul
echo 鉁?Product 鏈嶅姟宸插惎鍔?
echo.

:: 姝ラ 4: 鍒濆鍖栧晢鍝佹暟鎹?
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

:: 姝ラ 5: 鍚姩鍏朵粬寰湇鍔?
echo.
echo [5/5] Starting other services...
echo.

echo   鍚姩 User 鏈嶅姟...
start "User Service" cmd /k "cd /d %~dp0app\user && go run . || pause"
timeout /t 2 /nobreak >nul

echo   鍚姩 Cart 鏈嶅姟...
start "Cart Service" cmd /k "cd /d %~dp0app\cart && go run . || pause"
timeout /t 2 /nobreak >nul

echo   鍚姩 Order 鏈嶅姟...
start "Order Service" cmd /k "cd /d %~dp0app\order && go run . || pause"
timeout /t 2 /nobreak >nul

echo   鍚姩 Payment 鏈嶅姟...
start "Payment Service" cmd /k "cd /d %~dp0app\payment && go run . || pause"
timeout /t 2 /nobreak >nul

echo   鍚姩 Checkout 鏈嶅姟...
start "Checkout Service" cmd /k "cd /d %~dp0app\checkout && go run . || pause"
timeout /t 2 /nobreak >nul

echo   鍚姩 Email 鏈嶅姟...
start "Email Service" cmd /k "cd /d %~dp0app\email && go run . || pause"
timeout /t 2 /nobreak >nul

echo   鍚姩 Casbin 鏈嶅姟...
start "Casbin Service" cmd /k "cd /d %~dp0app\casbin && go run . || pause"
timeout /t 2 /nobreak >nul

echo   鍚姩 Eino 鏈嶅姟...
start "Eino Service" cmd /k "cd /d %~dp0app\eino && go run . || pause"
timeout /t 2 /nobreak >nul

echo.
echo ========================================
echo   鎵€鏈夋湇鍔″惎鍔ㄥ畬鎴愶紒
echo ========================================
echo.
echo 绛夊緟鎵€鏈夋湇鍔″畬鍏ㄥ惎鍔?.. (绾?0绉?
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


