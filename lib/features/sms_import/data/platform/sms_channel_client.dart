import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sms_import_failures.dart';
import '../../domain/entities/sms_permission_status.dart';

/// The `PlatformException.code` values of the SMS plugin
/// (sms-platform-channel §3), plus [unknown] for anything else.
enum SmsChannelErrorCode {
  unavailable('unavailable'),
  permissionDenied('permission_denied'),
  queryFailed('query_failed'),
  invalidArgs('invalid_args'),
  noActivity('no_activity'),
  requestInProgress('request_in_progress'),

  /// The plugin is not registered (iOS, macOS, a widget test).
  missingPlugin('missing_plugin'),

  /// A reply of the wrong shape.
  malformedReply('malformed_reply'),
  unknown('unknown');

  const SmsChannelErrorCode(this.wire);

  final String wire;

  static SmsChannelErrorCode fromWire(String code) {
    for (final value in values) {
      if (value.wire == code) return value;
    }
    return unknown;
  }

  /// The typed failure of sms-platform-channel §3. Fixed tokens only.
  Failure get failure => switch (this) {
    unavailable || missingPlugin => const SmsCapabilityUnavailableFailure(),
    permissionDenied ||
    noActivity ||
    requestInProgress => const SmsPermissionFailure(SmsPermissionStatus.denied),
    queryFailed || invalidArgs => const SmsInboxQueryFailure(),
    malformedReply || unknown => const UnknownFailure('sms_channel_failed'),
  };
}

/// The two SMS platform channels (sms-platform-channel §1). Thin: it shapes
/// arguments, invokes, and maps every `PlatformException` and
/// `MissingPluginException` to a code-only [SmsChannelErrorCode] failure.
/// It never logs, and no failure carries an exception message, a sender,
/// an address or a body (§3).
///
/// Registered on every platform; constructing it touches nothing. On iOS
/// and macOS nothing calls it (`SmsPlatformModule` selects the
/// `Unavailable*` adapters there).
@lazySingleton
class SmsChannelClient {
  SmsChannelClient({
    @ignoreParam MethodChannel? methodChannel,
    @ignoreParam EventChannel? eventChannel,
  }) : _methods = methodChannel ?? const MethodChannel(methodChannelName),
       _events = eventChannel ?? const EventChannel(eventChannelName);

  static const String methodChannelName = 'com.daftary.daftary/sms';
  static const String eventChannelName = 'com.daftary.daftary/sms/shared_text';

  final MethodChannel _methods;
  final EventChannel _events;

  /// `{readSmsDeclared, sdkInt, isStoreInstall?}` (§2.1).
  Future<Either<Failure, Map<String, Object?>>> getCapabilities() =>
      _invokeMap('getCapabilities');

  /// `{granted, shouldShowRationale}` (§2.2). Never prompts.
  Future<Either<Failure, Map<String, Object?>>> getPermissionState() =>
      _invokeMap('getPermissionState');

  /// `{granted, shouldShowRationale, dialogShown, sdkInt, installSource}`
  /// (§2.3). Prompts at most once.
  Future<Either<Failure, Map<String, Object?>>> requestPermission() =>
      _invokeMap('requestPermission');

  /// One keyset page (§2.4): `[{id, address, date, body, truncated}]`.
  Future<Either<Failure, List<Map<String, Object?>>>> queryInbox({
    required List<String> senders,
    required int afterDate,
    int? afterId,
    required int limit,
  }) async {
    final reply = await _invoke<List<Object?>>('queryInbox', {
      'senders': senders,
      'afterDate': afterDate,
      'afterId': afterId,
      'limit': limit,
    });
    return reply.flatMap((list) {
      final rows = <Map<String, Object?>>[];
      for (final row in list ?? const <Object?>[]) {
        if (row is! Map) {
          return Left(SmsChannelErrorCode.malformedReply.failure);
        }
        rows.add(row.cast<String, Object?>());
      }
      return Right(rows);
    });
  }

  /// `{text, truncated}` or `null` (§2.5). Returned once by the platform.
  Future<Either<Failure, Map<String, Object?>?>> getInitialSharedText() async {
    final reply = await _invoke<Map<Object?, Object?>>('getInitialSharedText');
    return reply.map((map) => map?.cast<String, Object?>());
  }

  /// Warm shares (§2.6), `{text, truncated}` each. Malformed events and
  /// stream errors are dropped, never logged.
  Stream<Map<String, Object?>> sharedTextEvents() => _events
      .receiveBroadcastStream()
      .handleError((Object _) {})
      .where((event) => event is Map)
      .map((event) => (event as Map).cast<String, Object?>());

  Future<Either<Failure, Map<String, Object?>>> _invokeMap(
    String method,
  ) async {
    final reply = await _invoke<Map<Object?, Object?>>(method);
    return reply.flatMap(
      (map) => map == null
          ? Left(SmsChannelErrorCode.malformedReply.failure)
          : Right(map.cast<String, Object?>()),
    );
  }

  Future<Either<Failure, T?>> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return Right(await _methods.invokeMethod<T>(method, arguments));
    } on PlatformException catch (e) {
      // Only the code is read; message and details are never touched.
      return Left(SmsChannelErrorCode.fromWire(e.code).failure);
    } on MissingPluginException {
      return Left(SmsChannelErrorCode.missingPlugin.failure);
    } on TypeError {
      return Left(SmsChannelErrorCode.malformedReply.failure);
    }
  }
}
