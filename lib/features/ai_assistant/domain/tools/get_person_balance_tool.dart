import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../people/domain/entities/person.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../../transactions/domain/usecases/get_person_balance.dart';
import '../entities/tool_result.dart';
import 'ai_tool.dart';
import 'tool_arguments.dart';
import 'tool_catalog.dart';

/// Keys of a `getPersonBalance` result.
abstract final class AIPersonDataKeys {
  static const String personName = 'personName';

  /// Signed, exactly `PersonBalance.net`: positive ⇒ they owe the user,
  /// negative ⇒ the user owes them.
  static const String netMinorUnits = 'netMinorUnits';

  /// `RelationshipStatus` name: `theyOweYou` | `youOweThem` | `settled`.
  static const String status = 'status';
}

/// `getPersonBalance` — wraps [GetPersonBalance] (001).
///
/// The model supplies a name; it is resolved to a `Person.id` against the
/// people list the app's own person picker reads
/// ([PeopleRepository.searchActivePeople], plus archived people, who still
/// carry balances in 001's overview) — no people feature exposes a
/// list/search use case, so the domain repository interface is the lookup.
/// An unmatched or ambiguous name is `foundData: false`, never a guess.
@injectable
class GetPersonBalanceTool extends AITool {
  const GetPersonBalanceTool(this._getPersonBalance, this._people);

  final GetPersonBalance _getPersonBalance;
  final PeopleRepository _people;

  static const String sourceUseCase = 'GetPersonBalance';

  @override
  String get name => AIToolNames.getPersonBalance;

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    final String requested;
    switch (AIToolArgumentReader.requiredString(
      arguments,
      AIToolArgs.personName,
    )) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final value):
        requested = value;
    }

    final List<Person> people;
    switch (await _people.searchActivePeople()) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final active):
        switch (await _people.searchArchivedPeople()) {
          case Left(value: final failure):
            return Left(failure);
          case Right(value: final archived):
            people = [...active, ...archived];
        }
    }

    switch (matchByName<Person>(requested, people, (p) => p.name)) {
      case AINameNotFound():
        return Right(
          _noData({
            AIToolArgs.personName: requested,
            AIToolDataKeys.reason: AIToolNoDataReasons.personNotFound,
          }),
        );
      case AINameAmbiguous(:final candidateNames):
        return Right(
          _noData({
            AIToolArgs.personName: requested,
            AIToolDataKeys.reason: AIToolNoDataReasons.ambiguousPerson,
            AIToolDataKeys.candidates: candidateNames,
          }),
        );
      case AINameMatched(item: final person):
        final balance = await _getPersonBalance(person.id);
        return balance.map(
          (b) => ToolResult(
            toolName: name,
            sourceUseCase: sourceUseCase,
            foundData: true,
            data: {
              AIPersonDataKeys.personName: person.name,
              AIPersonDataKeys.netMinorUnits: b.net.minorUnits,
              AIPersonDataKeys.status: b.status.name,
              ...aiToolMoneyUnits,
            },
          ),
        );
    }
  }

  ToolResult _noData(Map<String, Object?> data) => ToolResult(
    toolName: name,
    sourceUseCase: sourceUseCase,
    foundData: false,
    data: data,
  );
}
