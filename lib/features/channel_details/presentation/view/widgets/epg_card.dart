import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/epg_programme_entity.dart';

class EpgCard extends StatefulWidget {
  final EpgProgrammeEntity programme;

  const EpgCard({
    super.key,
    required this.programme,
  });

  @override
  State<EpgCard> createState() => _EpgCardState();
}

class _EpgCardState extends State<EpgCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final prog = widget.programme;
    final isLive = prog.isLive;
    final l10n = context.l10n;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isLive ? AppColors.primary.withAlpha(25) : context.cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isLive
              ? AppColors.primaryLight
              : (context.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
          width: isLive ? 1.5 : 1.0,
        ),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: prog.description.isNotEmpty
              ? () => setState(() => _isExpanded = !_isExpanded)
              : null,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Time & Live Badge
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: isLive ? AppColors.primary : context.cardBg,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isLive
                              ? Colors.transparent
                              : (context.isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14.sp,
                            color: isLive ? Colors.white : AppColors.primaryLight,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            prog.formattedTime.isNotEmpty
                                ? prog.formattedTime
                                : 'Scheduled',
                            style: TextStyle(
                              color: isLive ? Colors.white : context.textPrimary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isLive) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withAlpha(220),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              l10n?.nowPlaying ?? 'LIVE NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (prog.isPast) ...[
                      Text(
                        'Finished',
                        style: TextStyle(
                          color: context.textSecondary.withValues(alpha: 0.6),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 10.h),

                // Programme Title
                Text(
                  prog.title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // Subtitle if available
                if (prog.subTitle.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    prog.subTitle,
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                // Description
                if (prog.description.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    prog.description,
                    maxLines: _isExpanded ? 100 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _isExpanded ? 'Show less' : 'Read more',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.primaryLight,
                        size: 16.sp,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
