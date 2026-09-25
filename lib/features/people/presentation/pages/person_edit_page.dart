import 'package:flutter/material.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../domain/repositories/people_repository.dart';
import 'person_form_page.dart';

/// Loads [personId] before handing it to [PersonFormPage] in edit mode —
/// the router only carries the id, not the full [Person] (T093).
class PersonEditPage extends StatelessWidget {
  const PersonEditPage({required this.personId, super.key});

  final String personId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getIt<PeopleRepository>().getPersonById(personId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final l10n = AppLocalizations.of(context)!;
        return snapshot.data!.match(
          (failure) => Scaffold(
            body: AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.errorLoadTitle,
              message: l10n.messageFor(failure),
            ),
          ),
          (person) => PersonFormPage(editingPerson: person),
        );
      },
    );
  }
}
