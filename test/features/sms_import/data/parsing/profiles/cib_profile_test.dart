import 'package:daftary/features/sms_import/data/parsing/profiles/cib_profile.dart';

import 'profile_gate.dart';

// 023 T112: the CIB gate over test/fixtures/sms/cib/ (synthetic).
void main() => runProfileGate(cibProfile, minCases: 20);
