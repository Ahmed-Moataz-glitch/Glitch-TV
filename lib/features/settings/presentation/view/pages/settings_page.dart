import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_constants.dart';
import 'package:glitch_tv/l10n/app_localizations.dart';
import 'package:glitch_tv/features/settings/presentation/view_model/settings_cubit.dart';
import 'package:glitch_tv/features/settings/presentation/view_model/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final AnimatedTextController _animatedTextController;

  @override
  void initState() {
    super.initState();
    _animatedTextController = AnimatedTextController();
  }

  @override
  void dispose() {
    _animatedTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColors.textSecondaryLight;
    final cardBg = isDark ? AppColors.card : AppColors.cardLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n?.settings ?? 'Settings',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              children: [
                // Appearance Section
                _buildSectionHeader(
                  title: l10n?.appearance ?? 'Appearance',
                  icon: Icons.palette_outlined,
                  textPrimary: textPrimary,
                ),
                SizedBox(height: 12.h),

                // Theme Mode Selector Segment
                _buildThemeModeSelector(
                  context: context,
                  currentMode: state.themeMode,
                  isDark: isDark,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  l10n: l10n,
                ),
                SizedBox(height: 16.h),
                // Language Section
                _buildSectionHeader(
                  title: l10n?.language ?? 'Language',
                  icon: Icons.language_rounded,
                  textPrimary: textPrimary,
                ),
                SizedBox(height: 12.h),
                // Language Dropdown Menu Widget
                _buildLanguageDropdown(
                  context: context,
                  currentLocale: state.locale,
                  isDark: isDark,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  l10n: l10n,
                ),

                SizedBox(height: 16.h),

                // About Section
                _buildSectionHeader(
                  title: l10n?.about ?? 'About',
                  icon: Icons.info_outline_rounded,
                  textPrimary: textPrimary,
                ),
                SizedBox(height: 12.h),
                _buildAboutCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  l10n: l10n,
                ),
                SizedBox(height: 24.h),
                Align(
                  alignment: Alignment.center,
                  child: AnimatedTextKit(
                    controller: _animatedTextController,
                    animatedTexts: [
                      ColorizeAnimatedText(
                        'DEVELOPED BY AHMED GLITCH',
                        textStyle: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                          AppColors.textSecondary,
                        ],
                      ),
                    ],
                    repeatForever: true,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color textPrimary,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primaryLight),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeSelector({
    required BuildContext context,
    required ThemeMode currentMode,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required AppLocalizations? l10n,
  }) {
    final themeOptions = [
      _ThemeOption(
        mode: ThemeMode.system,
        title: l10n?.systemDefault ?? 'System Default',
        subtitle: l10n?.systemDefaultDesc ?? 'Follows your device system theme',
        icon: Icons.brightness_auto_rounded,
      ),
      _ThemeOption(
        mode: ThemeMode.light,
        title: l10n?.lightMode ?? 'Light Mode',
        subtitle: l10n?.lightModeDesc ?? 'Clean and bright appearance',
        icon: Icons.light_mode_rounded,
      ),
      _ThemeOption(
        mode: ThemeMode.dark,
        title: l10n?.darkMode ?? 'Dark Mode',
        subtitle: l10n?.darkModeDesc ?? 'Deep dark purple theme for low light',
        icon: Icons.dark_mode_rounded,
      ),
    ];

    return Column(
      children: themeOptions.map((option) {
        final isSelected = currentMode == option.mode;
        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: InkWell(
            onTap: () {
              context.read<SettingsCubit>().setThemeMode(option.mode);
            },
            borderRadius: BorderRadius.circular(16.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10)
                    : cardBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      option.icon,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? AppColors.textSecondary
                                : AppColors.primary),
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected ? AppColors.primary : textPrimary,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          option.subtitle,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22.r,
                    height: 22.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.2)),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 14.sp,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageDropdown({
    required BuildContext context,
    required Locale currentLocale,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required AppLocalizations? l10n,
  }) {
    final isArabic = currentLocale.languageCode == 'ar';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.translate_rounded,
              color: AppColors.primaryLight,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.appLanguage ?? 'App Language',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isArabic
                      ? (l10n?.arabicOption ?? 'العربية (Arabic)')
                      : (l10n?.englishDefault ?? 'English (Default)'),
                  style: TextStyle(fontSize: 12.sp, color: textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentLocale.languageCode,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryLight,
                  size: 20.sp,
                ),
                borderRadius: BorderRadius.circular(14.r),
                dropdownColor: cardBg,
                elevation: 4,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'en',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🇬🇧', style: TextStyle(fontSize: 16.sp)),
                        SizedBox(width: 6.w),
                        Text(
                          l10n?.english ?? 'English',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: currentLocale.languageCode == 'en'
                                ? AppColors.primaryLight
                                : textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ar',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🇪🇬', style: TextStyle(fontSize: 16.sp)),
                        SizedBox(width: 6.w),
                        Text(
                          l10n?.arabic ?? 'العربية',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: currentLocale.languageCode == 'ar'
                                ? AppColors.primaryLight
                                : textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? newLanguageCode) {
                  if (newLanguageCode != null) {
                    context.read<SettingsCubit>().setLanguage(newLanguageCode);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard({
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required AppLocalizations? l10n,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.live_tv_rounded,
                  color: AppColors.primaryLight,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    l10n?.appVersion ?? 'Version 1.0.0',
                    style: TextStyle(fontSize: 12.sp, color: textSecondary),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n?.appDescription ??
                'Stream live TV channels, listen to Egyptian and international radio stations, and enjoy top podcasts all in one place.',
            style: TextStyle(
              fontSize: 12.5.sp,
              height: 1.4,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption {
  final ThemeMode mode;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ThemeOption({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
