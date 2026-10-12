import 'package:daftary/features/sms_import/data/parsing/profiles/instapay_profile.dart';

import 'profile_gate.dart';

// 023 T116: the InstaPay gate over test/fixtures/sms/instapay/ (synthetic).
void main() => runProfileGate(instapayProfile, minCases: 12);
