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
  final dialogues = <Dialogue>[];
  for (final file in _strings(root['dialogue_files'])) {
    final json = jsonDecode(await read(file)) as Map<String, dynamic>;
    for (final raw in json['dialogues'] as List? ?? const []) {
      dialogues.add(_dialogue((raw as Map).cast<String, dynamic>()));
    }
  }
  // Turn text by id, so a checkpoint question can play a dialogue sentence.
  final turns = {
    for (final d in dialogues)
      for (final t in d.turns) t.id: t.es,
  };
  final assessments = <Assessment>[];
  for (final file in _strings(root['assessment_files'])) {
    final json = jsonDecode(await read(file)) as Map<String, dynamic>;
    for (final raw in json['assessments'] as List? ?? const []) {
      assessments.add(_assessment((raw as Map).cast<String, dynamic>(), turns));
    }
  }
  final verbs = <Verb>[];
  final verbFile = root['verb_file'] as String?;
  if (verbFile != null) {
    final json = jsonDecode(await read(verbFile)) as Map<String, dynamic>;
    for (final raw in json['verbs'] as List? ?? const []) {
      final j = (raw as Map).cast<String, dynamic>();
      verbs.add(
        Verb(
          id: j['id'] as String? ?? '',
          infinitive: j['infinitive'] as String? ?? '',
          ar: j['ar'] as String? ?? '',
          regular: j['regular'] as bool? ?? false,
          forms: {
            for (final e in ((j['present'] as Map?) ?? const {}).entries)
              e.key as String: e.value as String,
          },
          noteAr: j['note_ar'] as String? ?? '',
          examples: [
            for (final e in j['examples'] as List? ?? const [])
              Example(
                es: (e as Map)['es'] as String? ?? '',
                ar: e['ar'] as String? ?? '',
              ),
          ],
          lessonIds: _strings(j['lessons']),
        ),
      );
    }
  }
  return ContentPack(
    version: version,
    levels: levels,
    sources: sources,
    dialogues: dialogues,
    assessments: assessments,
    verbs: verbs,
  );
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

Dialogue _dialogue(Map<String, dynamic> j) {
  final id = j['id'] as String;
  return Dialogue(
    id: id,
    levelId: j['level'] as String? ?? '',
    unitId: j['unit'] as String? ?? '',
    lessonIds: _strings(j['lessons']),
    titleEs: j['title_es'] as String? ?? '',
    titleAr: j['title_ar'] as String? ?? '',
    scenarioAr: j['scenario_ar'] as String? ?? '',
    objectivesAr: _strings(j['objectives_ar']),
    speakers: [
      for (final raw in j['speakers'] as List? ?? const [])
        DialogueSpeaker(
          id: (raw as Map)['id'] as String? ?? '',
          name: raw['name'] as String? ?? '',
          roleAr: raw['role_ar'] as String? ?? '',
        ),
    ],
    turns: [
      for (var i = 0; i < (j['turns'] as List? ?? const []).length; i++)
        _turn(id, i, ((j['turns'] as List)[i] as Map).cast<String, dynamic>()),
    ],
    items: _strings(j['items']),
    grammarIds: _strings(j['grammar']),
    questions: [
      for (var i = 0; i < (j['questions'] as List? ?? const []).length; i++)
        _question(
          id,
          i,
          ((j['questions'] as List)[i] as Map).cast<String, dynamic>(),
        ),
    ],
    sourceId: j['source'] as String? ?? '',
  );
}

DialogueTurn _turn(String dialogueId, int i, Map<String, dynamic> j) =>
    DialogueTurn(
      id: j['id'] as String? ?? '$dialogueId.t${i + 1}',
      speaker: j['speaker'] as String? ?? '',
      es: j['es'] as String? ?? '',
      ar: j['ar'] as String? ?? '',
      en: j['en'] as String? ?? '',
    );

DialogueQuestion _question(String dialogueId, int i, Map<String, dynamic> j) =>
    DialogueQuestion(
      id: j['id'] as String? ?? '$dialogueId.q${i + 1}',
      type: j['type'] as String? ?? '',
      skill: j['skill'] as String? ?? 'listening',
      promptAr: j['prompt_ar'] as String? ?? '',
      choices: _strings(j['choices']),
      answer: j['answer'] as int? ?? 0,
      turnId: j['turn'] as String?,
      choicesEs: j['choices_es'] as bool? ?? true,
      explainAr: j['explain_ar'] as String? ?? '',
    );

Assessment _assessment(Map<String, dynamic> j, Map<String, String> turns) {
  final id = j['id'] as String;
  final questions = j['questions'] as List? ?? const [];
  return Assessment(
    id: id,
    version: j['version'] as int? ?? 0,
    kind: j['kind'] as String? ?? '',
    levelId: j['level'] as String? ?? '',
    unitId: j['unit'] as String?,
    titleAr: j['title_ar'] as String? ?? '',
    introAr: j['intro_ar'] as String? ?? '',
    canDos: [
      for (final raw in j['can_do'] as List? ?? const [])
        CanDo(
          id: (raw as Map)['id'] as String? ?? '',
          ar: raw['ar'] as String? ?? '',
          lessonIds: _strings(raw['lessons']),
        ),
    ],
    questions: [
      for (var i = 0; i < questions.length; i++)
        _assessmentQuestion(
          id,
          i,
          (questions[i] as Map).cast<String, dynamic>(),
          turns,
        ),
    ],
    sourceId: j['source'] as String? ?? '',
  );
}

AssessmentQuestion _assessmentQuestion(
  String assessmentId,
  int i,
  Map<String, dynamic> j,
  Map<String, String> turns,
) => AssessmentQuestion(
  id: j['id'] as String? ?? '$assessmentId.q${i + 1}',
  dialogueTurnId: j['dialogue_turn'] as String?,
  explainAr: j['explain_ar'] as String? ?? '',
  type: j['type'] as String? ?? '',
  skill: j['skill'] as String? ?? '',
  canDoId: j['can_do'] as String? ?? '',
  promptAr: j['prompt_ar'] as String? ?? '',
  stimulusEs: j['stimulus_es'] as String?,
  stimulusAr: j['stimulus_ar'] as String?,
  // A dialogue turn supplies the audio, so the checkpoint plays exactly
  // the sentence the learner heard in the listening library.
  audioEs: j['audio_es'] as String? ?? turns[j['dialogue_turn']],
  choices: _strings(j['choices']),
  answer: j['answer'] as int? ?? 0,
  choicesEs: j['choices_es'] as bool? ?? true,
  accepted: _strings(j['accepted']),
);
