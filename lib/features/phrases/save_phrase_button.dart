import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/phrases/saved_phrases_repository.dart';
import '../../core/providers.dart';

/// Bookmark toggle for any Spanish sentence shown in the app.
class SavePhraseButton extends ConsumerWidget {
  const SavePhraseButton(this.draft, {super.key});
  final PhraseDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedPhraseKeysProvider).contains(draft.key);
    return IconButton(
      key: ValueKey('save-phrase-${draft.key}'),
      tooltip: saved ? 'إزالة من عباراتي' : 'احفظ في عباراتي',
      isSelected: saved,
      icon: const Icon(Icons.bookmark_add_outlined),
      selectedIcon: Icon(
        Icons.bookmark_rounded,
        color: Theme.of(context).colorScheme.tertiary,
      ),
      onPressed: () async {
        final messenger = ScaffoldMessenger.maybeOf(context);
        try {
          final now = await ref
              .read(savedPhrasesRepositoryProvider)
              .toggle(draft);
          messenger
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                content: Text(
                  now ? 'حُفظت في «عباراتي».' : 'أُزيلت من «عباراتي».',
                ),
              ),
            );
        } catch (e) {
          messenger?.showSnackBar(
            SnackBar(content: Text('تعذّر حفظ العبارة: $e')),
          );
        }
      },
    );
  }
}
