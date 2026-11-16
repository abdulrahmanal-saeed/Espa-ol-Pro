import 'package:material_ui/material_ui.dart';

/// The AI tutor is NOT implemented in Phase 1. This screen says so plainly
/// instead of faking a conversation.
class TutorScreen extends StatelessWidget {
  const TutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget bullet(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: t.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(child: Text(s, style: const TextStyle(height: 1.6))),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('المعلّم الذكي')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.construction_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'هذه الميزة غير مفعّلة في الإصدار الحالي.',
                    style: t.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'المعلّم الذكي مخطط للمرحلة الثانية، ويتطلب خادماً وسيطاً آمناً ومفتاح خدمة ذكاء اصطناعي لا يُخزَّن داخل التطبيق. حتى ذلك الحين لا يرسل التطبيق أي بيانات إلى أي خدمة خارجية.',
            style: t.textTheme.bodyLarge!.copyWith(height: 1.8),
          ),
          const SizedBox(height: 20),
          Text(
            'ما سيقدّمه عند تفعيله',
            style: t.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          bullet('محادثة نصية بالإسبانية بمستواك الحالي مع شرح بالعربية.'),
          bullet('تمثيل أدوار مهنية: عميل، مدير مشتريات، مسؤول توظيف.'),
          bullet('تصحيح كتابتك وتسجيل الأخطاء في دفتر أخطائك.'),
          bullet('حدّ يومي وشهري للتكلفة تتحكم به من الإعدادات.'),
          const SizedBox(height: 12),
          Text(
            'كل ما عدا ذلك — الدروس، المراجعة، التدريب، التقدّم — يعمل كاملاً دون اتصال.',
            style: t.textTheme.bodyMedium!.copyWith(
              color: t.colorScheme.onSurfaceVariant,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
