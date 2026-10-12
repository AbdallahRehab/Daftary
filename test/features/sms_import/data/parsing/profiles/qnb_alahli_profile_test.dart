import 'package:daftary/features/sms_import/data/parsing/profiles/qnb_alahli_profile.dart';

import 'profile_gate.dart';

// 023 T113: the QNB Alahli gate over test/fixtures/sms/qnb/ (synthetic).
void main() => runProfileGate(qnbAlahliProfile, minCases: 20);
