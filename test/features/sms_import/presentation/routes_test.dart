import 'package:daftary/features/sms_import/presentation/routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// T068 — the paths of ui-contract §1.
void main() {
  test('paths match the UI contract', () {
    expect(BankMessagesRoutes.hub, '/bank-messages');
    expect(BankMessagesRoutes.enable, '/bank-messages/enable');
    expect(BankMessagesRoutes.paste, '/bank-messages/paste');
    expect(BankMessagesRoutes.ignored, '/bank-messages/ignored');
    expect(BankMessagesRoutes.senders, '/bank-messages/senders');
    expect(BankMessagesRoutes.learned, '/bank-messages/learned');
    expect(BankMessagesRoutes.reviewPattern, '/bank-messages/review/:importId');
    expect(BankMessagesRoutes.settings, '/settings/bank-messages');
  });

  test('review carries only the id, encoded', () {
    expect(
      BankMessagesRoutes.review('0b7c4a52-2f4e-4c1a-9a51-3f0f0c9d8e11'),
      '/bank-messages/review/0b7c4a52-2f4e-4c1a-9a51-3f0f0c9d8e11',
    );
    expect(BankMessagesRoutes.review('a/b'), '/bank-messages/review/a%2Fb');
  });

  test('no static path can be captured as a review id', () {
    for (final path in [
      BankMessagesRoutes.enable,
      BankMessagesRoutes.paste,
      BankMessagesRoutes.ignored,
      BankMessagesRoutes.senders,
      BankMessagesRoutes.learned,
    ]) {
      expect(path.startsWith('/bank-messages/review/'), isFalse, reason: path);
    }
  });
}
