param(
    [string]$Godot = $env:GODOT_EXE,
    [switch]$All,
    [int]$TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $Godot) {
    $candidates = @(
        (Join-Path (Split-Path -Parent $projectRoot) 'tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'),
        'C:\Tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
    )
    $Godot = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $Godot -or -not (Test-Path -LiteralPath $Godot)) {
    throw 'Specify -Godot <console executable> or set GODOT_EXE.'
}
$logRoot = Join-Path $projectRoot ('builds\local-validation\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$savedAppData = $env:APPDATA
$savedTemp = $env:TEMP
$savedTmp = $env:TMP
$results = @()
try {
    $env:APPDATA = Join-Path $logRoot 'appdata'
    $env:TEMP = Join-Path $logRoot 'temp'
    $env:TMP = $env:TEMP
    New-Item -ItemType Directory -Path $env:APPDATA,$env:TEMP -Force | Out-Null
    $engineVersion = & $Godot --version
    Write-Output "Godot: $engineVersion"
    foreach ($test in (Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'test_*.gd' | Sort-Object Name)) {
        if ($test.BaseName -eq 'test_real_time_stability' -and -not $All) {
            Write-Output "SKIP $($test.Name) (30 minute real-time test; use -All)"
            continue
        }
        $logPath = Join-Path $logRoot ($test.BaseName + '.log')
        $outPath = Join-Path $logRoot ($test.BaseName + '.stdout')
        $errPath = Join-Path $logRoot ($test.BaseName + '.stderr')
        $limit = $TimeoutSeconds
        if ($test.BaseName -eq 'test_real_time_stability') { $limit = 2100 }
        $arguments = '--headless --path "{0}" --log-file "{1}" --quit-after 200000 --script "res://tests/{2}"' -f $projectRoot,$logPath,$test.Name
        $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $outPath -RedirectStandardError $errPath
        $timedOut = -not $process.WaitForExit($limit * 1000)
        if ($timedOut) {
            # Only stop the exact child launched for this test.
            $process.Kill()
            $process.WaitForExit()
        }
        $process.Refresh()
        $output = (@($logPath,$outPath,$errPath) | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object { Get-Content -LiteralPath $_ -Raw }) -join "`n"
        $passed = -not $timedOut -and $process.ExitCode -eq 0 -and $output -match 'PASS' -and $output -notmatch 'SCRIPT ERROR|Parse Error|Assertion failed|(?m)^ERROR:|CRASH'
        $status = if ($passed) { 'PASS' } else { 'FAIL' }
        Write-Output "$status $($test.Name) exit=$($process.ExitCode) timeout=$timedOut"
        $results += [pscustomobject]@{ Test=$test.Name; Passed=$passed; ExitCode=$process.ExitCode; TimedOut=$timedOut; Log=$logPath }
    }
    $results | ConvertTo-Json -Depth 3 | Out-File -LiteralPath (Join-Path $logRoot 'results.json') -Encoding utf8
    $failures = @($results | Where-Object { -not $_.Passed })
    Write-Output "SUMMARY passed=$(@($results | Where-Object Passed).Count) failed=$($failures.Count) logs=$logRoot"
    if ($failures.Count -gt 0) { exit 1 }
} finally {
    $env:APPDATA = $savedAppData
    $env:TEMP = $savedTemp
    $env:TMP = $savedTmp
}
