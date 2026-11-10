@echo off
chcp 65001 >nul
cd /d "%~dp0"
start "" pythonw vpn_client\main.py
