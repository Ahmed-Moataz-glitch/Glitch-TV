import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:shimmer/shimmer.dart';

class ChannelCard extends StatefulWidget {
  final ChannelItemEntity item;
  final VoidCallback? onTap;

  const ChannelCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final channel = widget.item.channel;
    final logoUrl = widget.item.logoUrl;
    final category = channel.categories.isNotEmpty ? channel.categories.first : 'TV';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.textSecondary.withAlpha(25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container with favorite button
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: size.width,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withAlpha(200),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                      ),
                      padding: EdgeInsets.all(12.r),
                      child: Center(
                        child: logoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: logoUrl,
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
                    ),
                    Positioned(
                      top: 8.r,
                      right: 8.r,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 24.sp,
                            color: _isFavorite ? AppColors.primaryLight : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    if (channel.country.isNotEmpty)
                      Positioned(
                        top: 8.r,
                        left: 8.r,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(180),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            channel.country.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
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
                        color: AppColors.textPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withAlpha(100),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 12.sp,
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
    );
  }
}
