@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Pink Service VPN Client
echo ======================================================
echo    Запуск графического интерфейса Pink Service VPN...
echo ======================================================
echo.

python vpn_client\main.py

if errorlevel 1 (
    echo.
    echo [ВНИМАНИЕ] Произошла ошибка при работе приложения.
    echo Проверьте лог выше или файл vpn_client\crash.log.
    echo.
    pause
)
