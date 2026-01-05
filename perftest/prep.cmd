REM Find and call the appropriate VsDevCmd.bat
@echo off
setlocal enabledelayedexpansion

REM ====================================================================
REM Parse command-line parameter for build configuration
REM Usage: prep.cmd [1-12] [output_folder]
REM   1 = X64 MSVC RELEASE       2 = X64 MSVC DEBUG
REM   3 = X64 LLVM RELEASE       4 = X64 LLVM DEBUG
REM   5 = ARM64 MSVC RELEASE     6 = ARM64 MSVC DEBUG
REM   7 = ARM64 LLVM RELEASE     8 = ARM64 LLVM DEBUG
REM   9 = X64 LLVM LLD RELEASE   10 = X64 LLVM LLD DEBUG
REM   11 = ARM64 LLVM LLD RELEASE 12 = ARM64 LLVM LLD DEBUG
REM   output_folder = Optional folder path for build outputs (default: script directory)
REM ====================================================================

REM Set output directory from parameter or use script directory
if "%~2"=="" (
    set "OUTPUT_DIR=%~dp0"
) else (
    set "OUTPUT_DIR=%~2"
    if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
)

set "VSDEVCMD="

REM Check for Visual Studio versions in descending order (newer first)
REM For each version, check editions: Enterprise, Professional, Community
for %%V in (19 18 17) do (
    for %%E in (Enterprise Professional Community) do (
        set "VSPATH=C:\Program Files\Microsoft Visual Studio\%%V\%%E\Common7\Tools\VsDevCmd.bat"
        if exist "!VSPATH!" (
            set "VSDEVCMD=!VSPATH!"
            goto :FoundVS
        )
    )
)

:FoundVS
if "%VSDEVCMD%"=="" (
    echo ERROR: Could not find Visual Studio installation
    timeout /t 10 /nobreak >nul
    exit /b 1
)

echo Using Visual Studio from: %VSDEVCMD%
call "%VSDEVCMD%"
endlocal

REM Check if E: drive exists
if not exist e:\ (
    echo ERROR: E: drive does not exist
    timeout /t 10 /nobreak >nul
    exit /b 1
)

REM Check if the terminal_clang folder exists
if not exist e:\terminal\terminal_clang\ (
    echo ERROR: Folder e:\terminal\terminal_clang does not exist
    timeout /t 10 /nobreak >nul
    exit /b 1
)

e:
cd e:\terminal\terminal_clang

git clean -fdx

call tools\razzle.cmd
if errorlevel 1 (
    echo ERROR: tools\razzle.cmd failed
    timeout /t 10 /nobreak >nul
    exit /b 1
)

REM ====================================================================
REM Build Configuration Selection
REM ====================================================================
set "BUILD_CHOICE=%~1"
echo %BUILD_CHOICE%

if "%BUILD_CHOICE%"=="1" (
    call :BuildConfig "x64" "release" "" "X64 MSVC RELEASE"
) else if "%BUILD_CHOICE%"=="2" (
    call :BuildConfig "x64" "debug" "" "X64 MSVC DEBUG"
) else if "%BUILD_CHOICE%"=="3" (
    call :BuildConfig "x64" "release" "/p:WindowsTerminalClangBuild=true" "X64 LLVM RELEASE"
) else if "%BUILD_CHOICE%"=="4" (
    call :BuildConfig "x64" "debug" "/p:WindowsTerminalClangBuild=true" "X64 LLVM DEBUG"
) else if "%BUILD_CHOICE%"=="5" (
    call :BuildConfig "arm64" "release" "" "ARM64 MSVC RELEASE"
) else if "%BUILD_CHOICE%"=="6" (
    call :BuildConfig "arm64" "debug" "" "ARM64 MSVC DEBUG"
) else if "%BUILD_CHOICE%"=="7" (
    call :BuildConfig "arm64" "release" "/p:WindowsTerminalClangBuild=true" "ARM64 LLVM RELEASE"
) else if "%BUILD_CHOICE%"=="8" (
    call :BuildConfig "arm64" "debug" "/p:WindowsTerminalClangBuild=true" "ARM64 LLVM DEBUG"
) else if "%BUILD_CHOICE%"=="9" (
    call :BuildConfig "x64" "release" "/p:WindowsTerminalClangLLDBuild=true" "X64 LLVM LLD RELEASE"
) else if "%BUILD_CHOICE%"=="10" (
    call :BuildConfig "x64" "debug" "/p:WindowsTerminalClangLLDBuild=true" "X64 LLVM LLD DEBUG"
) else if "%BUILD_CHOICE%"=="11" (
    call :BuildConfig "arm64" "release" "/p:WindowsTerminalClangLLDBuild=true" "ARM64 LLVM LLD RELEASE"
) else if "%BUILD_CHOICE%"=="12" (
    call :BuildConfig "arm64" "debug" "/p:WindowsTerminalClangLLDBuild=true" "ARM64 LLVM LLD DEBUG"
) else (
    echo ERROR: Invalid build choice '%BUILD_CHOICE%'
    echo Usage: prep.cmd [1-12]
    echo   1 = X64 MSVC RELEASE       2 = X64 MSVC DEBUG
    echo   3 = X64 LLVM RELEASE       4 = X64 LLVM DEBUG
    echo   5 = ARM64 MSVC RELEASE     6 = ARM64 MSVC DEBUG
    echo   7 = ARM64 LLVM RELEASE     8 = ARM64 LLVM DEBUG
    echo   9 = X64 LLVM LLD RELEASE   10 = X64 LLVM LLD DEBUG
    echo   11 = ARM64 LLVM LLD RELEASE 12 = ARM64 LLVM LLD DEBUG
    echo   (no parameter = error)
    timeout /t 10 /nobreak >nul
    exit /b 1
)

