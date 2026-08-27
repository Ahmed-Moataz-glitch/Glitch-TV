import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/features/downloads/data/models/downloaded_episode_dto.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/podcast_details/data/services/podcast_download_service.dart';
import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final PodcastDownloadService _downloadService = PodcastDownloadService();
  final TextEditingController _searchController = TextEditingController();

  List<DownloadedEpisodeDto> _allDownloads = [];
  bool _isLoading = true;
  String _totalSize = '0 B';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    setState(() {
      _isLoading = true;
    });

    final episodes = await _downloadService.getDownloadedEpisodes();
    final sizeStr = await _downloadService.getTotalDownloadedSizeFormatted();

    if (mounted) {
      setState(() {
        _allDownloads = episodes;
        _totalSize = sizeStr;
        _isLoading = false;
      });
    }
  }

  List<DownloadedEpisodeDto> get _filteredDownloads {
    if (_searchQuery.trim().isEmpty) return _allDownloads;
    final q = _searchQuery.trim().toLowerCase();
    return _allDownloads.where((e) {
      return e.episodeTitle.toLowerCase().contains(q) ||
          e.podcastName.toLowerCase().contains(q) ||
          e.host.toLowerCase().contains(q);
    }).toList();
  }

  void _playEpisode(DownloadedEpisodeDto episode) {
    final podcast = PodcastEntity(
      id: episode.podcastId.isNotEmpty ? episode.podcastId : 'downloaded_${episode.id}',
      name: episode.podcastName.isNotEmpty ? episode.podcastName : 'Podcast',
      host: episode.host,
      artworkUrl: episode.artworkUrl,
      feedUrl: '',
      episodesCount: 1,
      category: 'Downloads',
    );

    final epEntity = PodcastEpisodeEntity(
      id: episode.id.isNotEmpty ? episode.id : episode.audioUrl,
      title: episode.episodeTitle,
      audioUrl: episode.audioUrl,
      duration: episode.duration,
      pubDate: episode.pubDate,
      description: '',
      artworkUrl: episode.artworkUrl,
      episodeNumber: '',
    );

    context.push(
      AppRouter.podcastPlayerPath,
      extra: {
        'podcast': podcast,
        'podcastsList': [podcast],
        'initialEpisodes': [epEntity],
        'initialEpisodeIndex': 0,
      },
    );
  }

  Future<void> _confirmDelete(DownloadedEpisodeDto episode) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ctx.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(
              color: ctx.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n?.deleteDownload ?? 'Delete Download',
                style: TextStyle(
                  color: ctx.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            l10n?.deleteDownloadConfirmation ??
                'Are you sure you want to delete this downloaded episode?',
            style: TextStyle(
              color: ctx.textSecondary,
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l10n?.cancel ?? 'Cancel',
                style: TextStyle(
                  color: ctx.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                l10n?.delete ?? 'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _downloadService.deleteDownloadedEpisode(
        podcastId: episode.podcastId,
        episodeTitle: episode.episodeTitle,
        audioUrl: episode.audioUrl,
      );
      await _loadDownloads();
      if (mounted) {
        AppToast.showToast(
          context: context,
          title: 'Download Removed',
          description: 'Episode deleted from your downloads.',
          type: ToastificationType.info,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final downloads = _filteredDownloads;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary,
            size: 24.sp,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(AppRouter.homePath);
            }
          },
        ),
        title: Text(
          l10n?.downloads ?? 'Downloads',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryLight,
              size: 24.sp,
            ),
            tooltip: l10n?.retry ?? 'Refresh',
            onPressed: _loadDownloads,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : _allDownloads.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadDownloads,
                    color: AppColors.primary,
                    backgroundColor: context.cardBg,
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      children: [
                        // Storage & Episodes Count Summary Card
                        _buildSummaryCard(),
                        SizedBox(height: 14.h),

                        // Search Field if more than 2 downloads
                        if (_allDownloads.length > 2) ...[
                          _buildSearchField(),
                          SizedBox(height: 14.h),
                        ],

                        // Section Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n?.downloadedEpisodes ?? 'Downloaded Episodes',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '${downloads.length}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),

                        if (downloads.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: Center(
                              child: Text(
                                l10n?.noResultsFound ?? 'No matching downloads',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          )
                        else
                          ...downloads.map(
                            (episode) => _buildDownloadCard(episode),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(context.isDark ? 30 : 15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.r,
            height: 50.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppColors.primaryLight.withAlpha(60),
              ),
            ),
            child: Icon(
              Icons.offline_pin_rounded,
              color: AppColors.primaryLight,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_allDownloads.length} ${_allDownloads.length == 1 ? "Episode" : "Episodes"} Available Offline',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${l10n?.storageUsed ?? "Storage Used"}: $_totalSize',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 14.sp,
        ),
        decoration: InputDecoration(
          hintText: l10n?.searchDownloads ?? 'Search downloads...',
          hintStyle: TextStyle(
            color: context.textSecondary.withValues(alpha: 0.6),
            fontSize: 13.sp,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: context.textSecondary,
                    size: 18.sp,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 10.h,
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadCard(DownloadedEpisodeDto episode) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () => _playEpisode(episode),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artwork thumbnail
                Container(
                  width: 60.r,
                  height: 60.r,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: episode.artworkUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: episode.artworkUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 160,
                            memCacheHeight: 160,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.podcasts_rounded,
                              color: AppColors.primaryLight,
                              size: 28.sp,
                            ),
                          )
                        : Icon(
                            Icons.podcasts_rounded,
                            color: AppColors.primaryLight,
                            size: 28.sp,
                          ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Episode Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.episodeTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      if (episode.podcastName.isNotEmpty)
                        Text(
                          episode.podcastName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          if (episode.fileSize.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                episode.fileSize,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                          if (episode.duration.isNotEmpty) ...[
                            Icon(
                              Icons.access_time_rounded,
                              color: context.textSecondary,
                              size: 11.sp,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              episode.duration,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons (Play & Delete)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: AppColors.primary,
                      ),
                      iconSize: 34.sp,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _playEpisode(episode),
                    ),
                    SizedBox(height: 8.h),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 28.sp,
                        color: Colors.redAccent.withAlpha(180),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDelete(episode),
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

  Widget _buildEmptyState() {
    final l10n = context.l10n;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90.r,
              height: 90.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(20),
                border: Border.all(
                  color: AppColors.primaryLight.withAlpha(60),
                ),
              ),
              child: Icon(
                Icons.cloud_download_outlined,
                size: 44.sp,
                color: AppColors.primaryLight,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              l10n?.noDownloadsYet ?? 'No Downloaded Episodes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n?.noDownloadsDescription ??
                  'Downloaded podcast episodes will appear here for offline listening.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
