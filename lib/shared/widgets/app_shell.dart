import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final StatefulNavigationShell navigationShell;
  const AppShell(
      {super.key, required this.child, required this.navigationShell});
  static const _labels = ['Home', 'Search', 'Create', 'Learn', 'Profile'];
  static const _icons = [
    Icons.home_outlined,
    Icons.search_rounded,
    Icons.add_circle_outline_rounded,
    Icons.school_outlined,
    Icons.person_outline_rounded
  ];
  static const _selectedIcons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.add_circle_rounded,
    Icons.school_rounded,
    Icons.person_rounded
  ];

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reducedMotion ? Duration.zero : const Duration(milliseconds: 260);
    void selectBranch(int index) {
      if (index != navigationShell.currentIndex) {
        HapticFeedback.selectionClick();
      }
      navigationShell.goBranch(index,
          initialLocation: index == navigationShell.currentIndex);
    }

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Align(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: DecoratedBox(
                      key: const ValueKey('floating-navigation'),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.plum.withValues(alpha: .12),
                                blurRadius: 24,
                                offset: const Offset(0, 8))
                          ]),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: SizedBox(
                              height: 64,
                              child: LayoutBuilder(
                                  builder: (context, constraints) {
                                final width = (constraints.maxWidth - 12) / 5;
                                return Stack(children: [
                                  AnimatedPositioned(
                                    key: const ValueKey('navigation-highlight'),
                                    duration: duration,
                                    curve: Curves.easeOutCubic,
                                    left: 6 +
                                        width * navigationShell.currentIndex,
                                    top: 6,
                                    bottom: 6,
                                    width: width,
                                    child: DecoratedBox(
                                        decoration: BoxDecoration(
                                            color: AppColors.lavender
                                                .withValues(alpha: .8),
                                            borderRadius:
                                                BorderRadius.circular(26))),
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: Row(children: [
                                        for (var index = 0; index < 5; index++)
                                          Expanded(
                                              child: Semantics(
                                            label: _labels[index],
                                            selected: index ==
                                                navigationShell.currentIndex,
                                            button: true,
                                            onTap: () => selectBranch(index),
                                            child: ExcludeSemantics(
                                                child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      overlayColor:
                                                          const WidgetStatePropertyAll(
                                                              Colors
                                                                  .transparent),
                                                      splashFactory: NoSplash
                                                          .splashFactory,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              26),
                                                      onTap: () =>
                                                          selectBranch(index),
                                                      child: Center(
                                                          child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                            AnimatedSwitcher(
                                                                duration:
                                                                    duration,
                                                                child: Icon(
                                                                    index ==
                                                                            navigationShell
                                                                                .currentIndex
                                                                        ? _selectedIcons[
                                                                            index]
                                                                        : _icons[
                                                                            index],
                                                                    key: ValueKey(
                                                                        '${_labels[index]}-${index == navigationShell.currentIndex}'),
                                                                    size: 23,
                                                                    color: index ==
                                                                            navigationShell
                                                                                .currentIndex
                                                                        ? AppColors
                                                                            .purpleAccent
                                                                        : AppColors
                                                                            .textSecondary)),
                                                            const SizedBox(
                                                                height: 3),
                                                            AnimatedDefaultTextStyle(
                                                                duration:
                                                                    duration,
                                                                curve: Curves
                                                                    .easeOutCubic,
                                                                style: TextStyle(
                                                                    fontFamily:
                                                                        AppFonts
                                                                            .uncutSans,
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight: index ==
                                                                            navigationShell
                                                                                .currentIndex
                                                                        ? FontWeight
                                                                            .w600
                                                                        : FontWeight
                                                                            .w500,
                                                                    color: index ==
                                                                            navigationShell
                                                                                .currentIndex
                                                                        ? AppColors
                                                                            .purpleAccent
                                                                        : AppColors
                                                                            .textSecondary),
                                                                child: Text(
                                                                    _labels[
                                                                        index],
                                                                    maxLines:
                                                                        1)),
                                                          ])),
                                                    ))),
                                          ))
                                      ])),
                                ]);
                              }))),
                    ),
                  )),
            ),
    );
  }
}

/// Crossfade persistent branch navigators without recreating their state.
class SmoothBranchContainer extends StatelessWidget {
  final int currentIndex;
  final List<Widget> children;
  const SmoothBranchContainer(
      {super.key, required this.currentIndex, required this.children});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        for (var index = 0; index < children.length; index++)
          IgnorePointer(
            ignoring: index != currentIndex,
            child: ExcludeSemantics(
                excluding: index != currentIndex,
                child: AnimatedOpacity(
                  opacity: index == currentIndex ? 1 : 0,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: TickerMode(
                      enabled: index == currentIndex, child: children[index]),
                )),
          ),
      ]);
}
