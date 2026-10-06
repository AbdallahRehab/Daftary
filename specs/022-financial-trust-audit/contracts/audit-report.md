# Contract: `audit.md` structure (Track 1 deliverable)

`audit.md` is accepted only if it matches this contract. Each rule points to the spec requirement it enforces.

## Required headings, in order (FR-014)

```text
# Daftary Financial Trust Audit
## 1. Executive Summary
## 2. Current Product Assessment
## 3. Accounting Assessment
## 4. Financial Logic Assessment
## 5. Business Logic Assessment
## 6. Data Model Assessment
## 7. UX/UI Assessment
## 8. Arabic/RTL Assessment
## 9. QA Assessment
## 10. Security & Privacy Assessment
## 11. Offline/Sync Assessment
## 12. Reporting Assessment
## 13. Missing Features
## 14. Incorrect Features
## 15. Recommended Improvements
## 16. Critical Bugs
## 17. Test Scenarios
## 18. Accountant Requirements
## 19. Chief Accountant Requirements
## 20. Prioritized Backlog
# DECISIONS REQUIRED FROM ME
```

## Section rules

| Section | Must contain | Spec |
| --- | --- | --- |
| 1 | Up to 10 bullets: P0/P1 counts, the 3 biggest trust risks, the test baseline (3,699 passing, 0 covering A/B defects), and the decisions needed | FR-021 |
| 3 | A table of every concept in FR-004 and FR-005 with the columns meaning, effect, reversible, partial, edit, delete, offline, sync, and need (now, later, none) | FR-004, FR-005 |
| 4 | One `FinancialFigure` record per user-visible figure (data-model Part 1) | SC-001 |
| 5 | The 29 flows: expected, actual, defect, severity, impact, solution, and executed or traced | FR-006, SC-002 |
| 8 | The terminology table (`TerminologyEntry`), plus per-screen RTL issues | FR-017, US4 |
| 9 | The stale-state trace per list and total, with the outcome from research §3 | FR-007 |
| 11 | The per-entity sync policy table (lww, financial, append), with a verdict | FR-010 |
| 16 | Only P0/P1 `Finding`s, each with reproduction steps | SC-003 |
| 17 | `TestScenario` records, at least 5 per critical calculation, with `automated` = path or "gap" | FR-018, SC-004 |
| 18, 19 | Plain language with no code paths; for each need: met, partly met or missing, plus the backlog ID | FR-021, US3 |
| 20 | `BacklogItem` records using the plan IDs A1…H6 with every field | FR-016 |
| Decisions | At most 7 `OwnerDecision`s, each with a recommendation | FR-020, SC-006 |

## Cross-reference rules

- Every seed PF-01…PF-12 and RF-01…RF-06 appears with its research status (SC-005).
- Every Finding of P2 or higher maps to at least one backlog ID; every backlog ID is traced back to a Finding.
- Amounts are written with their currency (`1,000.00 EGP`), and status labels are given in both languages.
