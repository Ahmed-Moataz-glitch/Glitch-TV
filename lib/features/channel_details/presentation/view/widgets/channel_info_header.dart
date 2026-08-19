import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:shimmer/shimmer.dart';

class ChannelInfoHeader extends StatelessWidget {
  final ChannelItemEntity item;

  const ChannelInfoHeader({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final channel = item.channel;
    final logoUrl = item.logoUrl;
    final category =
        channel.categories.isNotEmpty ? channel.categories.first : 'TV';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.textSecondary.withAlpha(25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.scaffoldBackground.withAlpha(50),
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
              color: AppColors.textPrimary.withAlpha(210),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                strokeAlign: BorderSide.strokeAlignOutside,
                color: AppColors.primaryLight.withAlpha(80),
                width: 4.sp,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(40),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: logoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.card,
                        highlightColor: AppColors.primary.withAlpha(40),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.card,
                            shape: BoxShape.circle,
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
              color: AppColors.textPrimary,
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
                  color: AppColors.primaryDark.withAlpha(120),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 13.sp,
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (channel.network.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.textSecondary.withAlpha(50),
                    ),
                  ),
                  child: Text(
                    channel.network,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
            ],
          ),

          if (channel.owners.isNotEmpty || channel.website.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Divider(color: AppColors.textSecondary.withAlpha(30)),
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
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        channel.owners.first,
                        style: TextStyle(
                          color: AppColors.textPrimary,
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
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        channel.launched,
                        style: TextStyle(
                          color: AppColors.textPrimary,
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
