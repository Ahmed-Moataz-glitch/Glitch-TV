part of 'channel_details_cubit.dart';

abstract class ChannelDetailsState {}

class ChannelDetailsInitial extends ChannelDetailsState {}

class ChannelDetailsLoading extends ChannelDetailsState {}

class ChannelDetailsError extends ChannelDetailsState {
  final String message;
  ChannelDetailsError(this.message);
}

class ChannelDetailsSuccess extends ChannelDetailsState {
  final List<EpgProgrammeEntity> todayProgrammes;
  final List<EpgProgrammeEntity> tomorrowProgrammes;
  final EpgProgrammeEntity? currentLiveProgramme;
  final ChannelItemEntity channelItem;
  final int selectedDayIndex;

  ChannelDetailsSuccess({
    required this.todayProgrammes,
    required this.tomorrowProgrammes,
    this.currentLiveProgramme,
    required this.channelItem,
    this.selectedDayIndex = 0,
  });

  List<EpgProgrammeEntity> get currentProgrammes =>
      selectedDayIndex == 0 ? todayProgrammes : tomorrowProgrammes;

  ChannelDetailsSuccess copyWith({
    List<EpgProgrammeEntity>? todayProgrammes,
    List<EpgProgrammeEntity>? tomorrowProgrammes,
    EpgProgrammeEntity? currentLiveProgramme,
    ChannelItemEntity? channelItem,
    int? selectedDayIndex,
  }) {
    return ChannelDetailsSuccess(
      todayProgrammes: todayProgrammes ?? this.todayProgrammes,
      tomorrowProgrammes: tomorrowProgrammes ?? this.tomorrowProgrammes,
      currentLiveProgramme: currentLiveProgramme ?? this.currentLiveProgramme,
      channelItem: channelItem ?? this.channelItem,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
    );
  }
}
