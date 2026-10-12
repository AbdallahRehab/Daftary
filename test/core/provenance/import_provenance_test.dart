import 'package:daftary/core/provenance/import_provenance.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023 T020: `ImportProvenance.fromWire` (data-model §2.8).
void main() {
  group('ImportProvenance.fromWire', () {
    test("'sms' maps to sms", () {
      final provenance = ImportProvenance.fromWire('sms');
      expect(provenance, ImportProvenance.sms);
      expect(provenance!.isSms, isTrue);
      expect(provenance.kind, ImportProvenanceKind.sms);
      expect(provenance.wire, 'sms');
    });

    test('null maps to null (not imported, FR-057)', () {
      expect(ImportProvenance.fromWire(null), isNull);
    });

    for (final other in ['email', 'SMS', '', ' sms', 'bank_api']) {
      test("'$other' maps to unknown and keeps its string", () {
        final provenance = ImportProvenance.fromWire(other);
        expect(provenance, isNotNull);
        expect(provenance!.isUnknown, isTrue);
        expect(provenance.isSms, isFalse);
        expect(provenance.wire, other);
      });
    }

    test('an unknown value round-trips losslessly', () {
      final first = ImportProvenance.fromWire('future_source')!;
      final second = ImportProvenance.fromWire(first.wire);
      expect(second, first);
      expect(second!.wire, 'future_source');
    });

    test('equality uses the original string', () {
      expect(
        ImportProvenance.fromWire('a'),
        isNot(ImportProvenance.fromWire('b')),
      );
      expect(ImportProvenance.fromWire('a'), ImportProvenance.fromWire('a'));
      expect(ImportProvenance.fromWire('x'), isNot(ImportProvenance.sms));
    });
  });
}
