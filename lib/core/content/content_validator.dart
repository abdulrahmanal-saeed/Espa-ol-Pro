import '../learning/answer_evaluator.dart';
import 'models.dart';

class ContentIssue {
  const ContentIssue(this.where, this.message);
  final String where;
  final String message;

  @override
  String toString() => '[$where] $message';
}

/// Activity types that require the learner to PRODUCE Spanish.
const productionTypes = {'type_es', 'dictation', 'fill', 'order', 'respond'};

/// Activity types that are graded automatically.
const gradedTypes = {
  'mcq_meaning',
  'mcq_reverse',
  'listen_choose',
  'listen_pick_es',
  'type_es',
  'dictation',
  'fill',
  'order',
  'match',
  'choice',
  'respond',
};

final _arabic = RegExp(r'[؀-ۿ]');
final _latin = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');

/// Deterministic structural + editorial checks over a [ContentPack].
///
/// This validates what a machine can verify (IDs, references, completeness,
/// script sanity, punctuation pairing, licensing metadata). It does NOT prove
/// linguistic correctness — that is tracked per source via `review_status`.
class ContentValidator {
  List<ContentIssue> validate(ContentPack pack) {
    final issues = <ContentIssue>[];
    void err(String where, String msg) => issues.add(ContentIssue(where, msg));

    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(pack.version)) {
      err(
        'curriculum',
        'version must be semantic (x.y.z), got "${pack.version}"',
      );
    }

    // --- sources & licensing ------------------------------------------------
    final sourceIds = <String>{};
    for (final s in pack.sources) {
      if (!sourceIds.add(s.id)) err('source:${s.id}', 'duplicate source id');
      if (s.license.trim().isEmpty) err('source:${s.id}', 'missing license');
      if (s.attribution.trim().isEmpty) {
        err('source:${s.id}', 'missing attribution');
      }
      if (!{
        'author_reviewed',
        'native_reviewed',
        'unreviewed',
      }.contains(s.reviewStatus)) {
        err('source:${s.id}', 'invalid review_status "${s.reviewStatus}"');
      }
    }

    // --- levels --------------------------------------------------------------
    final levelIds = pack.levels.map((l) => l.id).toList();
    if (levelIds.join(',') != cefrOrder.join(',')) {
      err('curriculum', 'levels must be exactly ${cefrOrder.join(' → ')}');
    }

    final unitIds = <String>{};
    final lessonIds = <String>{};
    final itemIds = <String>{};
    final grammarIds = <String>{};
    final activityIds = <String>{};
    final seenSpanish = <String, String>{};
    final taughtSoFar = <String>{};

