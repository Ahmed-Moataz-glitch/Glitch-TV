part of 'home_cubit.dart';

sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class LogosLoading extends HomeState {}

final class LogosLoaded extends HomeState {
  final LogosResponseEntity logosResponseEntity;
  LogosLoaded(this.logosResponseEntity);
}

final class LogosError extends HomeState {
  final String message;
  LogosError(this.message);
}

final class ChannelsLoading extends HomeState {}

final class ChannelsLoaded extends HomeState {
  final ChannelsResponseEntity channelsResponseEntity;
  ChannelsLoaded(this.channelsResponseEntity);
}

final class ChannelsError extends HomeState {
  final String message;
  ChannelsError(this.message);
}
