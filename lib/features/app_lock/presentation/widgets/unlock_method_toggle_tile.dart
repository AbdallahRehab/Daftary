import 'package:flutter/material.dart';

/// A switch row for one unlock method (FR-024).
///
/// When the method is not usable on this device the switch is disabled and
/// [unavailableMessage] replaces the [subtitle], so the user learns *why* it
/// cannot be turned on instead of meeting a dead control (FR-005/FR-007).
class UnlockMethodToggleTile extends StatelessWidget {
  const UnlockMethodToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.unavailableMessage,
    required this.isAvailable,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String unavailableMessage;
  final bool isAvailable;
  final bool value;

  /// `null` disables the switch (e.g. while a change is being saved).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(isAvailable ? subtitle : unavailableMessage),
      // An unavailable method always reads as off, even if it was enabled
      // before the device lost its enrolment.
      value: isAvailable && value,
      onChanged: isAvailable ? onChanged : null,
    );
  }
}
