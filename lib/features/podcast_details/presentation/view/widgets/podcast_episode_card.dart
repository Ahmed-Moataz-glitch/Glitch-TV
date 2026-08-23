import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';

class PodcastEpisodeCard extends StatefulWidget {
  final PodcastEpisodeEntity episode;
  final int index;
  final VoidCallback onTap;

  const PodcastEpisodeCard({
    super.key,
    required this.episode,
    required this.index,
    required this.onTap,
  });

  @override
  State<PodcastEpisodeCard> createState() => _PodcastEpisodeCardState();
}

class _PodcastEpisodeCardState extends State<PodcastEpisodeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final ep = widget.episode;
    final epNum = ep.episodeNumber.isNotEmpty
        ? 'E${ep.episodeNumber}'
        : '#${widget.index + 1}';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.textSecondary.withAlpha(20),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Episode Number Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.primaryLight.withAlpha(50),
                        ),
                      ),
                      child: Text(
                        epNum,
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // Episode Title
                    Expanded(
                      child: Text(
                        ep.title,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // Play Icon Button
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),

                // Description preview
                if (ep.description.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Text(
                      ep.description,
                      textAlign: TextAlign.right,
                      maxLines: _isExpanded ? 10 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary.withAlpha(200),
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 10.h),

                // Footer with Date & Duration
                Row(
                  children: [
                    if (ep.pubDate.isNotEmpty) ...[
                      Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.textSecondary.withAlpha(150),
                        size: 12.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        ep.pubDate,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                    if (ep.pubDate.isNotEmpty && ep.duration.isNotEmpty) ...[
                      SizedBox(width: 12.w),
                      Container(
                        width: 3.w,
                        height: 3.h,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withAlpha(120),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    if (ep.duration.isNotEmpty) ...[
                      Icon(
                        Icons.access_time_rounded,
                        color: AppColors.primaryLight,
                        size: 12.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        ep.duration,
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (ep.description.length > 80)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Text(
                          _isExpanded ? 'Show less' : 'Read more',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
