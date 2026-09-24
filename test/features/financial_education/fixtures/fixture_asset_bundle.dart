import 'dart:io';

import 'package:daftary/features/financial_education/data/datasources/bundled_education_content_data_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serves the feature's bundled-content asset paths from the small,
/// deterministic fixture tree beside this file instead of the real content,
/// so repository tests never depend on the authored articles.
class FixtureAssetBundle extends CachingAssetBundle {
  FixtureAssetBundle();

  static const String _fixtureRoot =
      'test/features/financial_education/fixtures/content';

  /// Every asset path requested, in order — lets a test prove caching and
  /// language fallback without inspecting internals.
  final List<String> requestedKeys = [];

  @override
  Future<ByteData> load(String key) async {
    requestedKeys.add(key);
    const prefix = '${BundledEducationContentDataSource.contentRoot}/';
    if (!key.startsWith(prefix)) {
      throw FlutterError('Unable to load asset: "$key".');
    }
    final file = File('$_fixtureRoot/${key.substring(prefix.length)}');
    if (!file.existsSync()) {
      throw FlutterError('Unable to load asset: "$key".');
    }
    final bytes = await file.readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