goto :eof

REM ====================================================================
REM Build function
REM Parameters: platform, configuration, additional_params, description
REM ====================================================================
:BuildConfig
echo.
echo Building: %~4

REM Create output file in output directory with timestamp and config name
set "CONFIG_NAME=%~4"
set "CONFIG_NAME=%CONFIG_NAME: =_%"
set "CONFIG_NAME=%CONFIG_NAME:/=_%"
set "TIMESTAMP=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"
set "TIMESTAMP=%TIMESTAMP:/=_%"
set "BUILD_OUTPUT=%OUTPUT_DIR%\build_%CONFIG_NAME%_%TIMESTAMP%.txt"

msbuild openconsole.slnx /p:platform=%~1;configuration=%~2 %~3 /t:Conhost\Host_EXE /m > "%BUILD_OUTPUT%" 2>&1
set "BUILD_ERROR=%ERRORLEVEL%"

REM Display the output
type "%BUILD_OUTPUT%"

if %BUILD_ERROR% NEQ 0 (
    echo ERROR: Build failed for %~4
    echo Output saved to: %BUILD_OUTPUT%
    timeout /t 10 /nobreak >nul
    exit /b 1
)

REM Extract and display the elapsed time
for /f "tokens=2,3*" %%a in ('findstr /C:"Time Elapsed" "%BUILD_OUTPUT%"') do (
    echo Success: %~4 - Time Elapsed %%b %%c
    set "LAST_BUILD_TIME=%%b %%c"
)

echo Output saved to: %BUILD_OUTPUT%

REM Copy the built binary to binaries folder in output directory
set "SOURCE_BIN=bin\%~1\%~2\openconsole.exe"
set "BINARIES_DIR=%OUTPUT_DIR%\binaries"
if not exist "%BINARIES_DIR%" mkdir "%BINARIES_DIR%"

REM Determine compiler type from description
set "COMPILER_TYPE=MSVC"
echo %~4 | findstr /C:"LLVM LLD" >nul && set "COMPILER_TYPE=Clang-LLD"
if "%COMPILER_TYPE%"=="MSVC" (
    echo %~4 | findstr /C:"LLVM" >nul && set "COMPILER_TYPE=Clang"
)

REM Construct target filename with platform, config, and compiler
set "TARGET_BIN=%BINARIES_DIR%\openconsole_%~1_%~2_%COMPILER_TYPE%.exe"

if exist "%SOURCE_BIN%" (
    copy /Y "%SOURCE_BIN%" "%TARGET_BIN%" >nul
    echo Binary copied to: %TARGET_BIN%
) else (
    echo WARNING: Binary not found at %SOURCE_BIN%
)

REM Pause for 2 seconds before exiting

echo LAST_BUILD_TIME=%LAST_BUILD_TIME%


timeout /t 2 /nobreak >nul

goto :eof


REM msbuild openconsole.slnx /p:platform=x64;configuration=release /t:_Tools\ConsoleBench /m 