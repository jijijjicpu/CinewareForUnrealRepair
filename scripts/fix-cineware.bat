@echo off
chcp 65001 >nul
title Cineware for Unreal Fix Tool
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix-cineware.ps1"
