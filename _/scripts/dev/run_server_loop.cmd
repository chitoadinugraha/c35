@echo off
set "ROOT=%~dp0..\..\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_server_loop.ps1" -Root "%ROOT%" -Port %DEV_SERVER_PORT%
