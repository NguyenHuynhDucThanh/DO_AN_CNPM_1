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
$MilestonesReport = Join-Path $TestResultsDir "e2e-report.json"
$ReportServerPortFile = Join-Path $TestResultsDir "allure-report-port.txt"
$DeviceName = if ($Device -ne "") { $Device } else { "chrome" }
$ChromedriverProcess = $null
$ScriptStart = Get-Date
$TempDir = $env:TEMP

# Dọn rác tạm do flutter drive / chromedriver tạo ra: mỗi lần chạy đẻ một
# profile Chrome tạm (scoped_dir*) ~chục–trăm MB và KHÔNG tự xóa → đầy ổ C.
# Chỉ xóa thư mục được sửa từ thời điểm $Since trở đi (tránh đụng Chrome khác
# của người dùng); thư mục đang bị khóa sẽ tự bỏ qua.
function Clear-RunTemp {
  param([datetime]$Since)
  foreach ($pattern in @('scoped_dir*', 'flutter_tools.*', '.org.chromium.*', '.com.google.Chrome.*')) {
    Get-ChildItem -Path $TempDir -Filter $pattern -Directory -Force -ErrorAction SilentlyContinue |
      Where-Object { $_.LastWriteTime -ge $Since } |
      ForEach-Object {
        try { Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop } catch { }
      }
  }
}

function Clear-StaleFlutterWebTemp {
  param([datetime]$Since)

  $targets = Get-ChildItem -Path $TempDir -Directory -Force -ErrorAction SilentlyContinue |
    Where-Object {
      $_.LastWriteTime -ge $Since -and (
        $_.Name -like 'scoped_dir*' -or
        $_.Name -like 'flutter_tools.*' -or
        $_.FullName -like '*flutter_tools_chrome_device*'
      )
    }

  foreach ($target in @($targets)) {
    try {
      Write-Host "Removing stale Flutter temp folder: $($target.FullName)"
      Remove-Item $target.FullName -Recurse -Force -ErrorAction Stop
    } catch {
      Write-Host "[WARN] Could not remove stale Flutter temp folder: $($target.FullName)"
    }
  }
}

function Wait-ForTcpPort {
  param(
    [int]$Port,
    [int]$TimeoutSeconds = 15
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if ($null -ne $connection) {
      return $true
    }
    Start-Sleep -Milliseconds 250
  }

  return $false
}

function Get-FreeTcpPort {
  $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
  try {
    $listener.Start()
    return ($listener.LocalEndpoint).Port
  } finally {
    $listener.Stop()
  }
}

function Start-AllureReportServer {
  param(
    [string]$ReportDir,
    [string]$PortFile
  )

  if (Test-Path $PortFile) {
    try {
      $existingPort = [int](Get-Content $PortFile -Raw -ErrorAction Stop)
      if (Get-NetTCPConnection -LocalPort $existingPort -ErrorAction SilentlyContinue) {
        return $existingPort
      }
    } catch {
      # Fall through and create a fresh server.
    }
  }

  $port = Get-FreeTcpPort
  $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
  if ($null -eq $pythonCommand) {
    throw "Python is required to serve the Allure report over localhost"
  }

  Start-Process -FilePath $pythonCommand.Source -ArgumentList @(
    '-m', 'http.server', "$port", '--bind', '127.0.0.1', '--directory', $ReportDir
  ) -WindowStyle Hidden | Out-Null

  if (-not (Wait-ForTcpPort -Port $port -TimeoutSeconds 10)) {
    throw "Allure report server did not start listening on port $port"
  }

  Set-Content -Path $PortFile -Value $port -Encoding ASCII
  return $port
}

function Invoke-FlutterDrive {
  param(
    [string]$OutFile,
    [string]$ErrFile,
    [string[]]$Arguments
  )

  $cleanArguments = @($Arguments | Where-Object { $_ -ne $null -and $_ -ne '' })
  $argumentLine = $cleanArguments -join ' '
  $process = Start-Process -FilePath "flutter" -ArgumentList $argumentLine -NoNewWindow -RedirectStandardOutput $OutFile -RedirectStandardError $ErrFile -Wait -PassThru
  return $process.ExitCode
}

function Stop-ChromedriverOnPort {
  param([int]$Port)

  $connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
  foreach ($connection in @($connections | Sort-Object OwningProcess -Unique)) {
    try {
      $owner = Get-Process -Id $connection.OwningProcess -ErrorAction Stop
      if ($owner.ProcessName -ieq 'chromedriver') {
        Write-Host "Closing existing chromedriver on port $Port (PID $($owner.Id))"
        Stop-Process -Id $owner.Id -Force -ErrorAction SilentlyContinue
      }
    } catch {
      # Ignore processes that exit between lookup and stop.
    }
  }
}

