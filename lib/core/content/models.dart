/// Immutable models for the versioned curriculum content package.
///
/// Pure Dart (no Flutter imports) so the same code runs in the app, in tests
/// and in the `tool/validate_content.dart` CLI.
library;

const cefrOrder = ['pre_a1', 'a1', 'a2', 'b1', 'b2', 'c1', 'c2'];

const skills = [
  'vocabulary',
  'listening',
  'reading',
  'writing',
  'speaking',
  'grammar',
];

const activityTypes = {
  'teach',
  'note',
  'mcq_meaning',
  'mcq_reverse',
  'listen_choose',
  'listen_pick_es',
  'type_es',
  'dictation',
  'fill',
  'order',
  'match',
  'speak',
  'choice',
  'respond',
};

const connectionTypes = {
  'arabic_origin',
  'cognate',
  'false_friend',
  'pronunciation',
  'grammar',
  'usage',
};

class ContentSource {
  const ContentSource({
    required this.id,
    required this.title,
    required this.license,
    required this.attribution,
    required this.reviewStatus,
  });

  final String id;
  final String title;
  final String license;
  final String attribution;

  /// `author_reviewed` | `native_reviewed` | `unreviewed`
  final String reviewStatus;

  factory ContentSource.fromJson(Map<String, dynamic> j) => ContentSource(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    license: j['license'] as String? ?? '',
    attribution: j['attribution'] as String? ?? '',
    reviewStatus: j['review_status'] as String? ?? '',
  );
}

class Level {
  const Level({
    required this.id,
    required this.code,
    required this.titleAr,
    required this.descriptionAr,
    required this.canDoAr,
    required this.isPreparatory,
    required this.units,
    this.requiresPass,
  });

  final String id;
  final String code;
  final String titleAr;
  final String descriptionAr;
  final List<String> canDoAr;
  final bool isPreparatory;
  final List<Unit> units;

  /// A level assessment of an earlier level that must be passed before any
  /// lesson of this level opens (`requires_pass`, content ≥ 1.11.0). Null
  /// when the level only needs its lesson prerequisites.
  final String? requiresPass;

  Iterable<Lesson> get lessons => units.expand((u) => u.lessons);
}

class Unit {
  const Unit({
    required this.id,
    required this.levelId,
    required this.titleAr,
    required this.descriptionAr,
    required this.status,
    required this.objectivesAr,
    required this.lessons,
    required this.grammar,
  });

  final String id;
  final String levelId;
  final String titleAr;
  final String descriptionAr;

  /// `available` (lessons shipped) or `planned` (curriculum map only).
  final String status;
  final List<String> objectivesAr;
  final List<Lesson> lessons;
  final List<GrammarNote> grammar;

  bool get isAvailable => status == 'available';
}

class Example {
  const Example({required this.es, required this.ar});
  final String es;
  final String ar;

  factory Example.fromJson(Map<String, dynamic> j) =>
      Example(es: j['es'] as String? ?? '', ar: j['ar'] as String? ?? '');
}

class LanguageConnection {
  const LanguageConnection({required this.type, required this.noteAr});
  final String type;
  final String noteAr;

  factory LanguageConnection.fromJson(Map<String, dynamic> j) =>
      LanguageConnection(
        type: j['type'] as String? ?? '',
        noteAr: j['ar'] as String? ?? '',
      );
}

class VocabItem {
  const VocabItem({
    required this.id,
    required this.es,
    required this.ar,
    required this.en,
    required this.pos,
    required this.examples,
    required this.noteAr,
    required this.tags,
    required this.work,
    required this.alt,
    required this.connections,
    this.syn = '',
    required this.lessonId,
    required this.levelId,
  });

  final String id;
  final String es;
  final String ar;
  final String en;
  final String pos;
  final List<Example> examples;
  final String noteAr;
  final List<String> tags;

  /// Relevant to the "Spanish for Work" track.
  final bool work;

  /// Other accepted written forms (e.g. feminine form, variant).
  final List<String> alt;
  final List<LanguageConnection> connections;

  /// Near-synonym group. Items sharing a group are never offered as
  /// distractors for each other (both would be defensible answers).
  final String syn;
  final String lessonId;
  final String levelId;

