@echo off
chcp 65001 >nul
cd /d "%~dp0"
python vpn_client\main.py --cli
pause
