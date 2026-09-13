import 'package:flutter_test/flutter_test.dart';
import 'package:everdun/app/app_theme.dart';
import 'package:everdun/core/design_system/app_colors.dart';
import 'package:everdun/core/design_system/design_tokens.dart';

void main() {
  test('builds light and dark themes with semantic colors', () {
    final light = buildLightTheme();
    final dark = buildDarkTheme();
    expect(light.scaffoldBackgroundColor, AppColors.light.canvas);
    expect(dark.scaffoldBackgroundColor, AppColors.dark.canvas);
    expect(
      light.extension<TrackerStatusThemeExtension>()!.overdue,
      AppColors.overdueCoral,
    );
    expect(
      dark.extension<TrackerStatusThemeExtension>()!.completed,
      AppColors.completedMint,
    );
  });
}
