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
  final EpgProgrammeEntity? currentLiveProgramme;
  final ChannelItemEntity channelItem;

  ChannelDetailsSuccess({
    required this.todayProgrammes,
    this.currentLiveProgramme,
    required this.channelItem,
  });
}