  /// Written forms graded as correct. A noun taught with its article
  /// ("el trabajo") is also accepted without it.
  List<String> get acceptedAnswers {
    final out = <String>[es, ...alt];
    for (final form in [es, ...alt]) {
      final m = RegExp(r'^(el|la|los|las) (.+)$').firstMatch(form);
      if (m != null && !out.contains(m.group(2))) out.add(m.group(2)!);
    }
    return out;
  }
}

class GrammarNote {
  const GrammarNote({
    required this.id,
    required this.titleAr,
    required this.bodyAr,
    required this.examples,
    required this.unitId,
  });

  final String id;
  final String titleAr;
  final String bodyAr;
  final List<Example> examples;
  final String unitId;
}

/// Raw authored activity. Turned into a concrete exercise by ExerciseBuilder.
class ActivitySpec {
  const ActivitySpec({
    required this.id,
    required this.type,
    required this.data,
  });

  final String id;
  final String type;
  final Map<String, dynamic> data;

  String? get itemId => data['item'] as String?;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.unitId,
    required this.levelId,
    required this.titleAr,
    required this.titleEs,
    required this.objectivesAr,
    required this.prerequisites,
    required this.minutes,
    required this.workRelevanceAr,
    required this.items,
    required this.activities,
    required this.sourceId,
    required this.grammarIds,
  });

  final String id;
  final String unitId;
  final String levelId;
  final String titleAr;
  final String titleEs;
  final List<String> objectivesAr;
  final List<String> prerequisites;
  final int minutes;
  final String workRelevanceAr;
  final List<VocabItem> items;
  final List<ActivitySpec> activities;
  final String sourceId;
  final List<String> grammarIds;
}

/// One verb in the conjugation reference (present tense).
class Verb {
  const Verb({
    required this.id,
    required this.infinitive,
    required this.ar,
    required this.regular,
    required this.forms,
    this.preterite = const {},
    bool? preteriteRegular,
    this.imperfect = const {},
    bool? imperfectRegular,
    this.conditional = const {},
    bool? conditionalRegular,
    this.subjunctive = const {},
    bool? subjunctiveRegular,
    this.noteAr = '',
    this.examples = const [],
    this.lessonIds = const [],
  }) : preteriteRegular = preteriteRegular ?? regular,
       imperfectRegular = imperfectRegular ?? regular,
       conditionalRegular = conditionalRegular ?? regular,
       subjunctiveRegular = subjunctiveRegular ?? regular;

  final String id;
  final String infinitive;
  final String ar;

  /// Regular verbs are checked against the conjugation rules.
  final bool regular;

  /// Present tense, keyed by [persons].
  final Map<String, String> forms;

  /// Pretérito indefinido, keyed by [persons]; empty when not given
  /// (content < 1.6.0), so older packages keep working.
  final Map<String, String> preterite;

  /// Whether [preterite] follows the rules (see [regularPreterite]). Defaults
  /// to [regular]; a verb irregular in the present can be regular in the past
  /// (volver: vuelvo / volví).
  final bool preteriteRegular;

  /// Pretérito imperfecto, keyed by [persons]; empty when not given
  /// (content < 1.11.0).
  final Map<String, String> imperfect;

  /// Whether [imperfect] follows [regularImperfect]. Defaults to [regular];
  /// most verbs irregular in the present are regular here (tener: tenía).
  final bool imperfectRegular;

  /// Condicional simple, keyed by [persons]; empty when not given.
  final Map<String, String> conditional;

  /// Whether [conditional] follows [regularConditional]. Defaults to
  /// [regular]; stem changes in the present do not affect it (podría is
  /// irregular, pensaría is not).
  final bool conditionalRegular;

  /// Presente de subjuntivo, keyed by [persons]; empty when not given.
  final Map<String, String> subjunctive;

  /// Whether [subjunctive] follows [regularSubjunctive]. Defaults to
  /// [regular].
  final bool subjunctiveRegular;

  final String noteAr;
  final List<Example> examples;

  /// Lessons where the verb is taught or used first.
  final List<String> lessonIds;

  static const persons = ['yo', 'tu', 'el', 'nosotros', 'vosotros', 'ellos'];

