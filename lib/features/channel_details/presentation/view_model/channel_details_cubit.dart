import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/epg_programme_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/use_case/fetch_epg_guide_use_case.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';

part 'channel_details_state.dart';

class ChannelDetailsCubit extends Cubit<ChannelDetailsState> {
  final FetchEpgGuideUseCase fetchEpgGuideUseCase;
  final ChannelItemEntity channelItem;

  ChannelDetailsCubit({
    required this.fetchEpgGuideUseCase,
    required this.channelItem,
  }) : super(ChannelDetailsInitial());

  static final Map<String, String> _epgChannelAliasMap = {
    'أون إي.eg': 'OnE.eg',
    'أون دراما.eg': 'OnDrama.eg',
    'إم بي سي 2.eg': 'MBC2.ae',
    'إم بي سي 3.eg': 'MBC3USA.us',
    'إم بي سي أكشن.eg': 'MBCAction.ae',
    'إم بي سي مصر 2.eg': 'MBCMasr2.eg',
    'إم بي سي مصر.eg': 'MBCMasr.eg',
    'الحياة.eg': 'AlhayatTV.eg',
    'السعيدة.eg': 'AlSaeedah.eg',
    'القاهرة والناس 2.eg': 'AlKaheraWalNas2.eg',
    'القاهرة والناس.eg': 'AlKaheraWalNas.eg',
    'المحور.eg': 'ElMehwarChannel.eg',
    'المصرية.eg': 'AlMasriyah.eg',
    'النهار دراما.eg': 'AlNaharDrama.eg',
    'النهار.eg': 'AlNahar.eg',
    'تن.eg': 'TeN.eg',
    'دي إم سي دراما.eg': 'DMCDrama.eg',
    'دي إم سي.eg': 'DMC.eg',
    'روتانا سينما مصر.eg': 'RotanaCinemaEgypt.eg',
    'سي بي سي دراما.eg': 'CBCDrama.eg',
    'سي بي سي.eg': 'CBC.eg',
    'سيما.eg': 'Cima.eg',
    'صدى البلد 2.eg': 'SadaElbalad2.eg',
    'صدى البلد دراما.eg': 'SadaElbaladDrama.eg',
    'صدى البلد.eg': 'SadaElbalad.eg',
    'عمان.eg': 'OmanTV.om',
    'ماسبيرو زمان.eg': 'MasperoZaman.eg',
    'ميكس بالعربي.eg': 'MixBelAraby.eg',
    'ناشونال جيوغرافيك أبو ظبي.eg': 'NationalGeographicAbuDhabi.ae',
    'نايل دراما.eg': 'NileDrama.eg',
    'نايل لايف.eg': 'NileLife.eg',
    'كرتون نتورك بالعربية.eg': 'CartoonNetworkArabic.ae',
    'سبيستون.eg': 'SpacetoonArabic.ae',
  };

  Future<void> loadEpg({bool forceRefresh = false}) async {
    emit(ChannelDetailsLoading());
    try {
      final result = await fetchEpgGuideUseCase.call(forceRefresh: forceRefresh);
      switch (result) {
        case ApiSuccess<List<EpgProgrammeEntity>>():
          final allProgrammes = result.data ?? [];
          final channelIdLower = channelItem.channel.id.toLowerCase();
          final channelNameLower = channelItem.channel.name.toLowerCase();

          // Filter programmes matching this channel
          final matchedProgrammes = allProgrammes.where((p) {
            final epgChLower = p.channelId.toLowerCase();
            if (epgChLower == channelIdLower) return true;

            final mappedId = _epgChannelAliasMap[p.channelId];
            if (mappedId != null && mappedId.toLowerCase() == channelIdLower) {
              return true;
            }

            final cleanEpg = epgChLower.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
            final cleanId = channelIdLower.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
            if (cleanId.isNotEmpty && cleanEpg == cleanId) return true;

            if (channelNameLower.isNotEmpty &&
                (epgChLower.contains(channelNameLower) ||
                    channelNameLower.contains(epgChLower))) {
              return true;
            }

            return false;
          }).toList();

          final now = DateTime.now();
          final tomorrow = now.add(const Duration(days: 1));

          // Filter for Today and Tomorrow
          final todayProgrammes =
              matchedProgrammes.where((p) => p.isOnDate(now)).toList();
          final tomorrowProgrammes =
              matchedProgrammes.where((p) => p.isOnDate(tomorrow)).toList();

          // Sort chronologically
          todayProgrammes.sort((a, b) {
            if (a.startTime == null) return -1;
            if (b.startTime == null) return 1;
            return a.startTime!.compareTo(b.startTime!);
          });

          tomorrowProgrammes.sort((a, b) {
            if (a.startTime == null) return -1;
            if (b.startTime == null) return 1;
            return a.startTime!.compareTo(b.startTime!);
          });

          // Find current live programme
          EpgProgrammeEntity? currentLive;
          for (var p in todayProgrammes) {
            if (p.isLive) {
              currentLive = p;
              break;
            }
          }

          final currentSelectedDay = state is ChannelDetailsSuccess
              ? (state as ChannelDetailsSuccess).selectedDayIndex
              : 0;

          emit(ChannelDetailsSuccess(
            todayProgrammes: todayProgrammes,
            tomorrowProgrammes: tomorrowProgrammes,
            currentLiveProgramme: currentLive,
            channelItem: channelItem,
            selectedDayIndex: currentSelectedDay,
          ));
        case ApiError<List<EpgProgrammeEntity>>():
          emit(ChannelDetailsError(result.message));
      }
    } catch (e) {
      emit(ChannelDetailsError('Failed to load EPG: ${e.toString()}'));
    }
  }

  void selectDay(int index) {
    if (state is ChannelDetailsSuccess) {
      final currentState = state as ChannelDetailsSuccess;
      emit(currentState.copyWith(selectedDayIndex: index));
    }
  }
}
