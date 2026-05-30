import 'dart:convert';
import 'dart:io';

class FlutterTestCase {
  FlutterTestCase({required this.id, required this.name, required this.start});

  final int id;
  final String name;
  final int start;
  int? stop;
  String status = 'passed';
  String? error;
  String? stackTrace;
  final List<String> logs = [];
}

void main(List<String> args) {
  final inputPath =
      _argValue(args, '--input') ?? 'build/test-results/flutter-test.jsonl';
  final outputPath = _argValue(args, '--output') ?? 'build/allure-results';

  final input = File(inputPath);
  if (!input.existsSync()) {
    stderr.writeln('Input file not found: ${input.path}');
    exitCode = 2;
    return;
  }

  final output = Directory(outputPath);
  if (output.existsSync()) {
    output.deleteSync(recursive: true);
  }
  output.createSync(recursive: true);

  final tests = <int, FlutterTestCase>{};
  final passMilestones = <String>[];
  final errorsByTest = <int, List<Map<String, dynamic>>>{};
  final rawLines = <String>[];
  String? plainTestName;
  int? plainExitCode;
  final startedAt = DateTime.now().millisecondsSinceEpoch;
  var sawJsonEvents = false;

  for (final line in input.readAsLinesSync(encoding: utf8)) {
    if (line.trim().isEmpty) continue;
    final normalizedLine = line.replaceFirst(RegExp(r'^\uFEFF'), '');
    rawLines.add(normalizedLine);

    final exitCodeMatch = RegExp(r'^__EXIT_CODE__:(-?\d+)\s*$').firstMatch(normalizedLine.trim());
    if (exitCodeMatch != null) {
      plainExitCode = int.tryParse(exitCodeMatch.group(1)!);
      continue;
    }

    final event = _tryDecode(normalizedLine);
    if (event != null) {
      sawJsonEvents = true;

      final type = event['type'];
      final time = startedAt + ((event['time'] as num?)?.toInt() ?? 0);

      if (type == 'testStart') {
        final test = event['test'] as Map<String, dynamic>?;
        if (test == null) continue;
        final id = (test['id'] as num).toInt();
        tests[id] = FlutterTestCase(
          id: id,
          name: (test['name'] ?? 'Unnamed Flutter test').toString(),
          start: time,
        );
      } else if (type == 'print') {
        final message = (event['message'] ?? '').toString();
        final testId = (event['testID'] as num?)?.toInt();
        if (testId != null) {
          tests[testId]?.logs.add(message);
        }

        final passName = _extractPassMilestone(message);
        if (passName != null) {
          passMilestones.add(passName);
        }
      } else if (type == 'testStart') {
        final test = event['test'] as Map<String, dynamic>?;
        if (test != null) {
          plainTestName ??= (test['name'] ?? '').toString();
        }
      } else if (type == 'error') {
        final testId = (event['testID'] as num?)?.toInt();
        if (testId == null) continue;
        errorsByTest.putIfAbsent(testId, () => []).add(event);
        final test = tests[testId];
        if (test != null) {
          test.status = 'failed';
          test.error = (event['error'] ?? '').toString();
          test.stackTrace = (event['stackTrace'] ?? '').toString();
        }
      } else if (type == 'testDone') {
        final testId = (event['testID'] as num?)?.toInt();
        if (testId == null) continue;
        final test = tests[testId];
        if (test == null) continue;
        test.stop = time;

        final result = (event['result'] ?? '').toString();
        if (result == 'failure' || result == 'error') {
          test.status = 'failed';
        } else if (result == 'skipped') {
          test.status = 'skipped';
        }

        final error = errorsByTest[testId]?.last;
        if (error != null) {
          test.error ??= (error['error'] ?? '').toString();
          test.stackTrace ??= (error['stackTrace'] ?? '').toString();
        }
      }
    } else {
      final plainPassName = _extractPlainPassMilestone(normalizedLine);
      if (plainPassName != null) {
        passMilestones.add(plainPassName);
      }

      plainTestName ??= _extractPlainTestName(normalizedLine);
    }
  }

  // Consolidate PASS milestone prints into a single Allure result with steps.
  if (passMilestones.isNotEmpty) {
    final steps = <Map<String, dynamic>>[];
    for (var i = 0; i < passMilestones.length; i++) {
      final name = _formatMilestoneName(i + 1, passMilestones[i]);
      steps.add({
        'name': name,
        'status': 'passed',
        'stage': 'finished',
        'start': startedAt + ((i + 1) * 1000),
        'stop': startedAt + ((i + 1) * 1000) + 500,
      });
    }

    _writeAllureResult(
      output,
      uuid: _uuid('milestones-summary-${startedAt}'),
      name: 'Finance App E2E Milestones',
      fullName: 'Finance App E2E.Milestones',
      status: 'passed',
      start: startedAt,
      stop: startedAt + (passMilestones.length * 1000) + 500,
      suite: 'Finance App E2E Milestones',
      attachments: rawLines.isEmpty
          ? const []
          : [
              {
                'name': 'Flutter command output',
                'type': 'text/plain',
                'source': _writeAttachment(output, rawLines.join('\n')),
              }
            ],
      steps: steps,
    );
  }

  if (!sawJsonEvents) {
    final summaryName = plainTestName?.isNotEmpty == true
        ? plainTestName!
        : 'Flutter integration test';
    final summaryStatus = (plainExitCode ?? 1) == 0 ? 'passed' : 'failed';

    _writeAllureResult(
      output,
      uuid: _uuid('flutter-drive-summary-$summaryName'),
      name: summaryName,
      fullName: 'Flutter Integration.$summaryName',
      status: summaryStatus,
      start: startedAt,
      stop: startedAt + 1000,
      suite: 'Flutter Integration Tests',
      message: summaryStatus == 'passed'
          ? null
          : 'Flutter drive exited with code ${plainExitCode ?? 1}',
      attachments: rawLines.isEmpty
          ? const []
          : [
              {
                'name': 'Flutter command output',
                'type': 'text/plain',
                'source': _writeAttachment(output, rawLines.join('\n')),
              },
            ],
    );
  } else {
    for (final test in tests.values) {
      // Always write tests — don't skip passed tests even when pass milestones exist.

      _writeAllureResult(
        output,
        uuid: _uuid('flutter-${test.id}-${test.name}'),
        name: test.name,
        fullName: 'Flutter Integration.${test.name}',
        status: test.status,
        start: test.start,
        stop: test.stop ?? test.start,
        suite: 'Flutter Integration Tests',
        message: test.error,
        trace: test.stackTrace,
        attachments: test.logs.isEmpty
            ? const []
            : [
                {
                  'name': 'Flutter test log',
                  'type': 'text/plain',
                  'source': _writeAttachment(output, test.logs.join('\n')),
                },
              ],
      );
    }
  }

  if (tests.isEmpty && passMilestones.isEmpty && sawJsonEvents) {
    _writeAllureResult(
      output,
      uuid: _uuid('flutter-test-command-failed'),
      name: 'Flutter test command',
      fullName: 'Flutter Integration.Flutter test command',
      status: 'failed',
      start: startedAt,
      stop: startedAt,
      suite: 'Flutter Integration Tests',
      message: rawLines.isEmpty
          ? 'Flutter test did not emit machine-readable test events.'
          : rawLines.join('\n'),
      attachments: rawLines.isEmpty
          ? const []
          : [
              {
                'name': 'Flutter command output',
                'type': 'text/plain',
                'source': _writeAttachment(output, rawLines.join('\n')),
              },
            ],
    );
  }

  stdout.writeln('Allure results generated: ${output.path}');
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}

