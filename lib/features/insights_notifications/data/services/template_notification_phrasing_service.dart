import 'package:injectable/injectable.dart';

import '../../domain/entities/composed_notification.dart';
import '../../domain/services/notification_phrasing_service.dart';

/// The only shipped [NotificationPhrasingService]: an identity pass-through.
/// The real wording already happened in the `gen_l10n` templates
/// (`NotificationComposer`, FR-007) before this is called.
@LazySingleton(as: NotificationPhrasingService)
class TemplateNotificationPhrasingService
    implements NotificationPhrasingService {
  const TemplateNotificationPhrasingService();

  @override
  Future<ComposedNotification> compose(ComposedNotification draft) async =>
      draft;
}
