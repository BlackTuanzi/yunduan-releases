@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ============================================
echo   Yunduan Releases - Sync Check
echo ============================================
echo.

git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
  echo [FAIL] Not a git repository: %~dp0
  goto :end
)

for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set BRANCH=%%b
for /f "delims=" %%u in ('git config --get remote.origin.url 2^>nul') do set REMOTE=%%u

if "%REMOTE%"=="" (
  echo [FAIL] No remote "origin" configured.
  goto :end
)

echo Branch : %BRANCH%
echo Remote : %REMOTE%
echo.

echo [1/4] Working tree status ...
set DIRTY=0
for /f "delims=" %%s in ('git status --porcelain 2^>nul') do set DIRTY=1

if "!DIRTY!"=="1" (
  echo   [WARN] Uncommitted changes:
  git status --short
) else (
  echo   [ OK ] Working tree clean
)
echo.

echo [2/4] Fetching remote ...
git fetch origin --quiet 2>nul
if errorlevel 1 (
  echo   [FAIL] Fetch failed - check network or credentials.
  goto :end
)
echo   [ OK ] Fetched
echo.

set LOCAL=
set REMOTEHEAD=
for /f "delims=" %%h in ('git rev-parse HEAD 2^>nul') do set LOCAL=%%h
for /f "delims=" %%h in ('git rev-parse "origin/%BRANCH%" 2^>nul') do set REMOTEHEAD=%%h

echo [3/4] Comparing local vs origin/%BRANCH% ...
if "%REMOTEHEAD%"=="" (
  echo   [WARN] Remote branch not found - push first:
  echo          git push -u origin %BRANCH%
  goto :end
)

for /f "delims=" %%a in ('git rev-list --left-right --count "origin/%BRANCH%...%BRANCH%" 2^>nul') do (
  for /f "tokens=1,2" %%x in ("%%a") do (
    set BEHIND=%%x
    set AHEAD=%%y
  )
)

if "%LOCAL%"=="%REMOTEHEAD%" (
  echo   [ OK ] Up to date with remote
) else (
  if "!AHEAD!"=="0" if "!BEHIND!"=="0" (
    echo   [ OK ] Up to date with remote
  ) else (
    if not "!AHEAD!"=="0" echo   [INFO] Local ahead by !AHEAD! commit^(s^) - run: git push
    if not "!BEHIND!"=="0" echo   [INFO] Behind by !BEHIND! commit^(s^) - run: git pull
  )
)
echo.

echo [4/4] Verifying manifest against local installers ...
if not exist "tools\update-manifest.js" (
  echo   [SKIP] tools\update-manifest.js not found
  goto :summary
)

set MISSING=0
if exist "SHA256SUMS.txt" (
  for /f "tokens=1,*" %%h in ('type "SHA256SUMS.txt"') do (
    if not "%%i"=="" (
      if not exist "%%i" (
        echo   [WARN] Listed but missing: %%i
        set MISSING=1
      )
    )
  )
) else (
  echo   [WARN] SHA256SUMS.txt not found
  set MISSING=1
)

if "!MISSING!"=="0" echo   [ OK ] All listed installers present
echo.

:summary
echo --------------------------------------------
if "!DIRTY!"=="1" echo Result: has uncommitted changes
if "!AHEAD!"=="0" if "!BEHIND!"=="0" echo Result: in sync
if not "%LOCAL%"=="%REMOTEHEAD%" if not "!AHEAD!"=="0" echo Result: needs push
if not "!BEHIND!"=="0" echo Result: needs pull
echo --------------------------------------------

:end
echo.
pause
endlocal
