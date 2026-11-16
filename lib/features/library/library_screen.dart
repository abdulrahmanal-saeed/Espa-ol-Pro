import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/content/models.dart';
import '../../core/db/database.dart';
import '../../core/learning/answer_evaluator.dart';
import '../../core/learning/progress_repository.dart';
import '../../core/providers.dart';
import '../../core/srs/review_repository.dart';
import '../../core/widgets/common.dart';
import '../../core/phrases/saved_phrases_repository.dart';
import '../lesson/exercise_widgets.dart';
import '../phrases/saved_phrases_view.dart';
import '../practice/practice_screen.dart';
import 'vocab_sheet.dart';

const errorCategoryLabels = {
  'vocabulary': 'مفردات',
  'spelling': 'إملاء / كتابة',
  'word_order': 'ترتيب الكلمات',
  'listening': 'استماع',
  'grammar': 'قواعد',
  'meaning': 'فهم المعنى',
  'communication': 'تواصل في موقف',
};

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('المكتبة'),
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'قاموسي'),
            Tab(text: 'عباراتي'),
            Tab(text: 'القواعد'),
            Tab(text: 'دفتر الأخطاء'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _Dictionary(),
          SavedPhrasesView(),
          _Grammar(),
          _ErrorNotebook(),
        ],
      ),
    ),
  );
}

class _Dictionary extends ConsumerStatefulWidget {
  const _Dictionary();

  @override
  ConsumerState<_Dictionary> createState() => _DictionaryState();
}

class _DictionaryState extends ConsumerState<_Dictionary> {
  String _query = '';
  bool _workOnly = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final learned = learnedItems(ref);
    final cards = ref.watch(cardsProvider).value ?? const <ReviewCard>[];
    final byItem = {
      for (final c in cards)
        if (c.cardType == cardRecognition) c.itemId: c,
    };
    if (learned.isEmpty) {
      return const EmptyState(
        icon: Icons.translate_rounded,
        title: 'قاموسك فارغ',
        message: 'كل عبارة تتعلّمها في الدروس تُضاف هنا تلقائياً مع أمثلتها.',
      );
    }
    final q = stripAccents(normalizeAnswer(_query));
    final items = learned.where((i) {
      if (_workOnly && !i.work) return false;
      if (q.isEmpty) return true;
      return stripAccents(normalizeAnswer(i.es)).contains(q) ||
          i.ar.contains(_query.trim());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'ابحث بالإسبانية أو العربية',
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('إسبانية العمل فقط'),
                selected: _workOnly,
                onSelected: (v) => setState(() => _workOnly = v),
              ),
              const Spacer(),
              Text('${items.length} عبارة', style: t.textTheme.labelMedium),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'لا نتائج',
                  message: 'جرّب كلمة أخرى أو ألغِ التصفية.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final card = byItem[item.id];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        onTap: () => showVocabSheet(context, item),
                        title: EsText(item.es, weight: FontWeight.w600),
                        subtitle: Text(item.ar),
                        leading: SpeakButton(item.es),
                        trailing: card == null ? null : _StateChip(card),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip(this.card);
  final ReviewCard card;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final (label, color) = card.reps == 0
        ? ('جديدة', t.colorScheme.outline)
        : switch (card.state) {
            2 => ('في المراجعة', AppColors.of(context).success),
            3 => ('إعادة تعلّم', t.colorScheme.error),
            _ => ('قيد التعلّم', AppColors.of(context).warning),
          };
    return Text(
      label,
      style: t.textTheme.labelSmall!.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Grammar extends ConsumerWidget {
  const _Grammar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    final units = [
      for (final l in pack.levels)
        for (final u in l.units)
          if (u.grammar.isNotEmpty) (l, u),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final (level, unit) in units) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              '${level.code} · ${unit.titleAr}',
              style: t.textTheme.labelLarge!.copyWith(
                color: t.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final GrammarNote g in unit.grammar)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: t.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      g.titleAr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        g.bodyAr,
                        style: t.textTheme.bodyLarge!.copyWith(height: 1.8),
                      ),
                      const SizedBox(height: 12),
                      for (final e in g.examples)
                        ExampleTile(
                          e,
                          source: PhraseSource(kind: 'grammar', id: g.id),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ErrorNotebook extends ConsumerWidget {
  const _ErrorNotebook();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    return AsyncView(
      value: ref.watch(errorsProvider),
      builder: (errors) {
        if (errors.isEmpty) {
          return const EmptyState(
            icon: Icons.fact_check_outlined,
            title: 'لا أخطاء مسجّلة',
            message: 'عندما تخطئ في تمرين يُسجَّل هنا: ما كتبته، والصواب، ونوع الخطأ، وعدد مرات تكراره.',
          );
        }
        final open = errors.where(ProgressRepository.isOpenError).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              '$open خطأ مفتوح · ${errors.length - open} تم تثبيته\n'
              'يُعدّ الخطأ «مثبّتاً» بعد إجابتين صحيحتين متتاليتين على السؤال نفسه.',
              style: t.textTheme.bodySmall!.copyWith(
                color: t.colorScheme.onSurfaceVariant,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 10),
            for (final e in errors) _ErrorCard(e),
          ],
        );
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard(this.e);
  final ErrorRecord e;

  static final _arabic = RegExp(r'[؀-ۿ]');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final open = ProgressRepository.isOpenError(e);
    final okColor = AppColors.of(context).success;
    Widget line(String text, {required bool wrong}) {
      final color = wrong ? t.colorScheme.error : okColor;
      final style = TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        decoration: wrong ? TextDecoration.lineThrough : null,
      );
      return _arabic.hasMatch(text)
          ? Text(text, style: style)
          : EsText(text, style: t.textTheme.bodyLarge!.merge(style));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(errorCategoryLabels[e.category] ?? e.category),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Text('× ${e.count}', style: t.textTheme.labelLarge),
                  const Spacer(),
                  Text(
                    open ? 'مفتوح' : 'تم تثبيته',
                    style: t.textTheme.labelMedium!.copyWith(
                      color: open ? AppColors.of(context).warning : okColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (e.promptAr.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  e.promptAr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.bodySmall!.copyWith(
                    color: t.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              line(e.incorrect, wrong: true),
              const SizedBox(height: 4),
              line(e.correct, wrong: false),
            ],
          ),
        ),
      ),
    );
  }
}
