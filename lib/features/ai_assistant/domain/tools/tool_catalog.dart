import '../services/ai_service.dart';

/// The fixed set of tool names the provider may request
/// (contracts/financial_query_tools.md). Referenced everywhere instead of
/// string literals, so a tool can never be declared under one name and
/// dispatched under another.
abstract final class AIToolNames {
  static const String getCategorySpend = 'getCategorySpend';
  static const String getTopSpendingCategory = 'getTopSpendingCategory';
  static const String compareSpendingAcrossPeriods =
      'compareSpendingAcrossPeriods';
  static const String getPersonBalance = 'getPersonBalance';
  static const String getOwedOverview = 'getOwedOverview';
  static const String getBudgetStatus = 'getBudgetStatus';
  static const String getOccasionTotals = 'getOccasionTotals';

  static const String getSavingsGoalStatus = 'getSavingsGoalStatus';
  static const String getSavingsProjection = 'getSavingsProjection';

  /// Every declared name — what a requested tool call is checked against
  /// before anything is dispatched.
  static const Set<String> all = {
    getCategorySpend,
    getTopSpendingCategory,
    compareSpendingAcrossPeriods,
    getPersonBalance,
    getOwedOverview,
    getBudgetStatus,
    getSavingsGoalStatus,
    getSavingsProjection,
    getOccasionTotals,
  };
}

/// Argument keys used in the tool schemas below — the same constants the
/// tool implementations read the model-supplied arguments by.
abstract final class AIToolArgs {
  static const String period = 'period';
  static const String periodA = 'periodA';
  static const String periodB = 'periodB';
  static const String categoryName = 'categoryName';
  static const String personName = 'personName';
  static const String month = 'month';
  static const String occasionName = 'occasionName';
  static const String goalName = 'goalName';

  /// `getSavingsProjection`: a hypothetical monthly contribution, integer
  /// minor units of the goal's own currency (011 FR-013).
  static const String hypotheticalMonthlyContributionMinorUnits =
      'hypotheticalMonthlyContributionMinorUnits';

  /// `getSavingsProjection`: a hypothetical `YYYY-MM-DD` date to finish the
  /// goal by (011 FR-014).
  static const String hypotheticalTargetDate = 'hypotheticalTargetDate';

  /// Keys inside a period object.
  static const String preset = 'preset';
  static const String startDate = 'startDate';
  static const String endDate = 'endDate';
}

/// Values of a period object's [AIToolArgs.preset]. `custom` requires
/// [AIToolArgs.startDate] and [AIToolArgs.endDate] (`YYYY-MM-DD`,
/// inclusive); the tool resolves presets exactly as 007's own period
/// presets are resolved — the model never does date math.
abstract final class AIPeriodPresets {
  static const String thisMonth = 'thisMonth';
  static const String lastMonth = 'lastMonth';
  static const String custom = 'custom';

  static const List<String> all = [thisMonth, lastMonth, custom];
}

/// The shared JSON schema for one period argument.
Map<String, Object?> _periodSchema(String description) => {
  'type': 'object',
  'description': description,
  'properties': {
    AIToolArgs.preset: {'type': 'string', 'enum': AIPeriodPresets.all},
    AIToolArgs.startDate: {
      'type': 'string',
      'description': 'YYYY-MM-DD, inclusive. Only when preset is "custom".',
    },
    AIToolArgs.endDate: {
      'type': 'string',
      'description': 'YYYY-MM-DD, inclusive. Only when preset is "custom".',
    },
  },
  'required': [AIToolArgs.preset],
};

