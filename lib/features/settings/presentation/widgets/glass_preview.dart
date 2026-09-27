import 'package:flutter/material.dart';

import '../../../../core/design_system/glass/app_glass_surface.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// A small, non-interactive sample of the Liquid Glass effect with the
/// user's current settings (spec US3, research Decisions 14–15).
///
/// A theme-derived backdrop (`colorScheme` shapes plus sample text) sits
/// under a top strip built from the same [AppGlassSurface] as the real bars,
/// so the preview reads the same `AppGlassScope` and cannot drift from them
/// (FR-015). It is shown only while glass is ON, is excluded from focus
/// traversal, and exposes a single descriptive semantics label.
class GlassPreview extends StatelessWidget {
  const GlassPreview({super.key});

  static const double _height = AppSpacing.xxl * 3;
  static const double _blobSize = AppSpacing.xxl * 1.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return ExcludeFocus(
      child: Semantics(
        label: l10n.glassPreviewSemantics,
        excludeSemantics: true,
        child: SizedBox(
          height: _height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: Stack(
                children: [
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    start: -AppSpacing.md,
                    width: _blobSize,
                    height: _blobSize,
                    child: _Blob(color: colorScheme.primary),
                  ),
                  PositionedDirectional(
                    top: AppSpacing.lg,
                    end: AppSpacing.xl,
                    width: _blobSize,
                    height: _blobSize,
                    child: _Blob(color: colorScheme.tertiary),
                  ),
                  PositionedDirectional(
                    bottom: -AppSpacing.md,
                    start: AppSpacing.xxl * 2,
                    width: _blobSize,
                    height: _blobSize,
                    child: _Blob(color: colorScheme.secondary),
                  ),
                  // Starts under the strip and runs past it, so the frosting
                  // is visible against the unblurred second line.
                  PositionedDirectional(
                    top: AppSpacing.xl,
                    start: AppSpacing.md,
                    end: AppSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.glassPreviewTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headline.copyWith(
                            color: onSurface,
                          ),
                        ),
                        Text(
                          l10n.glassPreviewTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(color: onSurface),
                        ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    top: 0,
                    start: 0,
                    end: 0,
                    height: kToolbarHeight,
                    child: AppGlassSurface(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.blur_on_outlined,
                            key: const Key('glass_preview_icon'),
                            color: onSurface,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.liquidGlassTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.title.copyWith(
                                color: onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One soft, theme-coloured circle in the preview backdrop.
class _Blob extends StatelessWidget {
  const _Blob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
