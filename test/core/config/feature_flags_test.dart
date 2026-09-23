import 'package:daftary/core/config/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

/// 012 research.md Decision 4 — the flags Home's quick actions read.
///
/// Both started `false` when Home was planned, and each is flipped by the
/// feature that ships the screen behind it. Occasions (008) and OCR Paper
/// Entry (009) have both shipped, so both are now on; if either feature is
/// ever pulled, this test is the reminder to hide its quick action too.
void main() {
  test('"Add occasion" is enabled because Occasions (008) has shipped', () {
    expect(kOccasionsFeatureEnabled, isTrue);
  });

  test('"Scan paper" is enabled because OCR Paper Entry (009) has shipped', () {
    expect(kOcrScanFeatureEnabled, isTrue);
  });
}
