import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/db/database.dart';
import '../../core/phrases/saved_phrases_repository.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';

const _sourceLabels = {
  'vocab': 'مفردة',
  'example': 'جملة مثال',
  'grammar': 'مرجع القواعد',
  'lesson_note': 'شرح في درس',
};

String _date(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  return '${d.year}/${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}';
}

/// «عباراتي»: the learner's saved sentences.
class SavedPhrasesView extends ConsumerStatefulWidget {
  const SavedPhrasesView({super.key});

  @override
  ConsumerState<SavedPhrasesView> createState() => _SavedPhrasesViewState();
}

class _SavedPhrasesViewState extends ConsumerState<SavedPhrasesView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AsyncView(
      value: ref.watch(savedPhrasesProvider),
      builder: (rows) {
        if (rows.isEmpty) {
          return const EmptyState(
            icon: Icons.bookmarks_outlined,
            title: 'لم تحفظ أي عبارة بعد',
            message: 'اضغط علامة الحفظ بجانب أي جملة أو مفردة في الدروس أو القاموس أو مرجع القواعد، فتظهر هنا مع صوتها ومصدرها.',
          );
        }
        final shown = SavedPhrasesRepository.search(rows, _query);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                key: const ValueKey('phrase-search'),
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'ابحث في عباراتك أو ملاحظاتك',
                  isDense: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  '${shown.length} من ${rows.length}',
                  style: t.textTheme.labelMedium,
                ),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'لا نتائج',
                      message: 'جرّب كلمة أخرى.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _PhraseCard(shown[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PhraseCard extends ConsumerWidget {
  const _PhraseCard(this.p);
  final SavedPhrase p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final showEn = ref.watch(settingsProvider.select((s) => s.showEnglish));
    final lesson = p.sourceLessonId == null
        ? null
        : ref.watch(contentProvider).lesson(p.sourceLessonId!);
    final repo = ref.read(savedPhrasesRepositoryProvider);
    final muted = t.textTheme.bodySmall!.copyWith(
      color: t.colorScheme.onSurfaceVariant,
    );
    return Card(
      key: ValueKey('phrase-${p.phraseKey}'),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: EsText(p.es, size: 18, weight: FontWeight.w600),
                ),
                SpeakButton(p.es),
              ],
            ),
            Text(p.ar, style: t.textTheme.bodyLarge),
            if (showEn && p.en.isNotEmpty)
              EsText(p.en, size: 14, color: t.colorScheme.onSurfaceVariant),
            if (p.note.isNotEmpty)
              Container(
                margin: const EdgeInsetsDirectional.only(top: 8, end: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(p.note, style: const TextStyle(height: 1.5)),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      _sourceLabels[p.sourceKind] ?? p.sourceKind,
                      ?lesson?.titleAr,
                      _date(p.savedAt),
                    ].join(' · '),
                    style: muted,
                  ),
                ),
                IconButton(
                  key: ValueKey('phrase-note-${p.phraseKey}'),
                  tooltip: p.note.isEmpty ? 'أضف ملاحظة' : 'عدّل الملاحظة',
                  icon: const Icon(Icons.edit_note_rounded),
                  onPressed: () async {
                    final note = await _editNote(context, p.note);
                    if (note != null) await repo.updateNote(p.id, note);
                  },
                ),
                IconButton(
                  key: ValueKey('phrase-remove-${p.phraseKey}'),
                  tooltip: 'إزالة من عباراتي',
                  icon: const Icon(Icons.bookmark_remove_outlined),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await repo.remove(p.es);
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: const Text('أُزيلت العبارة.'),
                          action: SnackBarAction(
                            label: 'تراجع',
                            onPressed: () => repo.restore(p),
                          ),
                        ),
                      );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _editNote(BuildContext context, String current) =>
      showDialog<String>(
        context: context,
        builder: (_) => _NoteDialog(initial: current),
      );
}

/// Owns its text controller, so the controller lives exactly as long as the
/// dialog (including its closing animation).
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initial});
  final String initial;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('ملاحظتك'),
    content: TextField(
      key: const ValueKey('phrase-note-field'),
      controller: _controller,
      autofocus: true,
      maxLines: 4,
      minLines: 2,
      maxLength: 500,
      decoration: const InputDecoration(
        hintText: 'متى تستعملها؟ ما الذي يذكّرك بها؟',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      TextButton(
        key: const ValueKey('phrase-note-save'),
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('حفظ'),
      ),
    ],
  );
}
