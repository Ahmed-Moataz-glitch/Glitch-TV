import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';

class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  String _getLocalizedCategory(BuildContext context, String category) {
    final l10n = context.l10n;
    if (l10n == null) return category;
    switch (category) {
      case 'All':
        return l10n.all;
      case 'Quran':
        return l10n.categoryQuran;
      case 'Music':
        return l10n.categoryMusic;
      case 'News':
        return l10n.categoryNews;
      case 'Culture':
        return l10n.categoryCulture;
      case 'Classics':
        return l10n.categoryClassics;
      case 'Technology':
        return l10n.categoryTechnology;
      case 'Business':
        return l10n.categoryBusiness;
      case 'Stories':
        return l10n.categoryStories;
      case 'Self Development':
        return l10n.categorySelfDev;
      case 'Comedy':
        return l10n.categoryComedy;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          final localizedName = _getLocalizedCategory(context, cat);

          return GestureDetector(
            onTap: () => onSelectCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : context.cardBg,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryLight
                      : (context.isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08)),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(100),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  localizedName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.textSecondary,
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
