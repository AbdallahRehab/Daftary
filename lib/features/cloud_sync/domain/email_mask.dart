/// Masks an email for display: `ahmed@gmail.com` becomes `a***@g***.com`
/// (contracts/dart-interfaces.md §4). The raw address is never shown or
/// logged.
String maskEmail(String email) {
  final trimmed = email.trim();
  final at = trimmed.lastIndexOf('@');
  if (at <= 0 || at == trimmed.length - 1) return '***';
  final local = trimmed.substring(0, at);
  final domain = trimmed.substring(at + 1);
  final dot = domain.lastIndexOf('.');
  final host = dot > 0 ? domain.substring(0, dot) : domain;
  final tld = dot > 0 ? domain.substring(dot) : '';
  return '${local[0]}***@${host[0]}***$tld';
}
