# finance_app

Finance management application built with Flutter, Riverpod, Firebase Auth,
and Cloud Firestore.

## Test report with Allure

The project includes a simple Allure reporting pipeline for integration tests:

```text
flutter drive on Chrome
        -> build/test-results/flutter-test.jsonl
        -> build/allure-results
        -> build/allure-report
```

Run the report script:

```powershell
.\scripts\run_allure_report.ps1
```

Run on a specific Flutter device. The current E2E flow is verified on Chrome,
and the script will use the local `chromedriver.exe` in the project root when
`-Device` is left empty:

```powershell
.\scripts\run_allure_report.ps1 -Device windows
```

If you want to run the same web E2E flow manually, the known-good command is:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome --dart-define=E2E_SLOW_MS=1200
```

Running on `windows` still requires a working Visual Studio toolchain. Check it with:

```powershell
flutter doctor
```

Generate and open the report in one command:

```powershell
.\scripts\run_allure_report.ps1 -Open
```

The HTML dashboard is generated at:

```text
build/allure-report
```

If Allure CLI is not installed, the script still creates `build/allure-results`
and prints install commands. Install Allure with one of:

```powershell
scoop install allure
npm install -g allure-commandline
```

The current converter also maps `[PASS] ...` log milestones from
`integration_test/app_test.dart` into separate Allure test cases, so the report
shows a visual count of passed/failed test cases instead of one long E2E line.
