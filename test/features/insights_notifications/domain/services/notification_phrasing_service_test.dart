import 'dart:io';

import 'package:daftary/features/insights_notifications/data/services/template_notification_phrasing_service.dart';
import 'package:daftary/features/insights_notifications/domain/entities/composed_notification.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_source_type.dart';
import 'package:daftary/features/insights_notifications/domain/services/notification_phrasing_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// T016 — [TemplateNotificationPhrasingService] is an identity pass-through,
/// and [NotificationPhrasingService] structurally cannot receive raw
/// candidate data (FR-008, research.md Decision 3).
void main() {
  const draft = ComposedNotification(
    title: 'Food is over budget',
    body: "You've spent 112% of your Food budget this month.",
    deepLinkTarget: NotificationDeepLinkTarget(
      type: NotificationSourceType.budgetCategory,
      id: 'cat-food',
      applicablePeriod: '2026-09',
    ),
  );

  test('compose() returns its input unchanged', () async {
    const NotificationPhrasingService service =
        TemplateNotificationPhrasingService();

    final result = await service.compose(draft);

    expect(result, draft);
    expect(identical(result, draft), isTrue);
  });

  test("compose()'s only parameter is an already-composed "
      'ComposedNotification', () {
    // Compile-time half: this tear-off only type-checks while compose takes
    // exactly one ComposedNotification. Widening it to a candidate type or
    // adding a raw-data parameter breaks this line.
    const service = TemplateNotificationPhrasingService();
    final Future<ComposedNotification> Function(ComposedNotification) compose =
        service.compose;
    expect(compose, isNotNull);

    // Source half: the interface file does not even import the candidate or
    // port types, so no signature in it can mention them.
    final source = File(
      'lib/features/insights_notifications/domain/services/'
      'notification_phrasing_service.dart',
    ).readAsStringSync();
    final code = source
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('///'))
        .join('\n');
    expect(code, isNot(contains('notification_candidate')));
    expect(code, isNot(contains('NotificationCandidate')));
    expect(code, isNot(contains('ports/')));
    expect(code, isNot(contains('Snapshot')));
    expect(
      RegExp(r'compose\(\s*ComposedNotification\s+\w+\s*\)').hasMatch(code),
      isTrue,
    );
  });
}
