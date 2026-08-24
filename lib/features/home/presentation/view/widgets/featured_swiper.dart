import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class FeaturedSwiper extends StatelessWidget {
  final List<ChannelItemEntity> items;

  const FeaturedSwiper({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 170.h,
      child: Swiper(
        itemCount: items.length,
        autoplay: true,
        loop: true,
        autoplayDelay: 3000,
        viewportFraction: 0.85,
        scale: 0.9,
        itemBuilder: (context, index) {
          final item = items[index];
          final channel = item.channel;

          return GestureDetector(
            onTap: () {
              context.push(
                AppRouter.channelDetailsPath,
                extra: item,
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.card,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.primaryLight.withAlpha(50),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20.w,
                      bottom: -20.h,
                      child: Icon(
                        Icons.live_tv_rounded,
                        size: 140.sp,
                        color: Colors.white.withAlpha(10),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Row(
                        children: [
                          Container(
                            width: 150.w,
                            height: 100.h,
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withAlpha(100),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: item.logoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: item.logoUrl,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => Shimmer.fromColors(
                                      baseColor: AppColors.card,
                                      highlightColor: AppColors.primary.withAlpha(40),
                                      child: Container(color: AppColors.card),
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.tv,
                                      size: 40.sp,
                                      color: AppColors.primaryLight,
                                    ),
                                  )
                                : Icon(
                                    Icons.tv,
                                    size: 40.sp,
                                    color: AppColors.primaryLight,
                                  ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(200),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6.r,
                                        height: 6.r,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'EGYPTIAN LIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  channel.name.isNotEmpty ? channel.name : channel.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  channel.categories.isNotEmpty
                                      ? channel.categories.join(' • ')
                                      : 'Egyptian Channel',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
