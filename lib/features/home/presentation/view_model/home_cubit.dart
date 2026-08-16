import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glitch_tv/features/home/data/api/api_result.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';
import 'package:glitch_tv/features/home/domain/use_case/fetch_channels_use_case.dart';
import 'package:glitch_tv/features/home/domain/use_case/fetch_logos_use_case.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  FetchLogosUseCase fetchLogosUseCase;
  FetchChannelsUseCase fetchChannelsUseCase;
  HomeCubit({
    required this.fetchLogosUseCase,
    required this.fetchChannelsUseCase,
  }) : super(HomeInitial());

  Future<void> fetchLogos() async {
    emit(LogosLoading());
    final result = await fetchLogosUseCase.call();
    switch(result){
      case ApiSuccess<LogosResponseEntity>():
        emit(LogosLoaded(result.data!));
      case ApiError<LogosResponseEntity>():
        emit(LogosError(result.message));
    }
  }

  Future<void> fetchChannels() async {
    emit(ChannelsLoading());
    final result = await fetchChannelsUseCase.call();
    switch(result){
      case ApiSuccess<ChannelsResponseEntity>():
        emit(ChannelsLoaded(result.data!));
      case ApiError<ChannelsResponseEntity>():
        emit(ChannelsError(result.message));
    }
  }
}
