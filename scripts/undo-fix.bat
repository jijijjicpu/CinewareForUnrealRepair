@echo off
chcp 65001 >nul
title Cineware for Unreal - Undo Fix
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix-cineware.ps1" -Undo
