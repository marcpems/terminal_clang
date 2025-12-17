@echo off
setlocal

REM set some defaults if no params are provided
if "%1"=="" (
    echo Using defaults compiler=llvm silicon=arm64 configuration=release number_of_iterations=3
    set COMPILER=llvm
    set SILICON=arm64
    set CONFIG=release
    set ITERATIONS=3
) else if /I not "%1"=="llvm" if /I not "%1"=="msvc" if "%4"=="" if /I not "%2"=="arm64" if /I not "%2"=="x64" (
    echo Usage: runTest.cmd [compiler] [silicon] [configuration] [number_of_iterations]
    echo   compiler: msvc or llvm
    echo   silicon: arm64 or x64
    echo   configuration: debug or release
    echo Example: runTest.cmd msvc debug 5
    exit /b 1
) else (
set COMPILER=%1
set SILICON=%2
set CONFIG=%3
set ITERATIONS=%4
echo Using parameters compiler=%COMPILER% silicon=%SILICON% configuration=%CONFIG% number_of_iterations=%ITERATIONS%
)

cd ..

for /L %%i in (1,1,%ITERATIONS%) do (
    echo.
    echo ========================================
    echo Iteration %%i of %ITERATIONS%
    echo ========================================
    echo.
    
    echo Cleaning repo ...
    git clean -fdx
    
    echo Starting build in new terminal...
    if "%COMPILER%"=="msvc" (
    start /wait "Build Iteration %%i" cmd /k "call tools\razzle.cmd && msbuild openconsole.slnx /p:platform=%SILICON%;configuration=%CONFIG% /t:Conhost\Host_EXE /m && echo. && echo Build complete! Press any key to close this window and continue... && pause > nul && exit"
    ) else (
    start /wait "Build Iteration %%i" cmd /k "call tools\razzle.cmd && msbuild openconsole.slnx /p:platform=%SILICON%;configuration=%CONFIG% /p:WindowsTerminalClangBuild=true /t:Conhost\Host_EXE /m && echo. && echo Build complete! Press any key to close this window and continue... && pause > nul && exit"
    )
)
