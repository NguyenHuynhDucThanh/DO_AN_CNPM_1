import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Driver cho `flutter drive`. Ghi `binding.reportData` (chứa danh sách
/// milestones) ra file JSON tin cậy thay vì phụ thuộc vào stdout — print() trên
/// web bị relay lossy nên số dòng [PASS] bắt được không ổn định.
Future<void> main() => integrationDriver(
      // Ghi cả khi test fail để giữ các milestone đã đạt trước khi lỗi.
      writeResponseOnFailure: true,
      responseDataCallback: (Map<String, dynamic>? data) async {
        if (data == null) return;
        final file = File('build/test-results/e2e-report.json');
        file.parent.createSync(recursive: true);
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(data),
          flush: true,
        );
      },
    );
