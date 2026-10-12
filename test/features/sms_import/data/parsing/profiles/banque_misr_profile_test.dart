import 'package:daftary/features/sms_import/data/parsing/profiles/banque_misr_profile.dart';

import 'profile_gate.dart';

// 023 T111: the Banque Misr gate over test/fixtures/sms/banque_misr/ (synthetic).
void main() => runProfileGate(banqueMisrProfile, minCases: 20);