  static const personLabels = {
    'yo': 'yo',
    'tu': 'tú',
    'el': 'él / ella / usted',
    'nosotros': 'nosotros / nosotras',
    'vosotros': 'vosotros / vosotras',
    'ellos': 'ellos / ellas / ustedes',
  };

  /// The present tense a regular verb must have, or null for an unknown
  /// ending.
  static Map<String, String>? regularPresent(String infinitive) {
    if (infinitive.length < 3) return null;
    final stem = infinitive.substring(0, infinitive.length - 2);
    final endings = switch (infinitive.substring(infinitive.length - 2)) {
      'ar' => ['o', 'as', 'a', 'amos', 'áis', 'an'],
      'er' => ['o', 'es', 'e', 'emos', 'éis', 'en'],
      'ir' => ['o', 'es', 'e', 'imos', 'ís', 'en'],
      _ => null,
    };
    if (endings == null) return null;
    return {for (var i = 0; i < 6; i++) persons[i]: '$stem${endings[i]}'};
  }

  /// The pretérito indefinido a regular verb must have, or null for an
  /// unknown ending. Includes the spelling changes of the yo form that keep
  /// the sound: -car → qué, -gar → gué, -zar → cé (saqué, llegué, empecé).
  static Map<String, String>? regularPreterite(String infinitive) {
    if (infinitive.length < 3) return null;
    final stem = infinitive.substring(0, infinitive.length - 2);
    final ending = infinitive.substring(infinitive.length - 2);
    final endings = switch (ending) {
      'ar' => ['é', 'aste', 'ó', 'amos', 'asteis', 'aron'],
      'er' || 'ir' => ['í', 'iste', 'ió', 'imos', 'isteis', 'ieron'],
      _ => null,
    };
    if (endings == null) return null;
    var yoStem = stem;
    if (ending == 'ar') {
      if (stem.endsWith('c')) {
        yoStem = '${stem.substring(0, stem.length - 1)}qu';
      } else if (stem.endsWith('g')) {
        yoStem = '${stem}u';
      } else if (stem.endsWith('z')) {
        yoStem = '${stem.substring(0, stem.length - 1)}c';
      }
    }
    return {
      for (var i = 0; i < 6; i++)
        persons[i]: '${i == 0 ? yoStem : stem}${endings[i]}',
    };
  }

  /// The pretérito imperfecto a regular verb must have, or null for an
  /// unknown ending: -ar → -aba…, -er / -ir → -ía….
  static Map<String, String>? regularImperfect(String infinitive) {
    if (infinitive.length < 3) return null;
    final stem = infinitive.substring(0, infinitive.length - 2);
    final endings = switch (infinitive.substring(infinitive.length - 2)) {
      'ar' => ['aba', 'abas', 'aba', 'ábamos', 'abais', 'aban'],
      'er' || 'ir' => ['ía', 'ías', 'ía', 'íamos', 'íais', 'ían'],
      _ => null,
    };
    if (endings == null) return null;
    return {for (var i = 0; i < 6; i++) persons[i]: '$stem${endings[i]}'};
  }

  /// The condicional simple a regular verb must have: the whole infinitive
  /// plus -ía…. Null for an unknown ending.
  static Map<String, String>? regularConditional(String infinitive) {
    if (infinitive.length < 2 ||
        !const {
          'ar',
          'er',
          'ir',
        }.contains(infinitive.substring(infinitive.length - 2))) {
      return null;
    }
    const endings = ['ía', 'ías', 'ía', 'íamos', 'íais', 'ían'];
    return {for (var i = 0; i < 6; i++) persons[i]: '$infinitive${endings[i]}'};
  }

