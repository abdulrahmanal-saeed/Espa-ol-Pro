import 'package:drift/drift.dart';

import '../db/database.dart';
import '../learning/answer_evaluator.dart';
import '../srs/review_repository.dart';

/// Where a phrase was saved from.
class PhraseSource {
  const PhraseSource({required this.kind, this.id, this.lessonId});

  /// vocab | example | grammar | lesson_note | dialogue
  final String kind;
  final String? id;
  final String? lessonId;

  static const kinds = {
    'vocab',
    'example',
    'grammar',
    'lesson_note',
    'dialogue',
  };
}

/// A phrase that can be saved: what the screen shows plus where it came from.
class PhraseDraft {
  const PhraseDraft({
    required this.es,
    required this.ar,
    this.en = '',
    required this.source,
  });

  final String es;
  final String ar;
  final String en;
  final PhraseSource source;

  String get key => SavedPhrasesRepository.keyFor(es);
}

class SavedPhrasesRepository {
  SavedPhrasesRepository(this.db, {required this.clock});

  final AppDatabase db;
  final Clock clock;

  /// Stable identity: case, punctuation and spacing are ignored; accents and
  /// ñ are kept, because they change meaning.
  static String keyFor(String es) => normalizeAnswer(es);

  Stream<List<SavedPhrase>> watchAll() => (db.select(
    db.savedPhrases,
  )..orderBy([(t) => OrderingTerm.desc(t.savedAt)])).watch();

  Stream<Set<String>> watchKeys() =>
      watchAll().map((rows) => {for (final r in rows) r.phraseKey});

  Future<List<SavedPhrase>> all() => db.select(db.savedPhrases).get();

  /// Saves [draft] once. Saving the same sentence again keeps the original
  /// record (its date, source and note) and returns false.
  Future<bool> save(PhraseDraft draft) async {
    final es = draft.es.trim();
    if (es.isEmpty) throw ArgumentError('A phrase needs Spanish text.');
    // `insert` returns a row id even when the row was ignored, so it cannot
    // tell a duplicate apart; `insertReturningOrNull` returns null for that.
    final row = await db
        .into(db.savedPhrases)
        .insertReturningOrNull(
          SavedPhrasesCompanion.insert(
            phraseKey: keyFor(es),
            es: es,
            ar: draft.ar.trim(),
            en: Value(draft.en.trim()),
            sourceKind: draft.source.kind,
            sourceId: Value(draft.source.id),
            sourceLessonId: Value(draft.source.lessonId),
            savedAt: clock().toUtc().millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return row != null;
  }

  Future<void> remove(String es) => (db.delete(
    db.savedPhrases,
  )..where((t) => t.phraseKey.equals(keyFor(es)))).go();

  /// Saves if absent, removes if present. Returns true when now saved.
  Future<bool> toggle(PhraseDraft draft) async {
    final existing = await (db.select(
      db.savedPhrases,
    )..where((t) => t.phraseKey.equals(draft.key))).getSingleOrNull();
    if (existing != null) {
      await remove(draft.es);
      return false;
    }
    await save(draft);
    return true;
  }

  /// Puts back a removed phrase exactly as it was (undo).
  Future<void> restore(SavedPhrase phrase) => db
      .into(db.savedPhrases)
      .insert(phrase.toCompanion(false), mode: InsertMode.insertOrIgnore);

  Future<void> updateNote(int id, String note) =>
      (db.update(db.savedPhrases)..where((t) => t.id.equals(id))).write(
        SavedPhrasesCompanion(note: Value(note.trim())),
      );

  /// Accent-insensitive search over Spanish, Arabic, English and the note.
  static List<SavedPhrase> search(List<SavedPhrase> rows, String query) {
    final q = query.trim();
    if (q.isEmpty) return rows;
    final latin = stripAccents(normalizeAnswer(q));
    return rows.where((r) {
      return stripAccents(normalizeAnswer(r.es)).contains(latin) ||
          stripAccents(normalizeAnswer(r.en)).contains(latin) ||
          r.ar.contains(q) ||
          r.note.toLowerCase().contains(q.toLowerCase());
    }).toList();
  }
}
