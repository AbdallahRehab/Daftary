import 'dart:convert';
import 'dart:io';

// 023 T052: loads the synthetic SMS corpus under test/fixtures/sms/
// (parser-contract §9). Every case is `<case>.txt` (the message exactly as
// received, UTF-8, no normalization) plus `<case>.json` (expectations;
// only present keys are asserted). Adding a case adds no code.

/// The corpus root, relative to the package root (the `flutter test` cwd).
const String kSmsFixtureRoot = 'test/fixtures/sms';

/// One corpus case.
class SmsFixture {
  SmsFixture({required this.path, required this.text, required this.meta});

  /// Path of the `.txt` relative to [kSmsFixtureRoot], `/`-separated, e.g.
  /// `_noise/otp_en.txt`.
  final String path;

  /// The raw message text, byte-exact.
  final String text;

  /// The decoded `.json` expectations.
  final Map<String, dynamic> meta;

  /// The top folder: a bank id, or `_noise`, `_paste`, `_cross`, `_hostile`.
  String get folder => path.split('/').first;

  /// Whether this folder is a supported bank (gated by SC-001).
  bool get isBank => !folder.startsWith('_');

  String? get sender => meta['sender'] as String?;

  String get source => (meta['source'] as String?) ?? 'scan';

  String? get classification => meta['classification'] as String?;

  /// `receivedAt` as a LOCAL date-time (fixtures carry no offset, so the
  /// expected local day does not depend on the machine's time zone).
  DateTime? get receivedAt {
    final value = meta['receivedAt'] as String?;
    return value == null ? null : DateTime.parse(value);
  }

  /// The clock for year inference; defaults to 2026-03-10 12:00 local.
  DateTime get now {
    final value = meta['now'] as String?;
    return value == null ? DateTime(2026, 3, 10, 12) : DateTime.parse(value);
  }

  @override
  String toString() => path;
}

/// Every case under [root], sorted by path. Fails if a `.txt` has no
/// `.json` sibling.
List<SmsFixture> loadSmsFixtures({String root = kSmsFixtureRoot}) {
  final dir = Directory(root);
  if (!dir.existsSync()) {
    throw StateError('Missing fixture root $root');
  }
  final cases = <SmsFixture>[];
  final files =
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.txt'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final jsonFile = File(file.path.replaceFirst(RegExp(r'\.txt$'), '.json'));
    if (!jsonFile.existsSync()) {
      throw StateError('Missing ${jsonFile.path}');
    }
    final relative = file.path
        .replaceAll(r'\', '/')
        .substring(dir.path.replaceAll(r'\', '/').length + 1);
    cases.add(
      SmsFixture(
        path: relative,
        text: file.readAsStringSync(),
        meta: jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>,
      ),
    );
  }
  return cases;
}

/// Reads a JSON file under [kSmsFixtureRoot] (for `_versions.json` and
/// `_fingerprints.json`).
Map<String, dynamic> readFixtureJson(String name) =>
    jsonDecode(File('$kSmsFixtureRoot/$name').readAsStringSync())
        as Map<String, dynamic>;
