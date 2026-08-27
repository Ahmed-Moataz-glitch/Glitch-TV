import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/view/widgets/offline_wrapper.dart';
import 'package:glitch_tv/features/favorites/presentation/view/pages/favorites_page.dart';
import 'package:glitch_tv/features/favorites/presentation/view_model/favorites_cubit.dart';
import 'package:glitch_tv/features/home/presentation/view/pages/home_page.dart';
import 'package:glitch_tv/features/home/presentation/view_model/home_cubit.dart';
import 'package:glitch_tv/features/settings/presentation/view/pages/settings_page.dart';
import 'package:glitch_tv/l10n/app_localizations.dart';

class AppSection extends StatefulWidget {
  final int initialIndex;

  const AppSection({super.key, this.initialIndex = 0});

  @override
  State<AppSection> createState() => _AppSectionState();
}

class _AppSectionState extends State<AppSection> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomePage(),
    FavoritesPage(),
    SettingsPage(),
  ];

  final List<IconData> _outlinedIcons = const [
    Icons.home_outlined,
    Icons.favorite_border,
    Icons.settings_outlined,
  ];

  final List<IconData> _filledIcons = const [
    Icons.home_rounded,
    Icons.favorite_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n?.home ?? 'Home',
      l10n?.favorites ?? 'Favorites',
      l10n?.settings ?? 'Settings',
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return OfflineWrapper(
      onRetry: () {
        context.read<HomeCubit>().loadData();
        context.read<FavoritesCubit>().loadFavorites();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedBottomNavigationBar.builder(
          itemCount: _pages.length,
          activeIndex: _currentIndex,
          height: 64.h,
          gapLocation: GapLocation.none,
          notchSmoothness: NotchSmoothness.smoothEdge,
          elevation: 0,
          backgroundColor: Theme.of(context).cardColor,
          splashColor: AppColors.primary.withValues(alpha: 0.15),
          splashSpeedInMilliseconds: 300,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          tabBuilder: (index, isActive) {
            final activeColor = AppColors.primary;
            final color = isActive ? activeColor : inactiveColor;
      
            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Active Top Indicator Pill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      height: 3.h,
                      width: isActive ? 20.w : 0.w,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(2.r),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                    ),
                    SizedBox(height: 4.h),
      
                    // Icon with scale micro-animation
                    AnimatedScale(
                      scale: isActive ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        isActive ? _filledIcons[index] : _outlinedIcons[index],
                        size: 24.sp,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 2.h),
      
                    // Label with font weight transition
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: color,
                        fontSize: 13.sp,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      ),
                      child: Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
}
