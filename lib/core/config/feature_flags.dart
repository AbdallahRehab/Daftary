/// Compile-time switches for Home quick actions that front whole features
/// (012 research.md Decision 4).
///
/// Each flag is owned by the feature that ships the screen behind it: while
/// a flag is `false`, Home must never offer a live route to that screen.
library;

/// "Add occasion" quick action — flipped on by Occasions (008, roadmap
/// §V2.1), whose `/occasions/new` form has shipped.
const bool kOccasionsFeatureEnabled = true;

/// "Scan paper" quick action — flipped on by OCR Paper Entry (009, roadmap
/// §V2.4), whose `/ocr/scan` capture flow has shipped.
const bool kOcrScanFeatureEnabled = true;