function Stop-FlutterChromeBrowser {
  $browserProcesses = Get-CimInstance Win32_Process -Filter "Name = 'chrome.exe'" |
    Where-Object { $_.CommandLine -like '*flutter_tools_chrome_device*' }

  foreach ($process in @($browserProcesses)) {
    try {
      Write-Host "Closing Flutter Chrome browser (PID $($process.ProcessId))"
      Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    } catch {
      # Ignore processes that have already exited.
    }
  }
}

function Stop-FlutterWebDriverChrome {
  $webdriverProcesses = Get-CimInstance Win32_Process -Filter "Name = 'chrome.exe'" |
    Where-Object {
      $_.CommandLine -like '*--test-type=webdriver*' -and
      (
        $_.CommandLine -like '*scoped_dir*' -or
        $_.CommandLine -like '*flutter_tools_chrome_device*'
      )
    }

  foreach ($process in @($webdriverProcesses)) {
    try {
      Write-Host "Closing Flutter WebDriver Chrome (PID $($process.ProcessId))"
      Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    } catch {
      # Ignore processes that have already exited.
    }
  }
}

New-Item -ItemType Directory -Force -Path $TestResultsDir | Out-Null

# Đóng mọi process test cũ trước, rồi mới dọn temp folders/log cũ để tránh
# xóa khi chúng هنوز còn bị khóa.
Stop-ChromedriverOnPort -Port 4444
Stop-FlutterChromeBrowser
Stop-FlutterWebDriverChrome
Start-Sleep -Milliseconds 500

# Dọn log/screenshot cũ còn sót từ các lần chạy trước (đặc biệt khi run bị ngắt).
Get-ChildItem -Path $TestResultsDir -Filter 'flutter-out-*.log' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $TestResultsDir -Filter 'flutter-err-*.log' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $ProjectRoot -Filter 'failure-*.png' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
# Dọn profile Chrome tạm còn sót từ các lần chạy trước (không giới hạn thời gian).
Clear-RunTemp -Since ([datetime]::MinValue)
Clear-StaleFlutterWebTemp -Since ([datetime]::MinValue)

