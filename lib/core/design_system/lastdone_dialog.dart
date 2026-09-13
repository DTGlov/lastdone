import 'package:flutter/material.dart';

import 'app_icons.dart';
import 'design_tokens.dart';

enum LastDoneDialogVariant {
  information,
  success,
  warning,
  error,
  confirmation,
  destructiveConfirmation,
}

Future<T?> showLastDoneDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  LastDoneDialogVariant variant = LastDoneDialogVariant.information,
  IconData? icon,
  String primaryLabel = 'Okay',
  T? primaryResult,
  String? secondaryLabel,
  T? secondaryResult,
  String? destructiveLabel,
  T? destructiveResult,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  builder: (_) => _LastDoneDialog(
    title: title,
    message: message,
    variant: variant,
    icon: icon,
    primaryLabel: primaryLabel,
    primaryResult: primaryResult,
    secondaryLabel: secondaryLabel,
    secondaryResult: secondaryResult,
    destructiveLabel: destructiveLabel,
    destructiveResult: destructiveResult,
  ),
);

class _LastDoneDialog extends StatelessWidget {
  const _LastDoneDialog({
    required this.title,
    required this.message,
    required this.variant,
    required this.primaryLabel,
    this.icon,
    this.primaryResult,
    this.secondaryLabel,
    this.secondaryResult,
    this.destructiveLabel,
    this.destructiveResult,
  });

  final String title;
  final String message;
  final LastDoneDialogVariant variant;
  final IconData? icon;
  final String primaryLabel;
  final Object? primaryResult;
  final String? secondaryLabel;
  final Object? secondaryResult;
  final String? destructiveLabel;
  final Object? destructiveResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<TrackerStatusThemeExtension>()!;
    final accent = switch (variant) {
      LastDoneDialogVariant.error => theme.colorScheme.error,
      LastDoneDialogVariant.warning => colors.dueSoon,
      LastDoneDialogVariant.success => colors.completed,
      _ => theme.colorScheme.primary,
    };
    final resolvedIcon =
        icon ??
        switch (variant) {
          LastDoneDialogVariant.success => AppIcons.complete,
          LastDoneDialogVariant.error => Icons.error_outline,
          LastDoneDialogVariant.warning => Icons.warning_amber_outlined,
          LastDoneDialogVariant.destructiveConfirmation => Icons.delete_outline,
          _ => AppIcons.insight,
        };
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: accent.withValues(alpha: 0.55)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(resolvedIcon, size: 28, color: accent),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              if (destructiveLabel != null)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () => Navigator.pop(context, destructiveResult),
                  child: Text(destructiveLabel!),
                ),
              if (destructiveLabel != null)
                const SizedBox(height: AppSpacing.xs),
              FilledButton(
                onPressed: () => Navigator.pop(context, primaryResult),
                child: Text(primaryLabel),
              ),
              if (secondaryLabel != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, secondaryResult),
                  child: Text(secondaryLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
