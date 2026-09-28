@echo off
chcp 65001 >nul 2>nul
setlocal EnableExtensions
title 大物实验预习 - 查看状态

echo ==================================================
echo    大物实验预习答题 - 查看状态（只读，不会提交）
echo ==================================================
echo.

set "GITBASH="
if exist "C:\Program Files\Git\bin\bash.exe"            set "GITBASH=C:\Program Files\Git\bin\bash.exe"
if not defined GITBASH if exist "C:\Program Files (x86)\Git\bin\bash.exe" set "GITBASH=C:\Program Files (x86)\Git\bin\bash.exe"
if not defined GITBASH if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" set "GITBASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not defined GITBASH goto NOGIT

where node >nul 2>nul
if errorlevel 1 goto NONODE

if not exist "%~dp0config.sh" goto NOCONF

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

"%GITBASH%" -lc "cd \"$(cygpath -u '%HERE%')\" && bash scripts/status.sh"
echo.
echo 按任意键关闭本窗口...
pause >nul
exit /b 0

:NOCONF
echo [x] 还没有配置文件 config.sh。
echo     请先双击「一键运行.bat」完成首次配置。
echo.
pause
exit /b 1

:NOGIT
echo [x] 没有找到 Git Bash。请先安装 Git for Windows：
echo         https://git-scm.com/download/win
echo.
pause
exit /b 1

:NONODE
echo [x] 没有找到 Node.js。请先安装（LTS 版）：
echo         https://nodejs.org
echo.
pause
exit /b 1
