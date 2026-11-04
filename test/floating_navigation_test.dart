import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:brainrotgram/shared/widgets/app_shell.dart';
import 'package:brainrotgram/theme/app_theme.dart';

void main() {
  testWidgets(
      'floating navigation fits a narrow phone, switches branches, and hides for the keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final router = GoRouter(initialLocation: '/tab0', routes: [
      StatefulShellRoute(
          navigatorContainerBuilder: (context, shell, children) =>
              SmoothBranchContainer(
                  currentIndex: shell.currentIndex, children: children),
          builder: (context, state, shell) =>
              AppShell(navigationShell: shell, child: shell),
          branches: [
            for (var i = 0; i < 5; i++)
              StatefulShellBranch(routes: [
                GoRoute(
                    path: '/tab$i',
                    builder: (_, __) =>
                        Scaffold(body: Center(child: Text('Page $i'))))
              ])
          ])
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router));
    await tester.pumpAndSettle();
    final rect =
        tester.getRect(find.byKey(const ValueKey('floating-navigation')));
    expect(rect.left, 16);
    expect(rect.right, 304);
    expect(rect.height, 64);
    final highlight = find.byKey(const ValueKey('navigation-highlight'));
    final start = tester.getTopLeft(highlight).dx;
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final moving = tester.getTopLeft(highlight).dx;
    expect(moving, greaterThan(start));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(highlight).dx, greaterThan(moving));
    expect(find.text('Page 1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('floating-navigation')), findsNothing);
  });
}