Write-Host "==> Running Flutter integration tests"
Push-Location $ProjectRoot
try {
  if ($DeviceName -eq "chrome") {
    $chromedriverPath = Join-Path $ProjectRoot "chromedriver.exe"
    if (-not (Test-Path $chromedriverPath)) {
      throw "Chrome device requested but chromedriver.exe was not found at $chromedriverPath"
    }

    Stop-ChromedriverOnPort -Port 4444
    Start-Sleep -Milliseconds 500

    $ChromedriverProcess = Start-Process -FilePath $chromedriverPath -ArgumentList "--port=4444" -PassThru -WindowStyle Hidden
    if (-not (Wait-ForTcpPort -Port 4444 -TimeoutSeconds 15)) {
      throw "chromedriver.exe did not start listening on port 4444"
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
  if (Test-Path $MachineOutput) {
    try { Remove-Item $MachineOutput -Force } catch {
      Write-Host "[WARN] Could not remove ${MachineOutput}: $($_.Exception.Message)"
    }
  }
  # Dọn file milestone report cũ để lần chạy này không tái dùng dữ liệu cũ nếu
  # flutter crash trước khi driver kịp ghi file mới.
  if (Test-Path $MilestonesReport) {
    try { Remove-Item $MilestonesReport -Force } catch {
      Write-Host "[WARN] Could not remove ${MilestonesReport}: $($_.Exception.Message)"
    }
  }
  $ts = Get-Date -Format "yyyyMMddTHHmmss"
  $outFile = Join-Path $TestResultsDir ("flutter-out-$ts.log")
  $errFile = Join-Path $TestResultsDir ("flutter-err-$ts.log")
  if (Test-Path $outFile) {
    try { Remove-Item $outFile -Force } catch {
      Write-Host "[WARN] Could not remove ${outFile}: $($_.Exception.Message)"
    }
  }
  if (Test-Path $errFile) {
    try { Remove-Item $errFile -Force } catch {
      Write-Host "[WARN] Could not remove ${errFile}: $($_.Exception.Message)"
    }
  }

  $flutterExitCode = Invoke-FlutterDrive -OutFile $outFile -ErrFile $errFile -Arguments $flutterArgs

  $outText = ''
  $errText = ''
  if (Test-Path $outFile) { $outText = Get-Content $outFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue }
  if (Test-Path $errFile) { $errText = Get-Content $errFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue }

  $combinedText = $outText + "`n" + $errText
  if ($flutterExitCode -ne 0 -and $DeviceName -eq "chrome" -and $combinedText -match 'AppConnectionException') {
    Write-Host "[WARN] Flutter Chrome debug connection failed; restarting chromedriver and retrying once."
    if ($null -ne $ChromedriverProcess -and -not $ChromedriverProcess.HasExited) {
      Stop-Process -Id $ChromedriverProcess.Id -Force
    }

    $ChromedriverProcess = Start-Process -FilePath $chromedriverPath -ArgumentList "--port=4444" -PassThru -WindowStyle Hidden
    if (-not (Wait-ForTcpPort -Port 4444 -TimeoutSeconds 15)) {
      throw "chromedriver.exe did not restart listening on port 4444"
    }

    if (Test-Path $outFile) { try { Remove-Item $outFile -Force } catch { Write-Host "[WARN] Could not remove ${outFile}: $($_.Exception.Message)" } }
    if (Test-Path $errFile) { try { Remove-Item $errFile -Force } catch { Write-Host "[WARN] Could not remove ${errFile}: $($_.Exception.Message)" } }

    $flutterExitCode = Invoke-FlutterDrive -OutFile $outFile -ErrFile $errFile -Arguments $flutterArgs
    $outText = ''
    $errText = ''
    if (Test-Path $outFile) { $outText = Get-Content $outFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue }
    if (Test-Path $errFile) { $errText = Get-Content $errFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue }
    $combinedText = $outText + "`n" + $errText
  }

  $combinedText | Set-Content -Encoding UTF8 $MachineOutput
  Add-Content -Encoding UTF8 $MachineOutput "__EXIT_CODE__:$flutterExitCode"

  Remove-Item $outFile,$errFile -ErrorAction SilentlyContinue
} finally {
  if ($null -ne $ChromedriverProcess -and -not $ChromedriverProcess.HasExited) {
    Stop-Process -Id $ChromedriverProcess.Id -Force
  }
  Stop-FlutterChromeBrowser
  Stop-FlutterWebDriverChrome
  # Cho Chrome automation đóng hẳn rồi xóa profile tạm của lần chạy này.
  Start-Sleep -Seconds 2
  Clear-RunTemp -Since $ScriptStart
  Clear-StaleFlutterWebTemp -Since $ScriptStart
  Pop-Location
}

Write-Host "==> Converting Flutter machine output to Allure results"
Push-Location $ProjectRoot
try {
  & dart run scripts\flutter_machine_to_allure.dart --input $MachineOutput --output $AllureResultsDir --milestones $MilestonesReport
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

Write-Host "==> Generating Allure HTML report and opening it"
Push-Location $ProjectRoot
try {
  # Generate clean report to ensure index.html exists (helps with font injection for static open)
  & allure generate $AllureResultsDir -o $AllureReportDir --clean
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  # Inject Google Noto Sans into generated report (best-effort)
  $indexPath = Join-Path $AllureReportDir "index.html"
  if (Test-Path $indexPath) {
    try {
      $html = Get-Content $indexPath -Raw -Encoding UTF8
      $fontLink = "<link href='https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;700&display=swap&subset=vietnamese' rel='stylesheet'>"
      $fontStyle = "<style>body{font-family: 'Noto Sans', system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif !important;}</style>"
      if ($html -notmatch [regex]::Escape($fontLink)) {
        $html = $html -replace '(?i)</head>', "$fontLink`n$fontStyle`n</head>"
        Set-Content -Path $indexPath -Value $html -Encoding UTF8
        Write-Host "Injected Noto Sans font into $indexPath"
      }
    } catch {
      Write-Host "[WARN] Could not inject font into generated index.html: $($_.Exception.Message)"
    }
  }

  $reportServerPort = Start-AllureReportServer -ReportDir $AllureReportDir -PortFile $ReportServerPortFile
  $reportUrl = "http://127.0.0.1:$reportServerPort/index.html"
  Write-Host "Local report: $reportUrl"
  Start-Process $reportUrl | Out-Null
  Write-Host "Opened report in default browser: $reportUrl"
  Write-Host "Ready for next run"
} finally {
  Pop-Location
}

exit $flutterExitCode
