REM Find and call the appropriate VsDevCmd.bat
@echo off
setlocal enabledelayedexpansion

REM ====================================================================
REM Parse command-line parameter for build configuration
REM Usage: prep.cmd [1-8]
REM   1 = X64 MSVC RELEASE      2 = X64 MSVC DEBUG
REM   3 = X64 LLVM RELEASE      4 = X64 LLVM DEBUG
REM   5 = ARM64 MSVC RELEASE    6 = ARM64 MSVC DEBUG
REM   7 = ARM64 LLVM RELEASE    8 = ARM64 LLVM DEBUG
REM   (no parameter = error)
REM ====================================================================
set "BUILD_CHOICE=%~1"

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
    exit /b 1
)

echo Using Visual Studio from: %VSDEVCMD%
call "%VSDEVCMD%"
endlocal

REM Check if E: drive exists
if not exist e:\ (
    echo ERROR: E: drive does not exist
    exit /b 1
)

REM Check if the terminal_clang folder exists
if not exist e:\terminal\terminal_clang\ (
    echo ERROR: Folder e:\terminal\terminal_clang does not exist
    exit /b 1
)

e:
cd e:\terminal\terminal_clang

git clean -fdx
if errorlevel 1 (
    echo ERROR: git clean failed
    exit /b 1
)

call tools\razzle.cmd
if errorlevel 1 (
    echo ERROR: tools\razzle.cmd failed
    exit /b 1
)

REM ====================================================================
REM Build Configuration Selection
REM ====================================================================

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
) else (
    echo ERROR: Invalid build choice '%BUILD_CHOICE%'
    echo Usage: prep.cmd [1-8]
    echo   1 = X64 MSVC RELEASE      2 = X64 MSVC DEBUG
    echo   3 = X64 LLVM RELEASE      4 = X64 LLVM DEBUG
    echo   5 = ARM64 MSVC RELEASE    6 = ARM64 MSVC DEBUG
    echo   7 = ARM64 LLVM RELEASE    8 = ARM64 LLVM DEBUG
    echo   (no parameter = error)
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

REM Create output file in script directory with timestamp and config name
set "CONFIG_NAME=%~4"
set "CONFIG_NAME=%CONFIG_NAME: =_%"
set "TIMESTAMP=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"
set "BUILD_OUTPUT=%~dp0build_%CONFIG_NAME%_%TIMESTAMP%.txt"

msbuild openconsole.slnx /p:platform=%~1;configuration=%~2 %~3 /t:Conhost\Host_EXE /m > "%BUILD_OUTPUT%" 2>&1
set "BUILD_ERROR=%ERRORLEVEL%"

REM Display the output
type "%BUILD_OUTPUT%"

if %BUILD_ERROR% NEQ 0 (
    echo ERROR: Build failed for %~4
    echo Output saved to: %BUILD_OUTPUT%
    exit /b 1
)

REM Extract and display the elapsed time
for /f "tokens=2,3*" %%a in ('findstr /C:"Time Elapsed" "%BUILD_OUTPUT%"') do (
    echo Success: %~4 - Time Elapsed %%b %%c
    set "LAST_BUILD_TIME=%%b %%c"
)

echo Output saved to: %BUILD_OUTPUT%
goto :eof


REM msbuild openconsole.slnx /p:platform=x64;configuration=release /t:_Tools\ConsoleBench /m 