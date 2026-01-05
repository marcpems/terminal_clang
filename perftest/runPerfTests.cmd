@echo off
setlocal enabledelayedexpansion

REM ====================================================================
REM Performance Test Runner
REM Runs each build configuration 7 times, discards slowest, averages the rest
REM Usage: runPerfTests.cmd [output_folder]
REM   output_folder: Optional folder path for BuildTimeSummary.txt (default: e:\terminal)
REM ====================================================================

REM Set output directory from parameter or use default
if "%~1"=="" (
    set "OUTPUT_DIR=e:\terminal"
) else (
    set "OUTPUT_DIR=%~1"
)

REM Ensure output directory exists
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo ====================================================================
echo Performance Test Suite
echo Running each configuration 7 times...
echo Output directory: %OUTPUT_DIR%
echo ====================================================================
echo.

REM Delete existing summary file if it exists
set "SUMMARY_FILE=%OUTPUT_DIR%\BuildTimeSummary.txt"
if exist "%SUMMARY_FILE%" del "%SUMMARY_FILE%"

REM Loop through all 12 configurations
for %%C in (1 2 3 4 5 6 7 8 9 10 11 12) do (
    call :RunConfigTests %%C
)

echo.
echo ====================================================================
echo Performance Test Results Summary
echo ====================================================================
for /l %%i in (0,1,11) do (
    if defined result_!%%i! (
        echo !result_%%i!
    )
)
echo ====================================================================

goto :eof

REM ====================================================================
REM Run 7 tests for a single configuration
REM Parameter: configuration number (1-12)
REM ====================================================================
:RunConfigTests
set "CONFIG=%~1"

REM Configuration names for display
if "%CONFIG%"=="1" set "CONFIG_DESC=X64 MSVC RELEASE"
if "%CONFIG%"=="2" set "CONFIG_DESC=X64 MSVC DEBUG"
if "%CONFIG%"=="3" set "CONFIG_DESC=X64 LLVM RELEASE"
if "%CONFIG%"=="4" set "CONFIG_DESC=X64 LLVM DEBUG"
if "%CONFIG%"=="5" set "CONFIG_DESC=ARM64 MSVC RELEASE"
if "%CONFIG%"=="6" set "CONFIG_DESC=ARM64 MSVC DEBUG"
if "%CONFIG%"=="7" set "CONFIG_DESC=ARM64 LLVM RELEASE"
if "%CONFIG%"=="8" set "CONFIG_DESC=ARM64 LLVM DEBUG"
if "%CONFIG%"=="9" set "CONFIG_DESC=X64 LLVM LLD RELEASE"
if "%CONFIG%"=="10" set "CONFIG_DESC=X64 LLVM LLD DEBUG"
if "%CONFIG%"=="11" set "CONFIG_DESC=ARM64 LLVM LLD RELEASE"
if "%CONFIG%"=="12" set "CONFIG_DESC=ARM64 LLVM LLD DEBUG"

echo.
echo ----------------------------------------------------------------
echo Testing: %CONFIG_DESC%
echo ----------------------------------------------------------------

REM Run 7 iterations
set /a max_time=0
set /a total_time=0
set /a run_count=0

for /l %%i in (1,1,7) do (
    echo Run %%i of 7...
    start /wait cmd /c ""%~dp0prep.cmd" %CONFIG% "%OUTPUT_DIR%""
    
    REM Find the most recent build output file for this config
    set "LAST_FILE="
    for /f "delims=" %%f in ('dir /b /o-d /tc "%~dp0build_!CONFIG_DESC: =_!_*.txt" 2^>nul') do (
        if not defined LAST_FILE set "LAST_FILE=%%f"
    )
    
    REM Extract time from the file
    for /f "tokens=2,3" %%a in ('findstr /C:"Time Elapsed" "%~dp0!LAST_FILE!"') do (
        set "TIME_STR=%%b"
        call :ConvertToSeconds "!TIME_STR!" time_seconds
        
        set /a times_%%i=!time_seconds!
        echo   Time: %%b (%%a)
        
        if !time_seconds! GTR !max_time! (
            set /a max_time=!time_seconds!
            set /a max_index=%%i
        )
    )
)

REM Calculate average excluding the slowest run
echo.
echo Discarding slowest run: !max_index! (!max_time! centiseconds)
set /a sum=0
set /a count=0

for /l %%i in (1,1,7) do (
    if not %%i==!max_index! (
        set /a sum=!sum! + !times_%%i!
        set /a count+=1
    )
)

set /a avg_time=!sum! / !count!

REM Convert back to time format for display
call :ConvertToTimeFormat !avg_time! avg_display

echo Average time (6 runs): !avg_display!

REM Store result for summary
set /a result_index=%CONFIG%-1
set "result_!result_index!=%CONFIG_DESC:~0,30%                              Average: !avg_display!"

REM Write to summary file
echo %CONFIG_DESC% - Average: !avg_display! >> "%SUMMARY_FILE%"

goto :eof

REM ====================================================================
REM Convert time string (HH:MM:SS.MS) to centiseconds
REM Parameters: time_string, output_variable_name
REM ====================================================================
:ConvertToSeconds
set "time_in=%~1"
set "out_var=%~2"

REM Parse HH:MM:SS.MS
for /f "tokens=1-4 delims=:." %%a in ("%time_in%") do (
    set /a hours=%%a
    set /a minutes=%%b
    set /a seconds=%%c
    set /a centisecs=%%d
)

REM Convert to total centiseconds (easier for integer math)
set /a total=hours*360000 + minutes*6000 + seconds*100 + centisecs
set "%out_var%=%total%"
goto :eof

REM ====================================================================
REM Convert centiseconds back to time format
REM Parameters: centiseconds, output_variable_name
REM ====================================================================
:ConvertToTimeFormat
set /a cs_in=%~1
set "out_var=%~2"

set /a hours=cs_in / 360000
set /a remainder=cs_in %% 360000
set /a minutes=remainder / 6000
set /a remainder=remainder %% 6000
set /a seconds=remainder / 100
set /a centisecs=remainder %% 100

REM Format with leading zeros
if %hours% LSS 10 set "hours=0%hours%"
if %minutes% LSS 10 set "minutes=0%minutes%"
if %seconds% LSS 10 set "seconds=0%seconds%"
if %centisecs% LSS 10 set "centisecs=0%centisecs%"

set "%out_var%=%hours%:%minutes%:%seconds%.%centisecs%"
goto :eof
