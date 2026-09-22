# Phase 1 Data Model: Financial Education & Wealth Planning

*All content entities below are bundled static assets, loaded read-only at runtime — there is no SQL schema for this feature (research.md Decision 1). The three "Scenario" value objects are ephemeral, never persisted, and never associated with any other stored entity.*

## Entity: EducationCategory (NEW, bundled static content)

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | Stable identifier (e.g. `saving_strategies`), used for navigation only — never shown to the user. |
| `title` | `String` | Localized per active language (research.md Decision 1: separate `en`/`ar` content trees). |
| `shortDescription` | `String` | Localized. Shown on the content library home. |
| `articleIds` | `List<String>` | Ordered list of `EducationArticle.id` belonging to this category. |

## Entity: EducationArticle (NEW, bundled static content)

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | Stable identifier (e.g. `what_is_diversification`), unique across all categories. |
| `categoryId` | `String` | FK to `EducationCategory.id`. |
| `title` | `String` | Localized. |
| `shortDescription` | `String` | Localized. Shown in the category's article list (FR-003). |
| `bodySections` | `List<ArticleSection>` | Localized. Structured as an ordered list of headed sections rather than one opaque blob, so the UI can render headings/paragraphs consistently without a markdown parser (research.md Decision 1). |

### Value Object: ArticleSection *(part of EducationArticle, not independently addressable)*

| Field | Type | Notes |
|---|---|---|
| `heading` | `String?` | Optional — a plain paragraph section may omit it. |
| `paragraphs` | `List<String>` | One or more paragraphs of body text. |

**Content-authoring rule (enforced by review, not by type system)**: no `EducationArticle` body may name a specific investment product/asset/platform or phrase content as a directive ("you should..."); this is FR-004/FR-006's requirement, verified per SC-004's content audit — see tasks.md's dedicated content-review task.

## Value Object: CompoundGrowthResult *(ephemeral, not persisted)*

| Field | Type | Notes |
|---|---|---|
| `futureValueMinorUnits` | `int` | Computed per research.md Decision 4's formula. |
| `totalContributedMinorUnits` | `int` | `monthlyContributionMinorUnits × months`. |
| `totalGrowthMinorUnits` | `int` | `futureValueMinorUnits − totalContributedMinorUnits`. |
| `isHighRateWarningShown` | `bool` | True when the entered annual rate exceeds the sanity-check threshold (FR-010, research.md/spec.md Assumptions — e.g. 30%). |

**Validation rules** (enforced in `CompoundGrowthCalculator`, per FR-008): `monthlyContributionMinorUnits > 0`; `annualRatePercent >= 0` (zero allowed, negative rejected); `years > 0`.

## Value Object: DoublingTimeResult *(ephemeral, not persisted)*

| Field | Type | Notes |
|---|---|---|
| `approximateDoublingYears` | `double` | `72 / annualRatePercent` (FR-011). |

**Validation rules**: `annualRatePercent > 0` (zero and negative both rejected — a doubling time is undefined at zero, per FR-011).

## Value Object: SavingsRateResult *(ephemeral, not persisted)*

| Field | Type | Notes |
|---|---|---|
| `savingsRatePercent` | `double` | `(savingsAmountMinorUnits / incomeMinorUnits) × 100` (FR-012). |

**Validation rules**: `incomeMinorUnits > 0` (division by zero rejected); `savingsAmountMinorUnits >= 0`; a `savingsAmountMinorUnits` exceeding `incomeMinorUnits` is explicitly **accepted**, never clamped or rejected (FR-012/Edge Cases).

## Relationships

```text
EducationCategory ──1:N── EducationArticle    (bundled static content, no runtime mutation)

CompoundGrowthResult, DoublingTimeResult, SavingsRateResult
    — no relationship to any persisted entity. CompoundGrowthResult's one integration point
      (FR-014) is a one-way, read-only value copy from SavingsGoal.currentAmountMinorUnits (011)
      into the calculator's INPUT field at the Presentation layer, not a stored or computed
      relationship on the result itself.
```

No relationship to any `AppDatabase` table — this feature reads nothing from and writes nothing to `drift`/SQLite (FR-019), aside from the single explicit, read-only `SavingsRepository.getSavingsOverview()` call (011) used only to populate an editable default value in a text field.

## Bundled Content Asset Sketch (for Phase 2 task planning, not exhaustive)

```text
lib/features/financial_education/data/content/
├── en/
│   ├── categories.json         # [{id, title, shortDescription, articleIds}, ...]
│   └── articles/
│       ├── why_track_your_spending.json
│       ├── what_is_diversification.json
│       └── ...
└── ar/
    ├── categories.json         # same ids, ar-localized title/shortDescription
    └── articles/
        └── ... (same ids as en/, ar-localized content)
```

Each locale tree uses the **same stable ids** across `en`/`ar` so navigation and deep-linking (e.g. "open article X") work identically regardless of the active language — only the localized text differs.
