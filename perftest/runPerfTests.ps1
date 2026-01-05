<#
====================================================================
Performance Test Runner
Runs each build configuration N times, discards slowest, averages the rest
Usage: runPerfTests.ps1 [iterations] [output_folder]
  iterations: Optional number of iterations per configuration (default: 7)
  output_folder: Optional folder path for BuildTimeSummary.txt (default: e:\terminal)
====================================================================
#>

param(
    [int]$Iterations = 7,
    [string]$OutputDir = "e:\terminal"
)

# Get script directory
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ScriptDir) { $ScriptDir = Get-Location }

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Performance Test Suite" -ForegroundColor Cyan
Write-Host "Running each configuration $Iterations times..." -ForegroundColor Cyan
Write-Host "Output directory: $OutputDir" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Delete existing summary file if it exists
$summaryFile = Join-Path $OutputDir "BuildTimeSummary.txt"
if (Test-Path $summaryFile) {
    Remove-Item $summaryFile
}

# Configuration mapping
$configs = @{
    1  = "X64 MSVC RELEASE"
    2  = "X64 MSVC DEBUG"
    3  = "X64 LLVM RELEASE"
    4  = "X64 LLVM DEBUG"
    5  = "ARM64 MSVC RELEASE"
    6  = "ARM64 MSVC DEBUG"
    7  = "ARM64 LLVM RELEASE"
    8  = "ARM64 LLVM DEBUG"
    9  = "X64 LLVM LLD RELEASE"
    10 = "X64 LLVM LLD DEBUG"
    11 = "ARM64 LLVM LLD RELEASE"
    12 = "ARM64 LLVM LLD DEBUG"
}

# Store results
$results = @{}

# Function to convert time string (HH:MM:SS.MS) to centiseconds
function ConvertTo-Centiseconds {
    param([string]$timeStr)
    
    if ($timeStr -match '(\d+):(\d+):(\d+)\.(\d+)') {
        $hours = [int]$matches[1]
        $minutes = [int]$matches[2]
        $seconds = [int]$matches[3]
        $centisecs = [int]$matches[4]
        
        return $hours * 360000 + $minutes * 6000 + $seconds * 100 + $centisecs
    }
    return 0
}

# Function to convert centiseconds back to time format
function ConvertFrom-Centiseconds {
    param([int]$cs)
    
    $hours = [Math]::Floor($cs / 360000)
    $remainder = $cs % 360000
    $minutes = [Math]::Floor($remainder / 6000)
    $remainder = $remainder % 6000
    $seconds = [Math]::Floor($remainder / 100)
    $centisecs = $remainder % 100
    
    return "{0:D2}:{1:D2}:{2:D2}.{3:D2}" -f $hours, $minutes, $seconds, $centisecs
}

# Function to run tests for a single configuration
function Run-ConfigTests {
    param([int]$configNum)
    
    $configDesc = $configs[$configNum]
    
    Write-Host ""
    Write-Host "----------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "Testing: $configDesc" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------" -ForegroundColor Yellow
    
    $times = @{}
    $maxTime = 0
    $maxIndex = 0
    
    # Run iterations
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Host "Run $i of ${Iterations}..."
        
        # Call prep.cmd
        $prepScript = Join-Path $script:ScriptDir "prep.cmd"
        
        Write-Host "DEBUG: Calling: $prepScript $configNum `"$OutputDir`"" -ForegroundColor Magenta
        Write-Host "DEBUG: Calling: "`"$prepScript`"" $configNum "`"$OutputDir`""" -ForegroundColor Magenta

        Start-process -FilePath "cmd.exe" -ArgumentList "/c", "$prepScript $configNum $OutputDir" -Wait

        #        & cmd.exe /c "`"$prepScript`"" $configNum "`"$OutputDir`""

        # Find the most recent build output file for this config
        $configPattern = $configDesc -replace ' ', '_'
        $buildFiles = Get-ChildItem -Path $OutputDir -Filter "build_${configPattern}_*.txt" -ErrorAction SilentlyContinue |
            Sort-Object CreationTime -Descending |
            Select-Object -First 1
        
        if ($buildFiles) {
            # Extract time from the file
            $content = Get-Content $buildFiles.FullName | Select-String "Time Elapsed"
            if ($content) {
                $match = $content -match 'Time Elapsed\s+(\S+)\s+(\S+)'
                if ($match) {
                    $timeStr = $matches[2]
                    $timeSeconds = ConvertTo-Centiseconds $timeStr
                    
                    $times[$i] = $timeSeconds
                    Write-Host "  Time: $timeStr ($($matches[1]))" -ForegroundColor Green
                    
                    if ($timeSeconds -gt $maxTime) {
                        $maxTime = $timeSeconds
                        $maxIndex = $i
                    }
                }
            }
        }
    }
    
    # Calculate average excluding the slowest run (unless only 1 iteration)
    Write-Host ""
    
    if ($Iterations -eq 1) {
        $avgTime = $times[1]
        $avgDisplay = ConvertFrom-Centiseconds $avgTime
        Write-Host "Average time (1 run): $avgDisplay" -ForegroundColor Cyan
    }
    else {
        Write-Host "Discarding slowest run: $maxIndex ($maxTime centiseconds)" -ForegroundColor Gray
        
        $sum = 0
        $count = 0
        
        for ($i = 1; $i -le $Iterations; $i++) {
            if ($i -ne $maxIndex) {
                Write-Host "DEBUG: Adding times[$i] = $($times[$i])" -ForegroundColor DarkGray
                $sum += $times[$i]
                $count++
            }
        }
        
        Write-Host "DEBUG: sum=$sum, count=$count" -ForegroundColor DarkGray
        
        if ($count -gt 0) {
            $avgTime = [Math]::Floor($sum / $count)
            $avgDisplay = ConvertFrom-Centiseconds $avgTime
            Write-Host "Average time ($count runs): $avgDisplay" -ForegroundColor Cyan
        }
        else {
            $avgDisplay = "N/A"
            Write-Host "Average time: $avgDisplay" -ForegroundColor Red
        }
    }
    
    # Store result
    $results[$configNum] = "$configDesc - Average: $avgDisplay"
    
    # Write to summary file
    Add-Content -Path $summaryFile -Value "$configDesc - Average: $avgDisplay"
}

# Loop through all 12 configurations (or subset for testing)
# 1..12 | ForEach-Object { Run-ConfigTests $_ }
9..12 | ForEach-Object { Run-ConfigTests $_ }

# Display results summary
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Performance Test Results Summary" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
$results.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Host $_.Value
}
Write-Host "====================================================================" -ForegroundColor Cyan
