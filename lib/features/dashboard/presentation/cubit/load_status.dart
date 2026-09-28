/// Lifecycle of one independently loaded Home aggregate (data-model.md
/// "Value object: LoadStatus").
///
/// The successor to the retired `OverviewStatus`: `DashboardState` carries
/// one of these per aggregate, so a failure on one side never collapses
/// the other into the same status (research.md Decision 2).
enum LoadStatus { loading, success, failure }
