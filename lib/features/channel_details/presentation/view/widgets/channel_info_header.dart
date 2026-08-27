import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class ChannelInfoHeader extends StatelessWidget {
  final ChannelItemEntity item;

  const ChannelInfoHeader({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final channel = item.channel;
    final logoUrl = item.logoUrl;
    final category =
        channel.categories.isNotEmpty ? channel.categories.first : 'TV';
    final l10n = context.l10n;

    return Container(
      width: size.width,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Avatar
          Container(
            width: 100.w,
            height: 100.h,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.textSecondary.withAlpha(180) : AppColors.textSecondaryLight.withAlpha(50),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                strokeAlign: BorderSide.strokeAlignOutside,
                color: AppColors.primaryLight.withAlpha(80),
                width: 4.sp,
              ),
            ),
            child: Center(
              child: logoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      memCacheWidth: (100 * devicePixelRatio).toInt(),
                      memCacheHeight: (100 * devicePixelRatio).toInt(),
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: context.cardBg,
                        highlightColor: AppColors.primary.withAlpha(40),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.live_tv,
                        size: 48.sp,
                        color: AppColors.primaryLight,
                      ),
                    )
                  : Icon(
                      Icons.live_tv,
                      size: 48.sp,
                      color: AppColors.primaryLight,
                    ),
            ),
          ),
          SizedBox(height: 16.h),

          // Channel Name
          Text(
            channel.name.isNotEmpty ? channel.name : channel.id,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),

          // Category & Country Badges
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withAlpha(context.isDark ? 120 : 40),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (channel.country.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(160),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    channel.country.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (channel.network.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: context.isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    channel.network,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Watch Now Button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(AppRouter.watchStreamPath, extra: item);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                icon: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
                label: Text(
                  l10n?.watchStream ?? 'Watch Stream',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          if (channel.owners.isNotEmpty || channel.website.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Divider(
              color: context.dividerColor,
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (channel.owners.isNotEmpty)
                  Column(
                    children: [
                      Text(
                        'Owner',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        channel.owners.first,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (channel.launched.isNotEmpty)
                  Column(
                    children: [
                      Text(
                        'Launched',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        channel.launched,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
