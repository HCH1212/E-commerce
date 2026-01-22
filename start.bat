@echo off
chcp 65001 >nul
echo ========================================
echo   E-commerce 项目一键启动脚本
echo ========================================
echo.

echo [1/3] 启动 Docker 基础服务 (MySQL, Redis, Consul, NATS)...
docker compose up -d
if %errorlevel% neq 0 (
    echo 错误: Docker 服务启动失败
    pause
    exit /b 1
)
echo ✓ Docker 服务启动成功
echo.

echo [2/3] 等待 MySQL 服务就绪...
timeout /t 10 /nobreak >nul
echo ✓ MySQL 服务已就绪
echo.

echo [3/3] 初始化数据库...
docker exec -i e-commerce-mysql-1 mysql -uroot -p041212 < init_databases.sql
if %errorlevel% neq 0 (
    echo 错误: 数据库初始化失败
    pause
    exit /b 1
)
echo ✓ 数据库初始化完成
echo.

echo ========================================
echo   基础环境准备完成！
echo ========================================
echo.
echo 接下来请按顺序在不同的终端窗口运行以下命令启动各个微服务:
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
echo 所有服务启动完成后，访问: http://localhost:8080
echo.
echo 有用的管理界面:
echo   - Consul: http://localhost:8500
echo   - MySQL: localhost:3306 (用户名: root, 密码: 041212)
echo.
