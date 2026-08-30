import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/features/home/domain/entities/radio_station_entity.dart';
import 'package:glitch_tv/features/home/presentation/view_model/home_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class RadioTabView extends StatefulWidget {
  final HomeCubit homeCubit;
  const RadioTabView({super.key, required this.homeCubit});

  @override
  State<RadioTabView> createState() => _RadioTabViewState();
}

class _RadioTabViewState extends State<RadioTabView>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _radioSearchController;
  String _selectedRadioCategory = 'All';

  @override
  bool get wantKeepAlive => true;
  final List<String> _radioCategories = [
    'All',
    'Quran',
    'Music',
    'News',
    'Culture',
    'Classics',
  ];
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
  void initState() {
    super.initState();
    _radioSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _radioSearchController.dispose();
    super.dispose();
  }

  bool _matchesRadioCategory(RadioStationEntity station, String category) {
    if (category == 'All') return true;

    final name = station.name.toLowerCase();
    final tags = station.tags.toLowerCase();
    final combined = '$name $tags';

    switch (category) {
      case 'Quran':
        return combined.contains('quran') ||
            combined.contains('qur\'an') ||
            combined.contains('quraan') ||
            combined.contains('قرآن') ||
            combined.contains('قران') ||
            combined.contains('islam') ||
            combined.contains('islamic') ||
            combined.contains('إسلام') ||
            combined.contains('اسلام') ||
            combined.contains('دين') ||
            combined.contains('تلاوة') ||
            combined.contains('تلاوات') ||
            combined.contains('سنة') ||
            combined.contains('sunnah') ||
            combined.contains('salaf') ||
            combined.contains('سلف') ||
            combined.contains('coptic') ||
            combined.contains('مسيحي');

      case 'Music':
        return combined.contains('music') ||
            combined.contains('موسيقى') ||
            combined.contains('موسيقي') ||
            combined.contains('أغاني') ||
            combined.contains('اغاني') ||
            combined.contains('pop') ||
            combined.contains('hits') ||
            combined.contains('songs') ||
            combined.contains('dance') ||
            combined.contains('rock') ||
            combined.contains('tarab') ||
            combined.contains('طرب') ||
            combined.contains('nogoum') ||
            combined.contains('نجوم') ||
            combined.contains('mega') ||
            combined.contains('ميجا') ||
            combined.contains('nrj') ||
            combined.contains('nile') ||
            combined.contains('mix') ||
            combined.contains('sound') ||
            combined.contains('fm') ||
            combined.contains('shaabi') ||
            combined.contains('sha3by') ||
            combined.contains('شعبي');

      case 'News':
        return combined.contains('news') ||
            combined.contains('أخبار') ||
            combined.contains('اخبار') ||
            combined.contains('talk') ||
            combined.contains('حوار') ||
            combined.contains('سياسة') ||
            combined.contains('9090') ||
            combined.contains('masr') ||
            combined.contains('مصر') ||
            combined.contains('cairo') ||
            combined.contains('القاهرة') ||
            combined.contains('bbc') ||
            combined.contains('monte carlo') ||
            combined.contains('general');

      case 'Culture':
        return combined.contains('culture') ||
            combined.contains('ثقافة') ||
            combined.contains('ثقافي') ||
            combined.contains('variety') ||
            combined.contains('منوعات') ||
            combined.contains('shabab') ||
            combined.contains('شباب') ||
            combined.contains('sport') ||
            combined.contains('رياضة') ||
            combined.contains('drama') ||
            combined.contains('دراما') ||
            combined.contains('voice') ||
            combined.contains('صوت') ||
            combined.contains('oriental') ||
            combined.contains('شرقي');

      case 'Classics':
        return combined.contains('classic') ||
            combined.contains('classics') ||
            combined.contains('كلاسيك') ||
            combined.contains('oldies') ||
            combined.contains('nostalgia') ||
            combined.contains('طرب') ||
            combined.contains('tarab') ||
            combined.contains('zaman') ||
            combined.contains('زمان') ||
            combined.contains('kalthom') ||
            combined.contains('كلثوم') ||
            combined.contains('halim') ||
            combined.contains('حليم') ||
            combined.contains('fairouz') ||
            combined.contains('فيروز') ||
            combined.contains('wahab') ||
            combined.contains('عبد الوهاب') ||
            combined.contains('turath') ||
            combined.contains('تراث');
      default:
        return combined.contains(category.toLowerCase());
    }
  }

  bool _isStationExcluded(RadioStationEntity station) {
    if (_excludedStationNames.contains(station.name.trim())) {
      return true;
    }
    if (station.name.contains('OM Kalthom')) {
      return true;
    }
    return false;
  }

  static const Set<String> _excludedStationNames = {
    'Coptic Voice Radio',
    'El Gouna Radio',
    'IVIeshal',
    'Misrin Street',
    'NRJ EGYPT',
    'OM Kalthom',
    'Radio 9090 90.9',
    'Radio Hits 88.2 Cairo',
    'Radio Quran',
    'Rebel Radio Online',
    'SHA3BY FM',
    'Tes3enat FM',
    'Thomas Lawrence',
    'إذاعة القرآن الكريم',
    '(القاهرة) إذاعة القرآن الكريم',
    'إذاعة طريق السلف',
    'تكبيرات العيد',
  };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final l10n = context.l10n;

    return BlocBuilder<HomeCubit, HomeState>(
      bloc: widget.homeCubit,
      builder: (context, state) {
        final stationsList = (state is HomeSuccess)
            ? state.radioStations
            : <RadioStationEntity>[];

        return StatefulBuilder(
          builder: (context, setRadioState) {
            final query = _radioSearchController.text.trim().toLowerCase();
            final filtered = stationsList.where((station) {
              if (_isStationExcluded(station)) {
                return false;
              }
              final matchesCategory = _matchesRadioCategory(
                station,
                _selectedRadioCategory,
              );
              final matchesQuery =
                  query.isEmpty ||
                  station.name.toLowerCase().contains(query) ||
                  station.tags.toLowerCase().contains(query);
              return matchesCategory && matchesQuery;
            }).toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(
                  decelerationRate: ScrollDecelerationRate.fast,
                ),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Input
                        Container(
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: context.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: TextField(
                            onTapOutside: (_) => FocusScope.of(context).unfocus(),
                            controller: _radioSearchController,
                            onChanged: (_) => setRadioState(() {}),
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14.sp,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  l10n?.searchRadioStations ??
                                  'Search Radio Stations...',
                              hintStyle: TextStyle(
                                color: context.textSecondary.withValues(alpha: 0.7),
                                fontSize: 14.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.radio_rounded,
                                color: AppColors.primaryLight,
                                size: 20.sp,
                              ),
                              suffixIcon: _radioSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: context.textSecondary,
                                        size: 18.sp,
                                      ),
                                      onPressed: () {
                                        _radioSearchController.clear();
                                        setRadioState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Category Selector Chips
                        SizedBox(
                          height: 40.h,
                          child: ListView.separated(
                            physics: const ClampingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            itemCount: _radioCategories.length,
                            separatorBuilder: (_, __) => SizedBox(width: 8.w),
                            itemBuilder: (context, index) {
                              final cat = _radioCategories[index];
                              final isSelected = cat == _selectedRadioCategory;
                              final localizedCat = _getLocalizedCategory(
                                context,
                                cat,
                              );

                              return ChoiceChip(
                                label: Text(localizedCat),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setRadioState(() {
                                    _selectedRadioCategory = cat;
                                  });
                                },
                                selectedColor: AppColors.primary,
                                backgroundColor: context.cardBg,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : context.textPrimary,
                                  fontSize: 12.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (context.isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.black.withValues(alpha: 0.06)),
                                  ),
                                ),
                                showCheckmark: false,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Radio List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n?.popularStations ?? 'Popular Stations',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: context.cardBg,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '${filtered.length}',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                ),
                if (state is HomeLoading)
                  SliverToBoxAdapter(child: _buildLoadingScreen())
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyView(
                      l10n?.noRadioStationsFound ??
                          'No Egyptian radio stations found',
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final station = filtered[index];
                        return Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: context.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50.w,
                                height: 50.h,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Container(
                                    padding: EdgeInsets.all(4.r),
                                    child: station.favicon.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: station.favicon,
                                            memCacheWidth: (50 * devicePixelRatio).toInt(),
                                            memCacheHeight: (50 * devicePixelRatio).toInt(),
                                            fit: BoxFit.contain,
                                            placeholder: (_, __) => Icon(
                                              Icons.radio_outlined,
                                              color: AppColors.primaryLight,
                                              size: 26.sp,
                                            ),
                                            errorWidget: (_, __, ___) => Icon(
                                              Icons.radio_outlined,
                                              color: AppColors.primaryLight,
                                              size: 26.sp,
                                            ),
                                          )
                                        : Icon(
                                            Icons.radio_outlined,
                                            color: AppColors.primaryLight,
                                            size: 26.sp,
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      station.name,
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withAlpha(
                                              30,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6.r,
                                            ),
                                          ),
                                          child: Text(
                                            station.country.isNotEmpty
                                                ? station.country
                                                : 'Egypt',
                                            style: TextStyle(
                                              color: AppColors.primaryLight,
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (station.tags.isNotEmpty) ...[
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: Text(
                                              '• ${station.tags}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: context.textSecondary,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.push(
                                    AppRouter.radioPlayerPath,
                                    extra: {
                                      'station': station,
                                      'stationsList': filtered,
                                    },
                                  );
                                },
                                icon: Icon(
                                  Icons.play_arrow_rounded,
                                  size: 18.sp,
                                ),
                                label: Text(l10n?.live ?? 'Live'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: context.cardBg,
            highlightColor: AppColors.primary.withAlpha(40),
            child: Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Shimmer.fromColors(
            baseColor: context.cardBg,
            highlightColor: AppColors.primary.withAlpha(40),
            child: Container(
              width: double.infinity,
              height: 160.h,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.h,
                crossAxisSpacing: 16.w,
                childAspectRatio: 1.1,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: context.cardBg,
                  highlightColor: AppColors.primary.withAlpha(40),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 32.w),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64.sp,
            color: context.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Try searching with a different keyword or category',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}