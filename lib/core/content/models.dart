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
  });

  final String id;
  final String code;
  final String titleAr;
  final String descriptionAr;
  final List<String> canDoAr;
  final bool isPreparatory;
  final List<Unit> units;

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

/// The fully loaded and indexed content package.
class ContentPack {
  ContentPack({
    required this.version,
    required this.levels,
    required this.sources,
    this.dialogues = const [],
  }) {
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
