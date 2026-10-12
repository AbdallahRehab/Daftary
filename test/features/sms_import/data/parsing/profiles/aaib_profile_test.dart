import 'package:daftary/features/sms_import/data/parsing/profiles/aaib_profile.dart';

import 'profile_gate.dart';

// 023 T115: the AAIB gate over test/fixtures/sms/aaib/ (synthetic).
void main() => runProfileGate(aaibProfile, minCases: 20);
