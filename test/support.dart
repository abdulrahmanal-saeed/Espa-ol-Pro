import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:espanol_pro/core/content/content_parser.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/db/database.dart';

const contentDir = 'assets/content/v1';

Future<ContentPack> loadRealContent() =>
    parseContentPack((path) => File('$contentDir/$path').readAsString());

AppDatabase memoryDb() {
  // Tests legitimately open several independent in-memory databases.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Controllable clock.
class FakeClock {
  FakeClock([DateTime? start])
    : now = start ?? DateTime.utc(2026, 3, 10, 9, 0, 0);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}
