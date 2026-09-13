import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:lastdone/app/app_router.dart';

void main() {
  testWidgets('router exposes persistent navigation destinations', (
    tester,
  ) async {
    final appRouter = AppRouter();
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter.router));
    expect(find.text('Today'), findsNWidgets(2));
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Timeline'), findsNWidgets(2));
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    expect(find.textContaining('You'), findsNWidgets(2));
  });
}
