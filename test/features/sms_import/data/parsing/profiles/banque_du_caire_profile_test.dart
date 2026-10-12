import 'package:daftary/features/sms_import/data/parsing/profiles/banque_du_caire_profile.dart';

import 'profile_gate.dart';

// 023 T114: the Banque du Caire gate over test/fixtures/sms/banque_du_caire/ (synthetic).
void main() => runProfileGate(banqueDuCaireProfile, minCases: 20);
