import '../content/models.dart';

class PlanItem {
  const PlanItem({
    required this.kind,
    required this.titleAr,
    required this.reasonAr,
    required this.minutes,
    required this.route,
    required this.done,
  });

  /// review | lesson | errors | listening | writing | pronunciation
  final String kind;
  final String titleAr;

  /// Plain-language explanation of WHY this is in today's plan.
  final String reasonAr;
  final int minutes;

  /// Navigation target, or null when nothing can be opened.
  final String? route;
  final bool done;
}

class PlannerInput {
  const PlannerInput({
    required this.dailyMinutes,
    required this.dueCards,
    required this.reviewedToday,
    required this.nextLesson,
    required this.lessonsCompletedToday,
    required this.learnedItems,
    required this.openErrors,
    required this.practiceKindsToday,
  });

  final int dailyMinutes;
  final int dueCards;
  final int reviewedToday;
  final Lesson? nextLesson;
  final int lessonsCompletedToday;
  final int learnedItems;
  final int openErrors;
  final Set<String> practiceKindsToday;
}

/// Transparent, deterministic daily plan. No randomness, no AI: the same
/// inputs always produce the same plan, and every block carries its reason.
///
/// Order encodes the pedagogy: retrieval of old material first, then new
/// learning, then targeted remediation and skill practice.
List<PlanItem> buildDailyPlan(PlannerInput i) {
  final quick = i.dailyMinutes <= 20;
  final intensive = i.dailyMinutes >= 60;
  final items = <PlanItem>[];

  // 1. Spaced repetition always comes first: forgetting does not wait.
  final reviewCap = quick ? 6 : (intensive ? 15 : 12);
  if (i.dueCards > 0) {
    final est = (i.dueCards * 0.4).ceil().clamp(1, reviewCap);
    items.add(
      PlanItem(
        kind: 'review',
        titleAr: 'مراجعة ${i.dueCards} بطاقة',
        reasonAr:
            'حان موعد مراجعتها وفق خوارزمية FSRS؛ تأجيلها يزيد احتمال نسيانها.',
        minutes: est,
        route: '/review',
        done: false,
      ),
    );
  } else if (i.reviewedToday > 0) {
    items.add(
      PlanItem(
        kind: 'review',
        titleAr: 'المراجعة اليومية',
        reasonAr: 'أنهيت كل المراجعات المستحقة اليوم (${i.reviewedToday}).',
        minutes: 0,
        route: null,
        done: true,
      ),
    );
  }

  // 2. New learning, in strict curriculum order.
  final lessonTarget = intensive ? 2 : 1;
  final lesson = i.nextLesson;
  if (i.lessonsCompletedToday >= lessonTarget) {
    items.add(
      PlanItem(
        kind: 'lesson',
        titleAr: 'تعلّم جديد',
        reasonAr:
            'أكملت ${i.lessonsCompletedToday} درساً اليوم — هدف اليوم تحقق.',
        minutes: 0,
        route: null,
        done: true,
      ),
    );
  } else if (lesson != null) {
    items.add(
      PlanItem(
        kind: 'lesson',
        titleAr: 'درس جديد: ${lesson.titleAr}',
        reasonAr: 'الدرس التالي في مسارك بعد إكمال متطلباته السابقة.',
        minutes: lesson.minutes,
        route: '/lesson/${lesson.id}',
        done: false,
      ),
    );
  }

  PlanItem practice(String kind, String title, String reason, int minutes) =>
      PlanItem(
        kind: kind,
        titleAr: title,
        reasonAr: reason,
        minutes: minutes,
        route: '/practice/$kind',
        done: i.practiceKindsToday.contains(kind),
      );

  // 3. Remediation, only when there is evidence of repeated difficulty.
  if (i.openErrors >= 3) {
    items.add(
      practice(
        'errors',
        'تدريب على أخطائك',
        'لديك ${i.openErrors} أخطاء لم تُصحَّح بعد في دفتر الأخطاء.',
        quick ? 3 : 5,
      ),
    );
  }

  // 4. Skill practice over material already learned.
  if (i.learnedItems >= 4) {
    items.add(
      practice(
        'listening',
        'تدريب استماع',
        'لتثبيت تمييز الأصوات في العبارات التي تعلّمتها.',
        quick ? 3 : 6,
      ),
    );
    items.add(
      practice(
        'pronunciation',
        'نطق وترديد',
        'الترديد بصوت مسموع يبني الطلاقة منذ البداية.',
        quick ? 3 : 5,
      ),
    );
    if (!quick) {
      items.add(
        practice(
          'writing',
          'كتابة من الذاكرة',
          'الاستدعاء النشط (الكتابة دون اختيارات) أقوى من التعرّف.',
          intensive ? 8 : 5,
        ),
      );
    }
  }
  return items;
}
