// Content validation CLI.
//
//   dart run tool/validate_content.dart [content-dir]
//
// Exits non-zero when the content package has any issue. Run in CI.
import 'dart:io';

import 'package:espanol_pro/core/content/content_parser.dart';
import 'package:espanol_pro/core/content/content_validator.dart';

Future<void> main(List<String> args) async {
  final dir = args.isEmpty ? 'assets/content/v1' : args.first;
  final pack = await parseContentPack(
    (path) => File('$dir/$path').readAsString(),
  );
  final issues = ContentValidator().validate(pack);
  final lessons = pack.orderedLessons;
  final acts = lessons.fold<int>(0, (n, l) => n + l.activities.length);
  final graded = lessons.fold<int>(
    0,
    (n, l) =>
        n + l.activities.where((a) => gradedTypes.contains(a.type)).length,
  );
  stdout.writeln(
    'Content v${pack.version}: ${pack.levels.length} levels, '
    '${pack.levels.expand((l) => l.units).length} units '
    '(${pack.levels.expand((l) => l.units).where((u) => u.isAvailable).length} available), '
    '${lessons.length} lessons, ${pack.allItems.length} vocabulary items, '
    '$acts activities ($graded graded), ${pack.allGrammar.length} grammar notes, '
    '${pack.dialogues.length} dialogues '
    '(${pack.dialogues.fold<int>(0, (n, d) => n + d.turns.length)} turns, '
    '${pack.dialogues.fold<int>(0, (n, d) => n + d.questions.length)} questions), '
    '${pack.assessments.length} assessments '
    '(${pack.assessments.fold<int>(0, (n, a) => n + a.questions.length)} questions).',
  );
  if (issues.isEmpty) {
    stdout.writeln('OK — no issues found.');
    return;
  }
  for (final i in issues) {
    stderr.writeln('ERROR $i');
  }
  stderr.writeln('${issues.length} issue(s) found.');
  exitCode = 1;
}
