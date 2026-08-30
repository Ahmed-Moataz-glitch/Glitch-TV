import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/features/favorites/presentation/view_model/favorites_cubit.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';

class ChannelCard extends StatelessWidget {
  final ChannelItemEntity item;
  final VoidCallback? onTap;

  const ChannelCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final channel = item.channel;
    final logoUrl = item.logoUrl;
    final category =
        channel.categories.isNotEmpty ? channel.categories.first : 'TV';

    final isFavorite = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.isChannelFavorite(channel.id),
    );
    final l10n = context.l10n;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Container with favorite button
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? AppColors.textSecondary.withAlpha(60)
                              : AppColors.textSecondaryLight.withAlpha(30),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                        ),
                        padding: EdgeInsets.all(12.r),
                        child: Center(
                          child: logoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: logoUrl,
                                  memCacheWidth: (120 * devicePixelRatio).round(),
                                  memCacheHeight: (100 * devicePixelRatio).round(),
                                  maxWidthDiskCache: 250,
                                  maxHeightDiskCache: 250,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: context.cardBg,
                                    highlightColor:
                                        AppColors.primary.withAlpha(40),
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
                      Positioned(
                        top: 8.r,
                        right: 8.r,
                        child: GestureDetector(
                          onTap: () async {
                            final isNowFav = await context
                                .read<FavoritesCubit>()
                                .toggleFavorite(item);
                            if (context.mounted) {
                              final channelDisplayName = channel.name.isNotEmpty
                                  ? channel.name
                                  : channel.id;
                              final title = isNowFav
                                  ? (l10n?.addedToFavorites ?? 'Added to Favorites')
                                  : (l10n?.removedFromFavorites ??
                                      'Removed from Favorites');
                              AppToast.showToast(
                                context: context,
                                title: title,
                                description: channelDisplayName,
                                type: isNowFav
                                    ? ToastificationType.success
                                    : ToastificationType.info,
                              );
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(120),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 24.sp,
                              color: isFavorite
                                  ? AppColors.primaryLight
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      if (channel.country.isNotEmpty)
                        Positioned(
                          top: 8.r,
                          left: 8.r,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(180),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              channel.country.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Channel details
                Padding(
                  padding: EdgeInsets.all(10.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name.isNotEmpty ? channel.name : channel.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark.withAlpha(context.isDark ? 100 : 40),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