    for (final level in pack.levels) {
      final lw = 'level:${level.id}';
      if (level.titleAr.trim().isEmpty) err(lw, 'missing title_ar');
      if (level.canDoAr.isEmpty) err(lw, 'missing can_do_ar descriptors');
      if (level.units.isEmpty) err(lw, 'level has no units in curriculum map');
      if (level.isPreparatory != (level.id == 'pre_a1')) {
        err(lw, 'only pre_a1 may be flagged preparatory');
      }

      for (final unit in level.units) {
        final uw = 'unit:${unit.id}';
        if (!unitIds.add(unit.id)) err(uw, 'duplicate unit id');
        if (unit.titleAr.trim().isEmpty) err(uw, 'missing title_ar');
        if (unit.objectivesAr.isEmpty) err(uw, 'missing objectives_ar');
        if (!{'available', 'planned'}.contains(unit.status)) {
          err(uw, 'invalid status "${unit.status}"');
        }
        if (unit.isAvailable && unit.lessons.isEmpty) {
          err(uw, 'available unit has no lessons');
        }

        for (final g in unit.grammar) {
          final gw = 'grammar:${g.id}';
          if (!grammarIds.add(g.id)) err(gw, 'duplicate grammar id');
          if (g.titleAr.trim().isEmpty || g.bodyAr.trim().isEmpty) {
            err(gw, 'grammar note needs title_ar and body_ar');
          }
          for (final e in g.examples) {
            _checkExample(e, gw, err);
          }
        }

        for (final lesson in unit.lessons) {
          final w = 'lesson:${lesson.id}';
          if (!lessonIds.add(lesson.id)) err(w, 'duplicate lesson id');
          if (lesson.titleAr.trim().isEmpty) err(w, 'missing title_ar');
          if (lesson.objectivesAr.isEmpty) err(w, 'missing objectives_ar');
          if (lesson.minutes <= 0) err(w, 'minutes must be > 0');
          if (!sourceIds.contains(lesson.sourceId)) {
            err(w, 'unknown content source "${lesson.sourceId}"');
          }
          for (final pre in lesson.prerequisites) {
            if (pre == lesson.id) {
              err(w, 'lesson lists itself as prerequisite');
            } else if (!lessonIds.contains(pre)) {
              err(w, 'prerequisite "$pre" is not an EARLIER lesson');
            }
          }
          for (final gid in lesson.grammarIds) {
            if (!grammarIds.contains(gid)) {
              err(w, 'unknown grammar reference "$gid"');
            }
          }

          // items
          for (final item in lesson.items) {
            final iw = 'item:${item.id}';
            if (!itemIds.add(item.id)) err(iw, 'duplicate item id');
            if (item.es.trim().isEmpty) err(iw, 'missing es');
            if (item.ar.trim().isEmpty) err(iw, 'missing ar');
            if (item.pos.trim().isEmpty) err(iw, 'missing pos');
            if (_arabic.hasMatch(item.es)) err(iw, 'es contains Arabic script');
            if (!_arabic.hasMatch(item.ar)) err(iw, 'ar has no Arabic script');
            _checkPunctuation(item.es, iw, err);
            if (item.examples.isEmpty) err(iw, 'needs at least one example');
            for (final e in item.examples) {
              _checkExample(e, iw, err);
            }
            for (final c in item.connections) {
              if (!connectionTypes.contains(c.type)) {
                err(iw, 'invalid connection type "${c.type}"');
              }
              if (c.noteAr.trim().isEmpty) err(iw, 'connection missing note');
            }
            final norm = normalizeAnswer(item.es);
            final prev = seenSpanish[norm];
            if (prev != null) {
              err(iw, 'duplicate Spanish text "${item.es}" (also in $prev)');
            } else {
              seenSpanish[norm] = item.id;
            }
          }

          // activities
          final lessonItemIds = lesson.items.map((i) => i.id).toSet();
          final taughtHere = <String>{};
          final usedTypes = <String>{};
          var graded = 0;
          for (final a in lesson.activities) {
            final aw = 'activity:${a.id}';
            if (!activityIds.add(a.id)) err(aw, 'duplicate activity id');
            if (!activityTypes.contains(a.type)) {
              err(aw, 'unknown activity type "${a.type}"');
              continue;
            }
            if (gradedTypes.contains(a.type)) {
              graded++;
              usedTypes.add(a.type);
            }

            bool itemOk(String? id, {bool required = true}) {
              if (id == null) {
                if (required) err(aw, '${a.type} requires "item"');
                return false;
              }
              if (!itemIds.contains(id)) {
                err(aw, 'references unknown or later item "$id"');
                return false;
              }
              if (a.type != 'teach' &&
                  lessonItemIds.contains(id) &&
                  !taughtHere.contains(id)) {
                err(aw, 'practises "$id" before its teach step');
              }
              return true;
            }

            String str(String k) => (a.data[k] as String? ?? '').trim();
            List list(String k) => a.data[k] as List? ?? const [];

            switch (a.type) {
              case 'teach':
                final id = a.itemId;
                if (itemOk(id)) {
                  if (!lessonItemIds.contains(id)) {
                    err(aw, 'teach must reference an item of this lesson');
                  }
                  if (!taughtHere.add(id!)) err(aw, 'item "$id" taught twice');
                }
              case 'note':
                if (str('title_ar').isEmpty || str('body_ar').isEmpty) {
                  err(aw, 'note needs title_ar and body_ar');
                }
              case 'mcq_meaning':
              case 'mcq_reverse':
              case 'listen_choose':
              case 'listen_pick_es':
              case 'type_es':
                itemOk(a.itemId);
              case 'dictation':
              case 'speak':
                if (a.itemId != null) {
                  itemOk(a.itemId);
                } else {
                  if (str('es').isEmpty || str('ar').isEmpty) {
                    err(aw, '${a.type} needs "item" or both "es" and "ar"');
                  }
                  _checkPunctuation(str('es'), aw, err);
                }
              case 'fill':
                if ('___'.allMatches(str('es')).length != 1) {
                  err(aw, 'fill "es" must contain exactly one ___ blank');
                }
                if (str('answer').isEmpty) err(aw, 'fill needs "answer"');
                if (str('ar').isEmpty) err(aw, 'fill needs "ar" translation');
                final opts = list('options');
                if (opts.isNotEmpty && !opts.contains(a.data['answer'])) {
                  err(aw, 'fill options must include the answer');
                }
                _checkPunctuation(
                  str('es').replaceAll('___', str('answer')),
                  aw,
                  err,
                );
              case 'order':
                if (str('es').split(RegExp(r'\s+')).length < 2) {
                  err(aw, 'order needs a sentence of at least 2 words');
                }
                if (str('ar').isEmpty) err(aw, 'order needs "ar"');
                _checkPunctuation(str('es'), aw, err);
              case 'match':
                final ids = list('items');
                if (ids.length < 3) err(aw, 'match needs at least 3 items');
                if (ids.toSet().length != ids.length) {
                  err(aw, 'match items must be distinct');
                }
                for (final id in ids) {
                  if (!itemIds.contains(id)) {
                    err(aw, 'references unknown or later item "$id"');
                  } else if (lessonItemIds.contains(id) &&
                      !taughtHere.contains(id)) {
                    err(aw, 'practises "$id" before its teach step');
                  }
                }
              case 'choice':
                final choices = list('choices');
                final ans = a.data['answer'];
                if (str('prompt_ar').isEmpty) err(aw, 'choice needs prompt_ar');
                if (choices.length < 2) err(aw, 'choice needs ≥ 2 choices');
                if (choices.toSet().length != choices.length) {
                  err(aw, 'choice options must be distinct');
                }
                if (ans is! int || ans < 0 || ans >= choices.length) {
                  err(aw, 'choice "answer" must be a valid index');
                }
                if (!skills.contains(a.data['skill'] ?? 'reading')) {
                  err(aw, 'invalid skill "${a.data['skill']}"');
                }
              case 'respond':
                if (str('prompt_ar').isEmpty) {
                  err(aw, 'respond needs prompt_ar');
                }
                final acc = list('accepted');
                if (acc.isEmpty) err(aw, 'respond needs accepted answers');
                for (final s in acc) {
                  _checkPunctuation(s.toString(), aw, err);
                }
            }
          }

          for (final id in lessonItemIds.difference(taughtHere)) {
            err(w, 'item "$id" has no teach step');
          }
          for (final item in lesson.items) {
            final practised = lesson.activities.any(
              (a) =>
                  gradedTypes.contains(a.type) &&
                  (a.itemId == item.id ||
                      (a.data['items'] as List? ?? const []).contains(item.id)),
            );
            if (!practised) {
              err(w, 'item "${item.id}" is never practised in a graded item');
            }
          }
          if (graded < 6) err(w, 'needs at least 6 graded activities');
          if (usedTypes.length < 4) {
            err(w, 'needs at least 4 distinct graded activity types');
          }
          if (usedTypes.intersection(productionTypes).isEmpty) {
            err(w, 'needs at least one production activity');
          }
          if (!lesson.activities.any(
            (a) =>
                a.type == 'listen_choose' ||
                a.type == 'listen_pick_es' ||
                a.type == 'dictation',
          )) {
            err(w, 'needs at least one listening activity');
          }
          taughtSoFar.addAll(lessonItemIds);
        }
      }
    }
    _validateLevelGates(pack, err);
    _validateDialogues(pack, sourceIds, grammarIds, err);
    _validateAssessments(pack, sourceIds, err);
    _validateVerbs(pack, err);
    _validateFinalStressWords(pack, err);
    return issues;
  }

  /// `requires_pass` must name the level assessment of an EARLIER level, so
  /// a gate can always be lifted by content the learner can already reach.
  void _validateLevelGates(
    ContentPack pack,
    void Function(String, String) err,
  ) {
    final order = [for (final l in pack.levels) l.id];
    for (final level in pack.levels) {
      final gate = level.requiresPass;
      if (gate == null) continue;
      final w = 'level:${level.id}';
      final test = pack.assessment(gate);
      if (test == null) {
        err(w, 'requires_pass "$gate" is not an assessment');
      } else if (test.kind != 'level') {
        err(w, 'requires_pass "$gate" must be a level assessment');
      } else if (order.indexOf(test.levelId) >= order.indexOf(level.id)) {
        err(w, 'requires_pass "$gate" must belong to an earlier level');
      }
    }
  }

  /// Every answer word of 5+ letters ending in a stressed é / ó must be a verb
  /// form (from the verb reference, or an item marked as a verb) or a listed
  /// non-verb ([finalStressNonVerbs]). The evaluator treats a missing final
  /// accent there as a different word and explains it as a change of tense,
  /// which is only true for verbs (REVIEW-015 P3).
  void _validateFinalStressWords(
    ContentPack pack,
    void Function(String, String) err,
  ) {
    final verbForms = <String>{
      for (final v in pack.verbs) ...v.allForms,
      for (final l in pack.orderedLessons)
        for (final i in l.items)
          if (i.pos.contains('فعل')) ...normalizeAnswer(i.es).split(' '),
    }.map(normalizeAnswer).toSet();

    void check(String where, String text) {
      for (final w in normalizeAnswer(text).split(' ')) {
        if (w.length < 5) continue;
        final last = w[w.length - 1];
        if (last != 'é' && last != 'ó') continue;
        if (verbForms.contains(w) || finalStressNonVerbs.contains(w)) continue;
        err(
          where,
          '"$w" ends in a stressed é/ó but is neither a verb form in the '
          'reference nor in finalStressNonVerbs',
        );
      }
    }

    for (final l in pack.orderedLessons) {
      for (final i in l.items) {
        for (final f in [i.es, ...i.alt]) {
          check('item:${i.id}', f);
        }
      }
      for (final a in l.activities) {
        final d = a.data;
        if (a.type == 'fill') {
          for (final f in [d['answer'], ...(d['alt'] as List? ?? const [])]) {
            check('activity:${a.id}', '$f');
          }
        }
        if (a.type == 'respond') {
          for (final f in d['accepted'] as List? ?? const []) {
            check('activity:${a.id}', '$f');
          }
        }
      }
    }
    for (final a in pack.assessments) {
      for (final q in a.questions) {
        for (final f in q.accepted) {
          check('question:${q.id}', f);
        }
      }
    }
  }

  /// Verb reference: complete, Spanish-only, tied to real lessons, and every
  /// regular verb conjugated exactly by the rules.
  void _validateVerbs(ContentPack pack, void Function(String, String) err) {
    final ids = <String>{};
    for (final v in pack.verbs) {
      final w = 'verb:${v.id}';
      if (!ids.add(v.id)) err(w, 'duplicate verb id');
      if (v.infinitive.trim().isEmpty) err(w, 'missing infinitive');
      if (!_arabic.hasMatch(v.ar)) err(w, 'ar has no Arabic script');
      for (final p in Verb.persons) {
        final f = v.forms[p] ?? '';
        if (f.trim().isEmpty) err(w, 'missing form for "$p"');
        if (_arabic.hasMatch(f)) err(w, 'form for "$p" contains Arabic script');
      }
      for (final k in v.forms.keys) {
        if (!Verb.persons.contains(k)) err(w, 'unknown person "$k"');
      }
      if (v.regular) {
        final expected = Verb.regularPresent(v.infinitive);
        if (expected == null) {
          err(w, 'a regular verb must end in -ar, -er or -ir');
        } else {
          for (final p in Verb.persons) {
            if (v.forms[p] != null && v.forms[p] != expected[p]) {
              err(w, 'regular form for "$p" should be "${expected[p]}"');
            }
          }
        }
      }
      // Optional tenses: the past (content ≥ 1.6.0), then the imperfect,
      // conditional and present subjunctive (content ≥ 1.11.0). Each may be
      // left out, but is complete when given; a regular one must equal the
      // rules exactly.
      for (final tense in Verb.optionalTenses) {
        final forms = tense.forms(v);
        if (forms.isEmpty) continue;
        final name = tense.nameEn;
        for (final p in Verb.persons) {
          final f = forms[p] ?? '';
          if (f.trim().isEmpty) err(w, 'missing $name form for "$p"');
          if (_arabic.hasMatch(f)) {
            err(w, '$name form for "$p" contains Arabic script');
          }
        }
        for (final k in forms.keys) {
          if (!Verb.persons.contains(k)) err(w, 'unknown $name person "$k"');
        }
        if (tense.isRegular(v)) {
          final expected = tense.rule(v.infinitive);
          if (expected == null) {
            err(w, 'a regular $name needs an -ar, -er or -ir verb');
          } else {
            for (final p in Verb.persons) {
              if (forms[p] != null && forms[p] != expected[p]) {
                err(
                  w,
                  'regular $name form for "$p" should be "${expected[p]}"',
                );
              }
            }
          }
        }
      }
      if (v.lessonIds.isEmpty) err(w, 'needs at least one lesson');
      for (final l in v.lessonIds) {
        if (pack.lesson(l) == null) err(w, 'unknown lesson "$l"');
      }
      if (v.examples.isEmpty) err(w, 'needs at least one example');
      for (final e in v.examples) {
        if (_arabic.hasMatch(e.es)) err(w, 'example es contains Arabic script');
        if (!_arabic.hasMatch(e.ar)) err(w, 'example ar has no Arabic script');
      }
    }
  }

  /// Assessments: objective, answerable, and tied to real lessons.
  void _validateAssessments(
    ContentPack pack,
    Set<String> sourceIds,
    void Function(String, String) err,
  ) {
    final ids = <String>{};
    final questionIds = <String>{};
    final checkpointUnits = <String>{};
    for (final a in pack.assessments) {
      final w = 'assessment:${a.id}';
      if (!ids.add(a.id)) err(w, 'duplicate assessment id');
      if (a.version < 1) err(w, 'version must be ≥ 1');
      if (a.titleAr.trim().isEmpty || a.introAr.trim().isEmpty) {
        err(w, 'needs title_ar and intro_ar');
      }
      if (!sourceIds.contains(a.sourceId)) {
        err(w, 'unknown content source "${a.sourceId}"');
      }
      final level = pack.level(a.levelId);
      if (level == null) err(w, 'unknown level "${a.levelId}"');
      switch (a.kind) {
        case 'unit':
          final unit = a.unitId == null ? null : pack.unit(a.unitId!);
          if (unit == null) {
            err(w, 'unit checkpoint needs a known "unit"');
          } else {
            if (unit.levelId != a.levelId) {
              err(w, 'unit "${unit.id}" is not in level "${a.levelId}"');
            }
            if (!unit.isAvailable) err(w, 'unit "${unit.id}" has no lessons');
            if (!checkpointUnits.add(unit.id)) {
              err(w, 'second checkpoint for unit "${unit.id}"');
            }
          }
        case 'level':
          if (a.unitId != null) err(w, 'a level assessment has no "unit"');
        default:
          err(w, 'kind must be "unit" or "level"');
      }

      // Can-do statements: real lessons, in scope, each with evidence.
      final canDoIds = <String>{};
      for (final c in a.canDos) {
        final cw = '$w/${c.id}';
        if (!canDoIds.add(c.id)) err(cw, 'duplicate can-do id');
        if (!_arabic.hasMatch(c.ar)) err(cw, 'can-do needs Arabic text');
        if (c.lessonIds.isEmpty) err(cw, 'can-do needs lessons to revisit');
        for (final l in c.lessonIds) {
          final lesson = pack.lesson(l);
          if (lesson == null) {
            err(cw, 'unknown lesson "$l"');
          } else if (a.kind == 'unit' && lesson.unitId != a.unitId) {
            err(cw, 'lesson "$l" is outside unit "${a.unitId}"');
          } else if (lesson.levelId != a.levelId && a.kind == 'level') {
            err(cw, 'lesson "$l" is outside level "${a.levelId}"');
          }
        }
        final evidence = a.questions.where((q) => q.canDoId == c.id).length;
        if (evidence < 2) {
          err(cw, 'needs at least 2 questions as evidence, has $evidence');
        }
      }

      if (a.questions.length < 8) err(w, 'needs at least 8 questions');
      final skillsUsed = <String>{};
      for (final q in a.questions) {
        final qw = '$w/${q.id}';
        if (!questionIds.add(q.id)) err(qw, 'duplicate question id');
        final turnId = q.dialogueTurnId;
        if (turnId != null) {
          final d = pack.dialogues
              .where((d) => d.turns.any((t) => t.id == turnId))
              .firstOrNull;
          if (d == null) {
            err(qw, 'unknown dialogue turn "$turnId"');
          } else if (a.unitId != null
              ? d.unitId != a.unitId
              : d.levelId != a.levelId) {
            err(qw, 'dialogue "${d.id}" is outside this assessment\'s scope');
          }
          if (q.skill != 'listening') {
            err(qw, 'a dialogue-turn question measures listening');
          }
        }
        if (!AssessmentQuestion.types.contains(q.type)) {
          err(qw, 'unknown question type "${q.type}"');
          continue;
        }
        if (!AssessmentQuestion.measuredSkills.contains(q.skill)) {
          err(qw, 'skill "${q.skill}" cannot be measured objectively');
        }
        skillsUsed.add(q.skill);
        if (!canDoIds.contains(q.canDoId)) {
          err(qw, 'unknown can-do "${q.canDoId}"');
        }
        void spanish(String? text, String field) {
          if (text == null) return;
          if (text.trim().isEmpty) err(qw, '$field is empty');
          if (_arabic.hasMatch(text)) err(qw, '$field contains Arabic script');
          _checkPunctuation(text, qw, err);
        }

        spanish(q.stimulusEs, 'stimulus_es');
        spanish(q.audioEs, 'audio_es');
        switch (q.type) {
          case 'choice':
            if (q.promptAr.trim().isEmpty) err(qw, 'choice needs prompt_ar');
            if (q.choices.length < 2) err(qw, 'choice needs ≥ 2 choices');
            if (q.choices.toSet().length != q.choices.length) {
              err(qw, 'choices must be distinct');
            }
            if (q.answer < 0 || q.answer >= q.choices.length) {
              err(qw, 'answer must be a valid index');
            }
            if (q.choicesEs) {
              for (final c in q.choices) {
                spanish(c, 'choice');
              }
            }
          case 'type':
            if (q.promptAr.trim().isEmpty) err(qw, 'type needs prompt_ar');
            if (q.accepted.isEmpty) err(qw, 'type needs accepted answers');
            for (final x in q.accepted) {
              spanish(x, 'accepted');
            }
          case 'dictation':
            if (q.audioEs == null) err(qw, 'dictation needs audio_es');
        }
      }
      if (skillsUsed.length < 3) {
        err(w, 'needs at least 3 different skills, has ${skillsUsed.length}');
      }
    }
  }

  /// Listening library: every reference must resolve, and a dialogue may only
  /// use vocabulary taught by (or before) the lessons it is linked to.
  void _validateDialogues(
    ContentPack pack,
    Set<String> sourceIds,
    Set<String> grammarIds,
    void Function(String, String) err,
  ) {
    final order = {
      for (var i = 0; i < pack.orderedLessons.length; i++)
        pack.orderedLessons[i].id: i,
    };
    final dialogueIds = <String>{};
    final turnIds = <String>{};
    final questionIds = <String>{};
    for (final d in pack.dialogues) {
      final w = 'dialogue:${d.id}';
      if (!dialogueIds.add(d.id)) err(w, 'duplicate dialogue id');
      if (d.titleEs.trim().isEmpty || d.titleAr.trim().isEmpty) {
        err(w, 'needs title_es and title_ar');
      }
      if (d.scenarioAr.trim().isEmpty) err(w, 'needs scenario_ar');
      if (d.objectivesAr.isEmpty) err(w, 'needs objectives_ar');
      if (!sourceIds.contains(d.sourceId)) {
        err(w, 'unknown content source "${d.sourceId}"');
      }
      final level = pack.level(d.levelId);
      final unit = pack.unit(d.unitId);
      if (level == null) err(w, 'unknown level "${d.levelId}"');
      if (unit == null) {
        err(w, 'unknown unit "${d.unitId}"');
      } else if (unit.levelId != d.levelId) {
        err(w, 'unit "${d.unitId}" is not in level "${d.levelId}"');
      }

      // Lessons: must exist; the latest one defines what has been taught.
      if (d.lessonIds.isEmpty) err(w, 'must be linked to at least one lesson');
      var latest = -1;
      for (final id in d.lessonIds) {
        final i = order[id];
        if (i == null) {
          err(w, 'unknown lesson "$id"');
        } else if (i > latest) {
          latest = i;
        }
      }
      final taught = latest < 0
          ? <String>{}
          : {
              for (final l in pack.orderedLessons.take(latest + 1))
                for (final it in l.items) it.id,
            };
      for (final id in d.items) {
        if (pack.item(id) == null) {
          err(w, 'unknown item "$id"');
        } else if (latest >= 0 && !taught.contains(id)) {
          err(w, 'item "$id" is not taught by its lessons or earlier');
        }
      }
      for (final g in d.grammarIds) {
        if (!grammarIds.contains(g)) err(w, 'unknown grammar reference "$g"');
      }

      // Speakers and turns.
      final speakerIds = <String>{};
      for (final sp in d.speakers) {
        if (!speakerIds.add(sp.id)) err(w, 'duplicate speaker "${sp.id}"');
        if (sp.name.trim().isEmpty || sp.roleAr.trim().isEmpty) {
          err(w, 'speaker "${sp.id}" needs name and role_ar');
        }
      }
      if (d.turns.length < 2) err(w, 'needs at least 2 turns');
      final used = <String>{};
      for (final t in d.turns) {
        final tw = '$w/${t.id}';
        if (!turnIds.add(t.id)) err(tw, 'duplicate turn id');
        if (!speakerIds.contains(t.speaker)) {
          err(tw, 'unknown speaker "${t.speaker}"');
        }
        used.add(t.speaker);
        if (t.es.trim().isEmpty || t.ar.trim().isEmpty) {
          err(tw, 'turn needs es and ar');
        }
        if (_arabic.hasMatch(t.es)) err(tw, 'es contains Arabic script');
        if (!_latin.hasMatch(t.es)) err(tw, 'es has no Latin letters');
        if (t.ar.isNotEmpty && !_arabic.hasMatch(t.ar)) {
          err(tw, 'ar has no Arabic script');
        }
        if (_arabic.hasMatch(t.en)) err(tw, 'en contains Arabic script');
        _checkPunctuation(t.es, tw, err);
      }
      if (used.length < 2) err(w, 'needs at least two speakers who speak');

      // Questions.
      if (d.questions.length < 3) err(w, 'needs at least 3 questions');
      for (final q in d.questions) {
        final qw = '$w/${q.id}';
        if (!questionIds.add(q.id)) err(qw, 'duplicate question id');
        if (!DialogueQuestion.types.contains(q.type)) {
          err(qw, 'unknown question type "${q.type}"');
          continue;
        }
        if (!skills.contains(q.skill)) err(qw, 'invalid skill "${q.skill}"');
        if (q.turnId != null && d.turn(q.turnId!) == null) {
          err(qw, 'unknown turn "${q.turnId}"');
        }
        switch (q.type) {
          case 'choice':
            if (q.promptAr.trim().isEmpty) err(qw, 'choice needs prompt_ar');
            if (q.choices.length < 2) err(qw, 'choice needs ≥ 2 choices');
            if (q.choices.toSet().length != q.choices.length) {
              err(qw, 'choices must be distinct');
            }
            if (q.answer < 0 || q.answer >= q.choices.length) {
              err(qw, 'answer must be a valid index');
            }
          case 'speaker':
          case 'dictation':
            if (q.turnId == null) err(qw, '${q.type} needs "turn"');
        }
      }
    }
  }

  void _checkExample(
    Example e,
    String where,
    void Function(String, String) err,
  ) {
    if (e.es.trim().isEmpty || e.ar.trim().isEmpty) {
      err(where, 'example needs both es and ar');
      return;
    }
    if (_arabic.hasMatch(e.es)) err(where, 'example es contains Arabic script');
    if (!_latin.hasMatch(e.es)) err(where, 'example es has no Latin letters');
    if (!_arabic.hasMatch(e.ar)) err(where, 'example ar has no Arabic script');
    _checkPunctuation(e.es, where, err);
  }

  /// Spanish opens every question/exclamation with ¿ / ¡.
  void _checkPunctuation(
    String es,
    String where,
    void Function(String, String) err,
  ) {
    int count(String ch) => ch.allMatches(es).length;
    if (count('¿') != count('?')) {
      err(where, 'unbalanced ¿ ? in "$es"');
    }
    if (count('¡') != count('!')) {
      err(where, 'unbalanced ¡ ! in "$es"');
    }
  }
}
