import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';

/// Pattern B: Full-Screen Offline Fallback Wrapper
/// Replaces the screen content with [OfflineFallbackView] whenever internet connectivity is lost.
class OfflineWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onRetry;
  final Widget Function(BuildContext context)? offlineBuilder;

  const OfflineWrapper({
    super.key,
    required this.child,
    this.onRetry,
    this.offlineBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return OfflineBuilder(
      debounceDuration: const Duration(milliseconds: 400),
      connectivityBuilder: (
        BuildContext context,
        List<ConnectivityResult> connectivity,
        Widget childWidget,
      ) {
        final bool isConnected =
            !connectivity.contains(ConnectivityResult.none);

        if (!isConnected) {
          if (offlineBuilder != null) {
            return offlineBuilder!(context);
          }
          return Scaffold(
            backgroundColor: context.scaffoldBg,
            body: SafeArea(
              child: OfflineFallbackView(onRetry: onRetry),
            ),
          );
        }

        return childWidget;
      },
      errorBuilder: (BuildContext context) => child,
      child: child,
    );
  }
}

/// Standalone Full-Screen Offline Fallback View
class OfflineFallbackView extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineFallbackView({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Glowing Network Off Icon Container
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(25),
                border: Border.all(
                  color: AppColors.primaryLight.withAlpha(70),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(40),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48.sp,
                color: AppColors.primaryLight,
              ),
            ),
            SizedBox(height: 24.h),

            // Title
            Text(
              l10n?.noInternetConnection ?? 'No Internet Connection',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 10.h),

            // Description
            Text(
              l10n?.noInternetPrompt ??
                  'Please check your network connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),

            // Retry Button
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: 20.sp),
              label: Text(
                l10n?.retry ?? 'Retry',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primary.withAlpha(120),
                padding: EdgeInsets.symmetric(
                  horizontal: 32.w,
                  vertical: 14.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