Map<String, dynamic>? _tryDecode(String line) {
  try {
    final decoded = jsonDecode(line);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

String? _extractPassMilestone(String message) {
  final match = RegExp(r'^\[PASS\]\s*(.+)$').firstMatch(message.trim());
  return match?.group(1)?.trim();
}

String? _extractPlainPassMilestone(String line) {
  return _extractPassMilestone(line);
}

String? _extractPlainTestName(String line) {
  final match = RegExp(r'^\d{2}:\d{2}\s+\+\d+:\s+(.+)$').firstMatch(line.trim());
  return match?.group(1)?.trim();
}

String _formatMilestoneName(int index, String name) {
  final id = index.toString().padLeft(2, '0');
  return 'TC$id - $name';
}

String _writeAttachment(Directory output, String content) {
  final source = '${_uuid(content)}-attachment.txt';
  File(
    '${output.path}${Platform.pathSeparator}$source',
  ).writeAsStringSync(content, encoding: utf8);
  return source;
}

void _writeAllureResult(
  Directory output, {
  required String uuid,
  required String name,
  required String fullName,
  required String status,
  required int start,
  required int stop,
  required String suite,
  String? message,
  String? trace,
  List<Map<String, dynamic>> attachments = const [],
  List<Map<String, dynamic>> steps = const [],
}) {
  final result = <String, dynamic>{
    'uuid': uuid,
    'historyId': _uuid(fullName),
    'testCaseId': _uuid(fullName),
    'name': name,
    'fullName': fullName,
    'status': status,
    'stage': 'finished',
    'start': start,
    'stop': stop,
    'labels': [
      {'name': 'suite', 'value': suite},
      {'name': 'framework', 'value': 'flutter_test'},
      {'name': 'language', 'value': 'dart'},
    ],
  };

  if (message != null && message.isNotEmpty) {
    result['statusDetails'] = {
      'message': message,
      if (trace != null && trace.isNotEmpty) 'trace': trace,
    };
  }

  if (attachments.isNotEmpty) {
    result['attachments'] = attachments;
  }

  if (steps.isNotEmpty) {
    result['steps'] = steps;
  }

  final file = File('${output.path}${Platform.pathSeparator}$uuid-result.json');
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result), encoding: utf8);
}

String _uuid(String input) {
  final hash = _fnv1a64(input).toRadixString(16).padLeft(16, '0');
  return '${hash.substring(0, 8)}-${hash.substring(8, 12)}-'
          '4${hash.substring(13, 16)}-a${hash.substring(1, 4)}-$hash${hash.substring(0, 4)}'
      .substring(0, 36);
}

int _fnv1a64(String input) {
  var hash = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  for (final unit in utf8.encode(input)) {
    hash ^= unit;
    hash = (hash * prime) & 0x7fffffffffffffff;
  }
  return hash;
}
