param(
  [string]$Device = "",
  [switch]$Open
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$TestResultsDir = Join-Path $ProjectRoot "build\test-results"
$MachineOutput = Join-Path $TestResultsDir "flutter-test.jsonl"
$AllureResultsDir = Join-Path $ProjectRoot "build\allure-results"
$AllureReportDir = Join-Path $ProjectRoot "build\allure-report"
$DeviceName = if ($Device -ne "") { $Device } else { "chrome" }
$ChromedriverProcess = $null

New-Item -ItemType Directory -Force -Path $TestResultsDir | Out-Null

Write-Host "==> Running Flutter integration tests"
Push-Location $ProjectRoot
try {
  if ($DeviceName -eq "chrome") {
    $chromedriverPath = Join-Path $ProjectRoot "chromedriver.exe"
    if (-not (Test-Path $chromedriverPath)) {
      throw "Chrome device requested but chromedriver.exe was not found at $chromedriverPath"
    }

    $portInUse = Get-NetTCPConnection -LocalPort 4444 -ErrorAction SilentlyContinue
    if ($null -eq $portInUse) {
      $ChromedriverProcess = Start-Process -FilePath $chromedriverPath -ArgumentList "--port=4444" -PassThru -WindowStyle Hidden
    }
  }

  $flutterArgs = @(
    "drive",
    "--driver=test_driver\integration_test.dart",
    "--target=integration_test\app_test.dart",
    "-d", $DeviceName,
    "--dart-define=E2E_SLOW_MS=1200"
  )

  # Run flutter and redirect stdout/stderr to separate temp files, then merge them
  if (Test-Path $MachineOutput) { Remove-Item $MachineOutput -Force }
  $outFile = Join-Path $TestResultsDir "flutter-out.log"
  $errFile = Join-Path $TestResultsDir "flutter-err.log"
  if (Test-Path $outFile) { Remove-Item $outFile -Force }
  if (Test-Path $errFile) { Remove-Item $errFile -Force }

  $startInfo = Start-Process -FilePath "flutter" -ArgumentList $flutterArgs -NoNewWindow -RedirectStandardOutput $outFile -RedirectStandardError $errFile -Wait -PassThru
  $flutterExitCode = $startInfo.ExitCode

  $outText = ''
  $errText = ''
  if (Test-Path $outFile) { $outText = Get-Content $outFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue }
  if (Test-Path $errFile) { $errText = Get-Content $errFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue }

  ($outText + "`n" + $errText) | Set-Content -Encoding UTF8 $MachineOutput
  Add-Content -Encoding UTF8 $MachineOutput "__EXIT_CODE__:$flutterExitCode"

  Remove-Item $outFile,$errFile -ErrorAction SilentlyContinue
} finally {
  if ($null -ne $ChromedriverProcess -and -not $ChromedriverProcess.HasExited) {
    Stop-Process -Id $ChromedriverProcess.Id -Force
  }
  Pop-Location
}

Write-Host "==> Converting Flutter machine output to Allure results"
Push-Location $ProjectRoot
try {
  & dart run scripts\flutter_machine_to_allure.dart --input $MachineOutput --output $AllureResultsDir
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} finally {
  Pop-Location
}

$allureCommand = Get-Command allure -ErrorAction SilentlyContinue
if ($null -eq $allureCommand) {
  Write-Host ""
  Write-Host "Allure CLI is not installed, so only build\allure-results was generated."
  Write-Host "Install Allure CLI, then run:"
  Write-Host "  allure generate build\allure-results -o build\allure-report --clean"
  Write-Host "  allure open build\allure-report"
  Write-Host ""
  Write-Host "Windows install options:"
  Write-Host "  scoop install allure"
  Write-Host "  npm install -g allure-commandline"
  exit $flutterExitCode
}

Write-Host "==> Generating Allure HTML report"
Push-Location $ProjectRoot
try {
  & allure generate $AllureResultsDir -o $AllureReportDir --clean
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  # Inject Google Noto Sans font for Vietnamese support into generated report
  $indexPath = Join-Path $AllureReportDir "index.html"
  if (Test-Path $indexPath) {
    $html = Get-Content $indexPath -Raw -Encoding UTF8
    $fontLink = "<link href='https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;700&display=swap&subset=vietnamese' rel='stylesheet'>"
    $fontStyle = "<style>body{font-family: 'Noto Sans', system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif !important;}</style>"
    if ($html -notmatch [regex]::Escape($fontLink)) {
      $html = $html -replace '(?i)</head>', "$fontLink`n$fontStyle`n</head>"
      Set-Content -Path $indexPath -Value $html -Encoding UTF8
      Write-Host "Injected Noto Sans font into $indexPath"
    }
  }

  if ($Open) {
    & allure open $AllureReportDir
  } else {
    Write-Host ""
    Write-Host "Allure report generated:"
    Write-Host "  $AllureReportDir"
    Write-Host ""
    Write-Host "Open it with:"
    Write-Host "  allure open build\allure-report"
  }
} finally {
  Pop-Location
}

exit $flutterExitCode
