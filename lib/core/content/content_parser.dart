import 'dart:convert';

import 'models.dart';

/// Reads a text file of the content package by its path relative to the
/// package root (e.g. `curriculum.json`, `units/pa1_u1.json`).
typedef ContentReader = Future<String> Function(String relativePath);

List<String> _strings(dynamic v) =>
    (v as List? ?? const []).map((e) => e.toString()).toList();

List<Example> _examples(dynamic v) => (v as List? ?? const [])
    .map((e) => Example.fromJson((e as Map).cast<String, dynamic>()))
    .toList();

/// Parses the content package. Structural problems that make parsing
/// impossible throw [FormatException]; everything else is reported by
/// `ContentValidator`.
Future<ContentPack> parseContentPack(ContentReader read) async {
  final root =
      jsonDecode(await read('curriculum.json')) as Map<String, dynamic>;
  final version = root['version'] as String? ?? '';
  final sources = (root['sources'] as List? ?? const [])
      .map((e) => ContentSource.fromJson((e as Map).cast<String, dynamic>()))
      .toList();

  final levels = <Level>[];
  for (final rawLevel in root['levels'] as List? ?? const []) {
    final lj = (rawLevel as Map).cast<String, dynamic>();
    final levelId = lj['id'] as String;
    final units = <Unit>[];
    for (final rawUnit in lj['units'] as List? ?? const []) {
      final uj = (rawUnit as Map).cast<String, dynamic>();
      final unitId = uj['id'] as String;
      final status = uj['status'] as String? ?? 'planned';
      var lessons = <Lesson>[];
      var grammar = <GrammarNote>[];
      if (status == 'available') {
        final file = jsonDecode(
          await read('units/$unitId.json'),
        ) as Map<String, dynamic>;
        grammar = (file['grammar'] as List? ?? const []).map((g) {
          final gj = (g as Map).cast<String, dynamic>();
          return GrammarNote(
            id: gj['id'] as String,
            titleAr: gj['title_ar'] as String? ?? '',
            bodyAr: gj['body_ar'] as String? ?? '',
            examples: _examples(gj['examples']),
            unitId: unitId,
          );
        }).toList();
        lessons = (file['lessons'] as List? ?? const [])
            .map(
              (l) => _lesson(
                (l as Map).cast<String, dynamic>(),
                unitId: unitId,
                levelId: levelId,
              ),
            )
            .toList();
      }
      units.add(
        Unit(
          id: unitId,
          levelId: levelId,
          titleAr: uj['title_ar'] as String? ?? '',
          descriptionAr: uj['description_ar'] as String? ?? '',
          status: status,
          objectivesAr: _strings(uj['objectives_ar']),
          lessons: lessons,
          grammar: grammar,
        ),
      );
    }
    levels.add(
      Level(
        id: levelId,
        code: lj['code'] as String? ?? '',
        titleAr: lj['title_ar'] as String? ?? '',
        descriptionAr: lj['description_ar'] as String? ?? '',
        canDoAr: _strings(lj['can_do_ar']),
        isPreparatory: lj['preparatory'] as bool? ?? false,
        units: units,
      ),
    );
  }
  return ContentPack(version: version, levels: levels, sources: sources);
}

Lesson _lesson(
  Map<String, dynamic> j, {
  required String unitId,
  required String levelId,
}) {
  final id = j['id'] as String;
  final items = (j['items'] as List? ?? const []).map((raw) {
    final ij = (raw as Map).cast<String, dynamic>();
    return VocabItem(
      id: ij['id'] as String,
      es: ij['es'] as String? ?? '',
      ar: ij['ar'] as String? ?? '',
      en: ij['en'] as String? ?? '',
      pos: ij['pos'] as String? ?? '',
      examples: _examples(ij['examples']),
      noteAr: ij['note_ar'] as String? ?? '',
      tags: _strings(ij['tags']),
      work: ij['work'] as bool? ?? false,
      alt: _strings(ij['alt']),
      connections: (ij['connections'] as List? ?? const [])
          .map(
            (c) =>
                LanguageConnection.fromJson((c as Map).cast<String, dynamic>()),
          )
          .toList(),
      syn: ij['syn'] as String? ?? '',
      lessonId: id,
      levelId: levelId,
    );
  }).toList();

  final activities = <ActivitySpec>[];
  final rawActs = j['activities'] as List? ?? const [];
  for (var i = 0; i < rawActs.length; i++) {
    final aj = (rawActs[i] as Map).cast<String, dynamic>();
    activities.add(
      ActivitySpec(
        id: aj['id'] as String? ?? '$id#${i + 1}',
        type: aj['type'] as String? ?? '',
        data: aj,
      ),
    );
  }

  return Lesson(
    id: id,
    unitId: unitId,
    levelId: levelId,
    titleAr: j['title_ar'] as String? ?? '',
    titleEs: j['title_es'] as String? ?? '',
    objectivesAr: _strings(j['objectives_ar']),
    prerequisites: _strings(j['prerequisites']),
    minutes: j['minutes'] as int? ?? 0,
    workRelevanceAr: j['work_relevance_ar'] as String? ?? '',
    items: items,
    activities: activities,
    sourceId: j['source'] as String? ?? '',
    grammarIds: _strings(j['grammar']),
  );
}
