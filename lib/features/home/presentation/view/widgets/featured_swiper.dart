import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class FeaturedSwiper extends StatefulWidget {
  final List<ChannelItemEntity> items;

  const FeaturedSwiper({super.key, required this.items});

  @override
  State<FeaturedSwiper> createState() => _FeaturedSwiperState();
}

class _FeaturedSwiperState extends State<FeaturedSwiper> {
  late final SwiperController _swiperController;

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;

    return RepaintBoundary(
      child: SizedBox(
        height: 170.h,
        child: Swiper(
          controller: _swiperController,
          physics: const ClampingScrollPhysics(),
          itemCount: widget.items.length,
          autoplay: true,
          loop: true,
          autoplayDelay: 3000,
          viewportFraction: 0.85,
          scale: 0.9,
          onTap: (index) {
            context.push(
              AppRouter.channelDetailsPath,
              extra: widget.items[index],
            );
          },
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final channel = item.channel;

            return Container(
              margin: EdgeInsets.symmetric(vertical: 4.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: context.isDark
                      ? [AppColors.primaryDark, AppColors.card]
                      : [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.primaryLight.withAlpha(80),
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
                        color: Colors.white.withAlpha(12),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 100.h,
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: context.isDark
                                    ? AppColors.textSecondary.withAlpha(100)
                                    : Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Center(
                                child: item.logoUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.logoUrl,
                                        memCacheWidth: (100 * devicePixelRatio)
                                            .toInt(),
                                        memCacheHeight: (100 * devicePixelRatio)
                                            .toInt(),
                                        fit: BoxFit.contain,
                                        alignment: Alignment.center,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                              baseColor: context.cardBg,
                                              highlightColor: AppColors.primary
                                                  .withAlpha(40),
                                              child: Container(
                                                color: context.cardBg,
                                              ),
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
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withAlpha(220),
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
                                      l10n?.live ?? 'LIVE',
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
                                channel.name.isNotEmpty
                                    ? channel.name
                                    : channel.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                channel.categories.isNotEmpty
                                    ? channel.categories.join(' • ')
                                    : (l10n?.tv ?? 'TV'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
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
          );
        },
      ),
    ),
  );
}
}
