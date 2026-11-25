@echo off
chcp 65001 >nul
title Lightroom RAW Toolkit
if "%~1"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Start-Toolkit.ps1"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Start-Toolkit.ps1" -RootPath "%~1"
)
if errorlevel 1 pause
