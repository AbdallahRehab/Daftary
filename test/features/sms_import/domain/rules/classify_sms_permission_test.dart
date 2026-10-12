import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/rules/classify_sms_permission.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023 T029: the permission classifier table (research Decision 2,
/// sms-platform-channel §2.3). Written before the implementation.
void main() {
  SmsPermissionResult result({
    required bool granted,
    required bool dialogShown,
    required bool shouldShowRationale,
    int sdkInt = 34,
    SmsInstallSource installSource = SmsInstallSource.store,
  }) => SmsPermissionResult(
    granted: granted,
    shouldShowRationale: shouldShowRationale,
    dialogShown: dialogShown,
    sdkInt: sdkInt,
    installSource: installSource,
  );

  /// The expected status for one combination, written out from the rule
  /// table rather than computed by the code under test.
  SmsPermissionStatus expected({
    required bool granted,
    required bool dialogShown,
    required bool shouldShowRationale,
    required bool previouslyRequested,
    required int sdkInt,
    required SmsInstallSource installSource,
  }) {
    if (granted) return SmsPermissionStatus.granted;
    if (!dialogShown &&
        sdkInt >= 35 &&
        installSource != SmsInstallSource.store) {
      return SmsPermissionStatus.restrictedBlocked;
    }
    if (!shouldShowRationale && previouslyRequested) {
      return SmsPermissionStatus.permanentlyDenied;
    }
    return SmsPermissionStatus.denied;
  }

  const bools = [false, true];

  group('every {granted, dialogShown, shouldShowRationale, '
      'previouslyRequested} combination', () {
    for (final sdkInt in [33, 34, 35, 36]) {
      for (final installSource in SmsInstallSource.values) {
        for (final granted in bools) {
          for (final dialogShown in bools) {
            for (final rationale in bools) {
              for (final previouslyRequested in bools) {
                final want = expected(
                  granted: granted,
                  dialogShown: dialogShown,
                  shouldShowRationale: rationale,
                  previouslyRequested: previouslyRequested,
                  sdkInt: sdkInt,
                  installSource: installSource,
                );
                test('sdk $sdkInt, ${installSource.name}, granted=$granted, '
                    'dialog=$dialogShown, rationale=$rationale, '
                    'requested=$previouslyRequested -> ${want.name}', () {
                  expect(
                    classifySmsPermission(
                      result(
                        granted: granted,
                        dialogShown: dialogShown,
                        shouldShowRationale: rationale,
                        sdkInt: sdkInt,
                        installSource: installSource,
                      ),
                      previouslyRequested: previouslyRequested,
                    ),
                    want,
                  );
                });
              }
            }
          }
        }
      }
    }
  });

  group('named cases', () {
    test('granted always wins', () {
      expect(
        classifySmsPermission(
          result(
            granted: true,
            dialogShown: false,
            shouldShowRationale: false,
            sdkInt: 35,
            installSource: SmsInstallSource.notStore,
          ),
          previouslyRequested: true,
          previouslyGranted: true,
        ),
        SmsPermissionStatus.granted,
      );
    });

    test('Android 15 sideload with no dialog is restricted settings', () {
      expect(
        classifySmsPermission(
          result(
            granted: false,
            dialogShown: false,
            shouldShowRationale: false,
            sdkInt: 35,
            installSource: SmsInstallSource.notStore,
          ),
          previouslyRequested: false,
        ),
        SmsPermissionStatus.restrictedBlocked,
      );
    });

    test('an unknown install source on Android 15 is not a store', () {
      expect(
        classifySmsPermission(
          result(
            granted: false,
            dialogShown: false,
            shouldShowRationale: false,
            sdkInt: 35,
            installSource: SmsInstallSource.unknown,
          ),
          previouslyRequested: false,
        ),
        SmsPermissionStatus.restrictedBlocked,
      );
    });

    test('a store install on Android 15 with no dialog is permanently '
        'denied after an earlier request', () {
      expect(
        classifySmsPermission(
          result(
            granted: false,
            dialogShown: false,
            shouldShowRationale: false,
            sdkInt: 35,
          ),
          previouslyRequested: true,
        ),
        SmsPermissionStatus.permanentlyDenied,
      );
    });

    test('a first denial can be asked again once', () {
      expect(
        classifySmsPermission(
          result(granted: false, dialogShown: true, shouldShowRationale: true),
          previouslyRequested: true,
        ),
        SmsPermissionStatus.denied,
      );
    });
  });

  group('revoked (a prior grant is now off)', () {
    for (final dialogShown in bools) {
      for (final rationale in bools) {
        for (final previouslyRequested in bools) {
          test('dialog=$dialogShown, rationale=$rationale, '
              'requested=$previouslyRequested -> revoked', () {
            expect(
              classifySmsPermission(
                result(
                  granted: false,
                  dialogShown: dialogShown,
                  shouldShowRationale: rationale,
                  sdkInt: 35,
                  installSource: SmsInstallSource.notStore,
                ),
                previouslyRequested: previouslyRequested,
                previouslyGranted: true,
              ),
              SmsPermissionStatus.revoked,
            );
          });
        }
      }
    }
  });
}
