param (
    [Parameter(Position=0, HelpMessage="Path to the XSLT file to test (e.g., ..\v4.xslt)")]
    [string]$XsltPath = "..\edifactparser.xslt"
)

$ErrorActionPreference = "Stop"

# Validate XSLT input
if (-not (Test-Path $XsltPath)) {
    Write-Error "XSLT file not found: $XsltPath"
    exit 1
}

# ---------------------------------------------------------------------------
# 1. Dynamic Configuration
# ---------------------------------------------------------------------------
$saxonVersion = "12.4"
$zipName      = "SaxonHE12-4J.zip"
$downloadUrl  = "https://downloads.saxonica.com/SaxonJ/HE/12/$zipName"
$toolsDir     = "saxon-tools"
$jarPath      = "$toolsDir\saxon-he-$saxonVersion.jar"

$xsltBaseName = [System.IO.Path]::GetFileNameWithoutExtension($XsltPath)
$outputDir    = "$xsltBaseName-results"
$traceLog     = "$outputDir\trace-output.txt"

New-Item -ItemType Directory -Force -Path $outputDir, "reference", $toolsDir | Out-Null

# ---------------------------------------------------------------------------
# 2. Dependency Management
# ---------------------------------------------------------------------------
if (-not (Test-Path $jarPath)) {
    Write-Host "Saxon dependencies missing. Fetching release zip from Saxonica..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipName
    
    Write-Host "Extracting archive to .\$toolsDir\..." -ForegroundColor Cyan
    Expand-Archive -Path $zipName -DestinationPath $toolsDir -Force
    Remove-Item $zipName -Force
}

# ---------------------------------------------------------------------------
# 3. Test Inputs
# ---------------------------------------------------------------------------
$testInputs = @(
    "standard.xml"
    "escape.xml"
    "error.xml"
    "long.xml"
    "stress_test.xml"
)

# ---------------------------------------------------------------------------
# 4. Helper Functions
# ---------------------------------------------------------------------------
function Invoke-SaxonTransform {
    param ([string]$Jar, [string]$Source, [string]$Stylesheet, [string]$OutputFile, [string]$LogFile)
    
    # Create temporary files to catch output so we don't block the PowerShell thread
    $outTemp = [System.IO.Path]::GetTempFileName()
    $errTemp = [System.IO.Path]::GetTempFileName()
    
    $argList = "-jar `"$Jar`" -t -s:`"$Source`" -xsl:`"$Stylesheet`" -o:`"$OutputFile`""
    
    # Launch Java using Start-Process so we can monitor it in real-time
    $proc = Start-Process -FilePath "java" -ArgumentList $argList -RedirectStandardOutput $outTemp -RedirectStandardError $errTemp -WindowStyle Hidden -PassThru
    
    $peakMem = 0
    
    # Poll the memory every 25 milliseconds while the process is alive
    while (-not $proc.HasExited) {
        try {
            $proc.Refresh()
            if ($proc.PeakWorkingSet64 -gt $peakMem) {
                $peakMem = $proc.PeakWorkingSet64
            }
        } catch {
            # Catch block prevents red text if the process terminates exactly during the read
        }
        Start-Sleep -Milliseconds 25
    }
    
    # Give the OS a tiny fraction of a second to release the file locks
    Start-Sleep -Milliseconds 50
    
    # Retrieve the text from our temp files and clean them up
    $stdout = Get-Content $outTemp -Raw -ErrorAction SilentlyContinue
    $stderr = Get-Content $errTemp -Raw -ErrorAction SilentlyContinue
    Remove-Item $outTemp -Force -ErrorAction SilentlyContinue
    Remove-Item $errTemp -Force -ErrorAction SilentlyContinue
    
    # Calculate megabytes (If it ran too fast to poll, default to 0)
    $peakMemMB = [math]::Round($peakMem / 1MB, 2)
    
    # Combine outputs and split into readable lines
    $rawOutput = "$stdout`n$stderr"
    $outputLines = $rawOutput -split "`r?`n"
    
    # Append everything to the master trace log
    $outputLines | Add-Content -Path $LogFile
    "System Peak Working Set: $peakMemMB MB" | Add-Content -Path $LogFile
    "" | Add-Content -Path $LogFile
    
    # Extract only the Execution time line from Saxon's trace
    $timeStat = $outputLines | Where-Object { $_ -match "Execution time" }
    
    if ($timeStat) {
        Write-Host "    > $($timeStat.Trim())" -ForegroundColor DarkGray
    }
    Write-Host "    > OS Peak Memory: $peakMemMB MB" -ForegroundColor DarkGray
}

function Test-FileHashMatch {
    param ([string]$ReferenceFile, [string]$GeneratedFile)
    
    if (-not (Test-Path $ReferenceFile)) {
        Write-Host "    [SKIP] Reference file not found: $ReferenceFile" -ForegroundColor Yellow
        return $null
    }
    if (-not (Test-Path $GeneratedFile)) {
        Write-Host "    [FAIL] Generated file missing: $GeneratedFile" -ForegroundColor Red
        return $false
    }

    $hashRef = (Get-FileHash -Path $ReferenceFile -Algorithm SHA256).Hash
    $hashGen = (Get-FileHash -Path $GeneratedFile -Algorithm SHA256).Hash

    if ($hashRef -eq $hashGen) {
        Write-Host "    [PASS] Hashes match" -ForegroundColor Green
        return $true
    } else {
        Write-Host "    [FAIL] Hash mismatch!" -ForegroundColor Red
        Write-Host "           Ref: $hashRef" -ForegroundColor Red
        Write-Host "           Gen: $hashGen" -ForegroundColor Red
        return $false
    }
}

# ---------------------------------------------------------------------------
# 5. Run Test Suite
# ---------------------------------------------------------------------------
if (Test-Path $traceLog) { Clear-Content $traceLog }
$results = @{ Passed = 0; Failed = 0; Skipped = 0 }

Write-Host "`nStarting Test Suite" -ForegroundColor Cyan
Write-Host "XSLT target: $XsltPath" -ForegroundColor DarkGray
Write-Host "Output Dir : $outputDir`n" -ForegroundColor DarkGray

foreach ($inputFileName in $testInputs) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFileName)
    $outPath  = "$outputDir\$baseName.xml"
    $refPath  = "reference\$baseName.xml"

    Write-Host "Testing '$inputFileName'..." -ForegroundColor White
    
    Invoke-SaxonTransform -Jar $jarPath -Source "test-files\$inputFileName" -Stylesheet $XsltPath -OutputFile $outPath -LogFile $traceLog
    
    $status = Test-FileHashMatch -ReferenceFile $refPath -GeneratedFile $outPath
    
    if ($status -eq $true) { $results.Passed++ }
    elseif ($status -eq $false) { $results.Failed++ }
    else { $results.Skipped++ }
}

# ---------------------------------------------------------------------------
# 6. Summary
# ---------------------------------------------------------------------------
Write-Host "`n================ TEST SUMMARY ================" -ForegroundColor Cyan
Write-Host "Passed:  $($results.Passed)" -ForegroundColor Green
Write-Host "Failed:  $($results.Failed)" -ForegroundColor $(if ($results.Failed -gt 0) { "Red" } else { "Gray" })
Write-Host "Skipped: $($results.Skipped)" -ForegroundColor $(if ($results.Skipped -gt 0) { "Yellow" } else { "Gray" })
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Full trace log saved to: $traceLog`n" -ForegroundColor DarkGray