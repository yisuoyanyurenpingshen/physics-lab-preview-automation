@echo off
chcp 65001 >nul 2>nul
setlocal EnableExtensions
title 大物实验预习 - 一键运行

echo ==================================================
echo    大物实验预习答题 - 一键运行
echo ==================================================
echo.

rem ---------- 1. 找 Git Bash ----------
set "GITBASH="
if exist "C:\Program Files\Git\bin\bash.exe"            set "GITBASH=C:\Program Files\Git\bin\bash.exe"
if not defined GITBASH if exist "C:\Program Files (x86)\Git\bin\bash.exe" set "GITBASH=C:\Program Files (x86)\Git\bin\bash.exe"
if not defined GITBASH if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" set "GITBASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not defined GITBASH goto NOGIT

rem ---------- 2. 找 Node.js ----------
where node >nul 2>nul
if errorlevel 1 goto NONODE

rem ---------- 3. 找 agent-browser（缺了自动装） ----------
where agent-browser >nul 2>nul
if not errorlevel 1 goto ABOK
echo [首次运行] 没找到 agent-browser，正在自动安装（走国内镜像，约 20 秒）...
echo.
call npm install -g agent-browser --registry=https://registry.npmmirror.com
echo.
where agent-browser >nul 2>nul
if not errorlevel 1 goto ABOK
echo [x] agent-browser 自动安装失败。
echo     请在命令行里手动执行这一句，然后再双击本文件：
echo         npm install -g agent-browser --registry=https://registry.npmmirror.com
echo.
pause
exit /b 1
:ABOK

rem ---------- 4. 首次运行：生成并打开 config.sh ----------
if not exist "%~dp0config.sh" (
  echo [首次运行] 正在生成配置文件 config.sh ...
  copy "%~dp0config.example.sh" "%~dp0config.sh" >nul
  echo.
  echo   接下来会打开记事本，请填写下面两行，然后保存并关闭记事本：
  echo.
  echo       export SITE_USER="你的账号"
  echo       export SITE_PASSWORD="你的密码"
  echo.
  echo   保存关闭后，脚本会自动继续。
  echo.
  pause
  start /wait notepad "%~dp0config.sh"
  echo.
)

rem ---------- 5. 执行 ----------
set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

echo --------------------------------------------------
"%GITBASH%" -lc "cd \"$(cygpath -u '%HERE%')\" && bash scripts/run_all.sh"
set "RC=%ERRORLEVEL%"
echo --------------------------------------------------
echo.

if not "%RC%"=="0" (
  echo [x] 执行过程中出现错误（退出码 %RC%）。
  echo     请把上面的信息截图反馈，或查看「教师使用说明.md」第 6 节。
) else (
  echo [√] 全部处理完毕。
)

echo.
echo 按任意键关闭本窗口...
pause >nul
exit /b %RC%

:NOGIT
echo [x] 没有找到 Git Bash（bash.exe）。
echo.
echo     请先安装 Git for Windows：
echo         https://git-scm.com/download/win
echo     安装时一路默认即可，装完后重新双击本文件。
echo.
pause
exit /b 1

:NONODE
echo [x] 没有找到 Node.js。
echo.
echo     请先安装 Node.js（选 LTS 版，18 以上）：
echo         https://nodejs.org
echo     装完后重新双击本文件。
echo.
pause
exit /b 1
