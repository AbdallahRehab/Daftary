import 'package:sqlite3/sqlite3.dart';

/// Removes exactly what the 011 v11 step adds (the three savings tables;
/// their indexes go with them), turning a database created from today's
/// schema back into its v10 shape. Every "today's schema minus N" migration
/// fixture calls this, so the upgrade runs v11 for real.
void dropSavingsGoalsAdditions(Database raw) {
  raw.execute('DROP TABLE savings_contribution_audits;');
  raw.execute('DROP TABLE savings_contributions;');
  raw.execute('DROP TABLE savings_goals;');
}