  /// The presente de subjuntivo a regular verb must have, or null for an
  /// unknown ending: -ar → -e…, -er / -ir → -a…. Spelling changes keep the
  /// sound in every person: -car → qu (explique), -gar → gu (llegue),
  /// -zar → c (organice), -ger / -gir → j (escoja).
  static Map<String, String>? regularSubjunctive(String infinitive) {
    if (infinitive.length < 3) return null;
    var stem = infinitive.substring(0, infinitive.length - 2);
    final ending = infinitive.substring(infinitive.length - 2);
    final endings = switch (ending) {
      'ar' => ['e', 'es', 'e', 'emos', 'éis', 'en'],
      'er' || 'ir' => ['a', 'as', 'a', 'amos', 'áis', 'an'],
      _ => null,
    };
    if (endings == null) return null;
    final head = stem.substring(0, stem.length - 1);
    if (ending == 'ar') {
      if (stem.endsWith('c')) {
        stem = '${head}qu';
      } else if (stem.endsWith('g')) {
        stem = '${stem}u';
      } else if (stem.endsWith('z')) {
        stem = '${head}c';
      }
    } else if (stem.endsWith('g')) {
      stem = '${head}j';
    }
    return {for (var i = 0; i < 6; i++) persons[i]: '$stem${endings[i]}'};
  }

  /// The optional tenses beyond the present, in teaching order. Each has a
  /// JSON key, the rule a regular form must follow, an Arabic label and the
  /// widget-key prefix used in Library → الأفعال (`verb-past-…` predates
  /// this list and is kept for compatibility).
  static final optionalTenses = <VerbTense>[
    VerbTense(
      key: 'preterite',
      labelAr: 'الماضي البسيط · pretérito indefinido',
      nameEn: 'past',
      uiKey: 'verb-past',
      forms: (v) => v.preterite,
      isRegular: (v) => v.preteriteRegular,
      rule: regularPreterite,
    ),
    VerbTense(
      key: 'imperfect',
      labelAr: 'الماضي المستمر · pretérito imperfecto',
      nameEn: 'imperfect',
      uiKey: 'verb-imperfect',
      forms: (v) => v.imperfect,
      isRegular: (v) => v.imperfectRegular,
      rule: regularImperfect,
    ),
    VerbTense(
      key: 'conditional',
      labelAr: 'الشرطي · condicional',
      nameEn: 'conditional',
      uiKey: 'verb-conditional',
      forms: (v) => v.conditional,
      isRegular: (v) => v.conditionalRegular,
      rule: regularConditional,
    ),
    VerbTense(
      key: 'subjunctive',
      labelAr: 'المضارع الالتزامي · presente de subjuntivo',
      nameEn: 'subjunctive',
      uiKey: 'verb-subjunctive',
      forms: (v) => v.subjunctive,
      isRegular: (v) => v.subjunctiveRegular,
      rule: regularSubjunctive,
    ),
  ];

  /// Every written form of this verb, all tenses.
  Iterable<String> get allForms => [
    ...forms.values,
    for (final t in optionalTenses) ...t.forms(this).values,
  ];
}

/// One optional tense of the verb reference (see [Verb.optionalTenses]).
class VerbTense {
  const VerbTense({
    required this.key,
    required this.labelAr,
    required this.nameEn,
    required this.uiKey,
    required this.forms,
    required this.isRegular,
    required this.rule,
  });

  /// JSON key; `<key>_regular` overrides the verb's `regular` flag.
  final String key;
  final String labelAr;

  /// Used in validator messages ("regular past form for …").
  final String nameEn;

  /// Widget-key prefix in the library: `<uiKey>-<verb>` for the header,
  /// `<uiKey>-<verb>-<person>` for each form.
  final String uiKey;
  final Map<String, String> Function(Verb) forms;
  final bool Function(Verb) isRegular;
  final Map<String, String>? Function(String infinitive) rule;
}

/// The fully loaded and indexed content package.
class ContentPack {
  ContentPack({
    required this.version,
    required this.levels,
    required this.sources,
    this.dialogues = const [],
    this.assessments = const [],
    this.verbs = const [],
  }) {
    for (final v in verbs) {
      _verbs[v.id] = v;
    }
    for (final a in assessments) {
      _assessments[a.id] = a;
    }
    for (final d in dialogues) {
      _dialogues[d.id] = d;
    }
    for (final level in levels) {
      for (final unit in level.units) {
        _units[unit.id] = unit;
        for (final g in unit.grammar) {
          _grammar[g.id] = g;
        }
        for (final lesson in unit.lessons) {
          _lessons[lesson.id] = lesson;
          orderedLessons.add(lesson);
          for (final item in lesson.items) {
            _items[item.id] = item;
          }
        }
      }
    }
  }