/// The tool declarations sent to the provider on every turn
/// (`AIService.sendTurn`'s `availableTools`). Declarations only — each
/// tool's implementation in this directory wraps exactly one existing use
/// case and performs no arithmetic of its own (research.md Decision 4).
///
/// Every description tells the model the same thing: figures come back
/// from the app's own calculations, and `foundData: false` means there is
/// genuinely nothing to report — say so, never invent a number.
final List<AIToolDeclaration> aiToolCatalog = List.unmodifiable([
  AIToolDeclaration(
    name: AIToolNames.getCategorySpend,
    description:
        "Returns the user's recorded expense total per category for a "
        'period (amounts in integer minor units, with each category\'s share '
        'of the period total). Pass categoryName to get one category; omit '
        'it for all categories.',
    parametersSchema: {
      'type': 'object',
      'properties': {
        AIToolArgs.period: _periodSchema('The period to report on.'),
        AIToolArgs.categoryName: {
          'type': 'string',
          'description': 'Expense category name, as the user said it.',
        },
      },
      'required': [AIToolArgs.period],
    },
  ),
  AIToolDeclaration(
    name: AIToolNames.getTopSpendingCategory,
    description:
        'Returns the single expense category the user spent the most on in '
        'a period, with its amount (integer minor units) and share of the '
        'period total.',
    parametersSchema: {
      'type': 'object',
      'properties': {
        AIToolArgs.period: _periodSchema('The period to report on.'),
      },
      'required': [AIToolArgs.period],
    },
  ),
  AIToolDeclaration(
    name: AIToolNames.compareSpendingAcrossPeriods,
    description:
        "Compares the user's total expenses in two periods: both totals, "
        'the difference and the percentage change (integer minor units).',
    parametersSchema: {
      'type': 'object',
      'properties': {
        AIToolArgs.periodA: _periodSchema('The earlier/baseline period.'),
        AIToolArgs.periodB: _periodSchema('The period compared against it.'),
      },
      'required': [AIToolArgs.periodA, AIToolArgs.periodB],
    },
  ),
  AIToolDeclaration(
    name: AIToolNames.getPersonBalance,
    description:
        'Returns the net balance between the user and one named person '
        '(integer minor units) and whether they owe the user, the user owes '
        'them, or they are settled.',
    parametersSchema: {
      'type': 'object',
      'properties': {
        AIToolArgs.personName: {
          'type': 'string',
          'description': "The person's name, as the user said it.",
        },
      },
      'required': [AIToolArgs.personName],
    },
  ),
  AIToolDeclaration(
    name: AIToolNames.getOwedOverview,
    description:
        'Returns who owes the user money and whom the user owes, with each '
        'net amount and the two totals (integer minor units).',
    parametersSchema: {'type': 'object', 'properties': <String, Object?>{}},
  ),
  AIToolDeclaration(
    name: AIToolNames.getBudgetStatus,
    description:
        "Returns the user's budget for a month: planned vs actual per "
        'category, remaining amounts, percentage used, and whether the '
        'month is over budget (integer minor units).',
    parametersSchema: {
      'type': 'object',
      'properties': {
        AIToolArgs.month: {
          'type': 'string',
          'description': 'YYYY-MM. Omit for the current month.',
        },
      },
    },
  ),
  AIToolDeclaration(
    name: AIToolNames.getSavingsGoalStatus,
    description:
        "Returns the user's savings goals: target, saved, remaining, "
        'percentage progress, whether achieved, and the estimated completion '
        '(months and date) and required monthly contribution the app '
        'computed for each. Each goal carries its own currency — amounts are '
        'integer minor units of that goal\'s currency. Pass goalName for one '
        'goal; omit it for every active goal plus the total saved in the '
        'primary currency.',
    parametersSchema: {
      'type': 'object',
      'properties': {
        AIToolArgs.goalName: {
          'type': 'string',
          'description': "The savings goal's name, as the user said it.",
        },
      },
    },
  ),
  AIToolDeclaration(
    name: AIToolNames.getSavingsProjection,
    description:
        'A read-only "what if" for one savings goal, computed by the app '
        '(the goal is never changed). Give exactly one of: '
        'hypotheticalMonthlyContributionMinorUnits (returns how many months '
        'it would take and the completion date), or hypotheticalTargetDate '
        '(returns the monthly contribution required to finish by then). '
        'Amounts are integer minor units of the goal\'s own currency — call '
        'getSavingsGoalStatus first if you do not know it.',
    parametersSchema: {
      'type': 'object',
      'properties': {
        AIToolArgs.goalName: {
          'type': 'string',
          'description': "The savings goal's name, as the user said it.",
        },
        AIToolArgs.hypotheticalMonthlyContributionMinorUnits: {
          'type': 'integer',
          'description':
              'A monthly amount to try, > 0, in integer minor units of the '
              "goal's currency (the user's own figure, only re-expressed in "
              'minor units).',
        },
        AIToolArgs.hypotheticalTargetDate: {
          'type': 'string',
          'description': 'YYYY-MM-DD, after today: the date to finish by.',
        },
      },
      'required': [AIToolArgs.goalName],
    },
  ),
  AIToolDeclaration(
    name: AIToolNames.getOccasionTotals,
    description:
        'Returns money received, given and net for a named occasion (e.g. a '
        'wedding), or for recent occasions when no name is given (integer '
        'minor units).',
    parametersSchema: {
      'type': 'object',
      'properties': {
        AIToolArgs.occasionName: {
          'type': 'string',
          'description': "The occasion's name, as the user said it.",
        },
      },
    },
  ),
]);
