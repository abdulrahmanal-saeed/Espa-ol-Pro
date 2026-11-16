import 'package:espanol_pro/core/db/database.dart';
import 'package:espanol_pro/core/phrases/saved_phrases_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late SavedPhrasesRepository repo;

  setUp(() {
    db = memoryDb();
    clock = FakeClock();
    repo = SavedPhrasesRepository(db, clock: clock.call);
  });
  tearDown(() => db.close());

  PhraseDraft draft(
    String es, {
    String ar = 'ترجمة',
    String kind = 'example',
    String? id = 'casa',
    String? lesson = 'pa1_u1_l1',
  }) => PhraseDraft(
    es: es,
    ar: ar,
    source: PhraseSource(kind: kind, id: id, lessonId: lesson),
  );

  test('saves a phrase with its source and date', () async {
    expect(
      await repo.save(draft('Mi casa es tu casa.', ar: 'بيتي بيتك.')),
      isTrue,
    );
    final p = (await repo.all()).single;
    expect(p.es, 'Mi casa es tu casa.');
    expect(p.ar, 'بيتي بيتك.');
    expect(p.sourceKind, 'example');
    expect(p.sourceId, 'casa');
    expect(p.sourceLessonId, 'pa1_u1_l1');
    expect(p.savedAt, clock.now.millisecondsSinceEpoch);
    expect(p.note, '');
  });

  test('the same sentence saved twice is one record, the first kept', () async {
    await repo.save(draft('Hola, María.', kind: 'example'));
    clock.advance(const Duration(days: 2));
    // Different case, spacing and punctuation, different screen.
    expect(await repo.save(draft('  hola maría ', kind: 'grammar')), isFalse);
    final p = (await repo.all()).single;
    expect(p.es, 'Hola, María.');
    expect(p.sourceKind, 'example');
  });

  test(
    'the same text from two lessons keeps the first source and note',
    () async {
      await repo.save(draft('Hasta mañana.', lesson: 'pa1_u2_l1'));
      final first = (await repo.all()).single;
      await repo.updateNote(first.id, 'وداع الزميل');
      clock.advance(const Duration(days: 30));
      expect(
        await repo.save(
          draft('Hasta mañana.', lesson: 'a1_u1_l3', kind: 'vocab'),
        ),
        isFalse,
      );
      final kept = (await repo.all()).single;
      expect(kept.sourceLessonId, 'pa1_u2_l1');
      expect(kept.sourceKind, 'example');
      expect(kept.note, 'وداع الزميل');
      expect(kept.savedAt, first.savedAt);
    },
  );

  test('accents and ñ make a different phrase', () {
    expect(
      SavedPhrasesRepository.keyFor('¿Qué es?'),
      isNot(SavedPhrasesRepository.keyFor('Que es')),
    );
    expect(
      SavedPhrasesRepository.keyFor('año'),
      isNot(SavedPhrasesRepository.keyFor('ano')),
    );
    expect(
      SavedPhrasesRepository.keyFor('¿Cómo estás?'),
      SavedPhrasesRepository.keyFor('cómo   ESTÁS'),
    );
  });

  test('identity does not depend on content ids', () async {
    await repo.save(draft('Buenos días.', id: 'buenos_dias'));
    // A later curriculum version renames the item: still the same phrase.
    expect(
      await repo.save(draft('Buenos días.', id: 'greeting_morning')),
      isFalse,
    );
    expect((await repo.all()).length, 1);
  });

  test('toggle saves, then removes', () async {
    final d = draft('Gracias.');
    expect(await repo.toggle(d), isTrue);
    expect((await repo.all()).length, 1);
    expect(await repo.toggle(d), isFalse);
    expect(await repo.all(), isEmpty);
  });

  test('notes are stored trimmed; restore brings back the exact row', () async {
    await repo.save(draft('De nada.'));
    final p = (await repo.all()).single;
    await repo.updateNote(p.id, '  رد على الشكر  ');
    final withNote = (await repo.all()).single;
    expect(withNote.note, 'رد على الشكر');
    await repo.remove('de nada');
    expect(await repo.all(), isEmpty);
    await repo.restore(withNote);
    expect((await repo.all()).single.toJson(), withNote.toJson());
  });

  test('empty text is refused', () async {
    expect(() => repo.save(draft('   ')), throwsArgumentError);
    expect(await repo.all(), isEmpty);
  });

  test(
    'search ignores accents and case, and covers Arabic and notes',
    () async {
      await repo.save(draft('¿Cómo estás?', ar: 'كيف حالك؟'));
      await repo.save(draft('Trabajo en ventas.', ar: 'أعمل في المبيعات.'));
      final rows = await repo.all();
      await repo.updateNote(
        rows.firstWhere((r) => r.es.startsWith('Trabajo')).id,
        'للمقابلة',
      );
      final all = await repo.all();
      List<String> find(String q) =>
          SavedPhrasesRepository.search(all, q).map((r) => r.es).toList();
      expect(find('como'), ['¿Cómo estás?']);
      expect(find('VENTAS'), ['Trabajo en ventas.']);
      expect(find('حالك'), ['¿Cómo estás?']);
      expect(find('مقابلة'), ['Trabajo en ventas.']);
      expect(find(''), hasLength(2));
      expect(find('xyz'), isEmpty);
    },
  );
}