  final String version;
  final List<Level> levels;
  final List<ContentSource> sources;

  /// Listening library, in authored order.
  final List<Dialogue> dialogues;
  final Map<String, Dialogue> _dialogues = {};
  Dialogue? dialogue(String id) => _dialogues[id];

  /// Verb conjugation reference, in authored order.
  final List<Verb> verbs;
  final Map<String, Verb> _verbs = {};
  Verb? verb(String id) => _verbs[id];

  /// Unit checkpoints and level assessments, in authored order.
  final List<Assessment> assessments;
  final Map<String, Assessment> _assessments = {};
  Assessment? assessment(String id) => _assessments[id];

  /// The checkpoint for [unitId], if one is authored.
  Assessment? checkpointFor(String unitId) {
    for (final a in assessments) {
      if (a.kind == 'unit' && a.unitId == unitId) return a;
    }
    return null;
  }

  /// The end-of-level assessment for [levelId], if one ships.
  Assessment? levelAssessmentFor(String levelId) {
    for (final a in assessments) {
      if (a.kind == 'level' && a.levelId == levelId) return a;
    }
    return null;
  }

  final Map<String, Unit> _units = {};
  final Map<String, Lesson> _lessons = {};
  final Map<String, VocabItem> _items = {};
  final Map<String, GrammarNote> _grammar = {};

  /// All shipped lessons in curriculum order.
  final List<Lesson> orderedLessons = [];

  Lesson? lesson(String id) => _lessons[id];
  Unit? unit(String id) => _units[id];
  VocabItem? item(String id) => _items[id];
  GrammarNote? grammarNote(String id) => _grammar[id];
  Level? level(String id) {
    for (final l in levels) {
      if (l.id == id) return l;
    }
    return null;
  }

  Iterable<VocabItem> get allItems => _items.values;
  Iterable<GrammarNote> get allGrammar => _grammar.values;

