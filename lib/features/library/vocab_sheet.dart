import 'package:material_ui/material_ui.dart';

import '../../core/content/models.dart';
import '../lesson/exercise_widgets.dart';

Future<void> showVocabSheet(BuildContext context, VocabItem item) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: VocabDetail(item),
        ),
      ),
    );