  /// Items of [lesson] plus everything taught earlier in the curriculum —
  /// the pool the exercise builder may draw distractors from.
  List<VocabItem> itemsUpTo(Lesson lesson) {
    final out = <VocabItem>[];
    for (final l in orderedLessons) {
      out.addAll(l.items);
      if (l.id == lesson.id) break;
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// Listening library (Phase 1.2). Authored, versioned content: only the
// learner's attempts are stored in SQLite.
// ---------------------------------------------------------------------------

class DialogueSpeaker {
  const DialogueSpeaker({
    required this.id,
    required this.name,
    required this.roleAr,
  });

  final String id;

  /// Display name (a Spanish first name, or a role in Arabic). Never spoken.
  final String name;
  final String roleAr;
}

class DialogueTurn {
  const DialogueTurn({
    required this.id,
    required this.speaker,
    required this.es,
    required this.ar,
    this.en = '',
  });

  final String id;
  final String speaker;

  /// The only text ever sent to the Spanish voice.
  final String es;
  final String ar;
  final String en;
}

/// A comprehension question about a dialogue.
///
/// `choice`: [promptAr], [choices], [answer] (index); optional [turnId] whose
/// Spanish is played as the stimulus; [choicesEs] says the choices are Spanish.
/// `speaker`: "who said this?" for [turnId]; choices are the speakers.
/// `dictation`: type what [turnId] says.
class DialogueQuestion {
  const DialogueQuestion({
    required this.id,
    required this.type,
    required this.skill,
    this.promptAr = '',
    this.choices = const [],
    this.answer = 0,
    this.turnId,
    this.choicesEs = true,
    this.explainAr = '',
  });

  final String id;
  final String type;
  final String skill;
  final String promptAr;
  final List<String> choices;
  final int answer;
  final String? turnId;
  final bool choicesEs;
  final String explainAr;

  static const types = {'choice', 'speaker', 'dictation'};
}

class Dialogue {
  const Dialogue({
    required this.id,
    required this.levelId,
    required this.unitId,
    required this.lessonIds,
    required this.titleEs,
    required this.titleAr,
    required this.scenarioAr,
    required this.objectivesAr,
    required this.speakers,
    required this.turns,
    required this.items,
    required this.grammarIds,
    required this.questions,
    required this.sourceId,
  });

  final String id;
  final String levelId;
  final String unitId;

  /// Lessons whose content the dialogue uses. It unlocks when ALL of them are
  /// completed, so a learner never meets it before the language it needs.
  final List<String> lessonIds;
  final String titleEs;
  final String titleAr;
  final String scenarioAr;
  final List<String> objectivesAr;
  final List<DialogueSpeaker> speakers;
  final List<DialogueTurn> turns;

  /// Vocabulary items the dialogue practises (curriculum item ids).
  final List<String> items;
  final List<String> grammarIds;
  final List<DialogueQuestion> questions;
  final String sourceId;

  DialogueSpeaker? speaker(String id) {
    for (final s in speakers) {
      if (s.id == id) return s;
    }
    return null;
  }

  DialogueTurn? turn(String id) {
    for (final t in turns) {
      if (t.id == id) return t;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Assessments (Phase 1.2B). Definitions are authored JSON; results live in
// SQLite (schema v5).
// ---------------------------------------------------------------------------

/// A learner-facing capability ("أستطيع …") that assessments give evidence
/// for. Its state is computed from checkpoint answers only (see
/// `CanDoEvidence`), never from lessons opened or completed.
class CanDo {
  const CanDo({required this.id, required this.ar, required this.lessonIds});

  final String id;
  final String ar;

  /// Lessons to revisit when the evidence is weak.
  final List<String> lessonIds;
}

/// One objectively scored assessment question.
///
/// `choice`: [promptAr], [choices], [answer]; optional [stimulusEs] (shown)
/// or [audioEs] (played, never shown); [choicesEs].
/// `type`: [promptAr] and optional [stimulusAr]; [accepted] Spanish answers.
/// `dictation`: [audioEs] is played; the learner types it.
class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.type,
    required this.skill,
    required this.canDoId,
    this.promptAr = '',
    this.stimulusEs,
    this.stimulusAr,
    this.audioEs,
    this.choices = const [],
    this.answer = 0,
    this.choicesEs = true,
    this.accepted = const [],
    this.dialogueTurnId,
    this.explainAr = '',
  });

  final String id;
  final String type;
  final String skill;
  final String canDoId;

  /// When set, [audioEs] is this dialogue turn's sentence.
  final String? dialogueTurnId;

  /// Shown on the result screen after a wrong answer (never during the
  /// checkpoint).
  final String explainAr;
  final String promptAr;
  final String? stimulusEs;
  final String? stimulusAr;
  final String? audioEs;
  final List<String> choices;
  final int answer;
  final bool choicesEs;
  final List<String> accepted;

  static const types = {'choice', 'type', 'dictation'};

  /// Skills an assessment can objectively measure. Speaking is deliberately
  /// absent: the app has no valid way to score it.
  static const measuredSkills = {
    'vocabulary',
    'reading',
    'listening',
    'writing',
    'grammar',
  };

  /// The canonical correct answer, for the results screen.
  String get correctAnswer => switch (type) {
    'choice' => choices[answer],
    'dictation' => audioEs ?? '',
    _ => accepted.isEmpty ? '' : accepted.first,
  };
}

class Assessment {
  const Assessment({
    required this.id,
    required this.version,
    required this.kind,
    required this.levelId,
    required this.unitId,
    required this.titleAr,
    required this.introAr,
    required this.canDos,
    required this.questions,
    required this.sourceId,
  });

  final String id;

  /// Bump whenever questions change; stored with every attempt.
  final int version;

  /// `unit` checkpoint or `level` assessment.
  final String kind;
  final String levelId;

  /// Set for unit checkpoints.
  final String? unitId;
  final String titleAr;
  final String introAr;
  final List<CanDo> canDos;
  final List<AssessmentQuestion> questions;
  final String sourceId;

  CanDo? canDo(String id) {
    for (final c in canDos) {
      if (c.id == id) return c;
    }
    return null;
  }

  AssessmentQuestion? question(String id) {
    for (final q in questions) {
      if (q.id == id) return q;
    }
    return null;
  }
}
