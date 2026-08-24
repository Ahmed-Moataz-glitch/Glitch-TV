// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Glitch TV';

  @override
  String get home => 'Home';

  @override
  String get favorites => 'Favorites';

  @override
  String get settings => 'Settings';

  @override
  String get liveMediaStreams => 'Live Media & Streams';

  @override
  String get live => 'LIVE';

  @override
  String get all => 'All';

  @override
  String get retry => 'Retry';

  @override
  String get error => 'Error';

  @override
  String get clear => 'Clear';

  @override
  String get share => 'Share';

  @override
  String get tv => 'TV';

  @override
  String get radio => 'Radio';

  @override
  String get podcasts => 'Podcasts';

  @override
  String get searchTvChannels => 'Search TV channels...';

  @override
  String get searchRadioStations => 'Search radio stations...';

  @override
  String get searchPodcasts => 'Search podcasts...';

  @override
  String get searchFavorites => 'Search favorite channels...';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get noChannelsFound => 'No channels available';

  @override
  String get noRadioStationsFound => 'No radio stations found';

  @override
  String get noPodcastsFound => 'No podcasts found';

  @override
  String get featuredChannels => 'Featured Channels';

  @override
  String get allChannels => 'All Channels';

  @override
  String get popularStations => 'Popular Stations';

  @override
  String get allStations => 'All Stations';

  @override
  String get trendingPodcasts => 'Trending Podcasts';

  @override
  String get allPodcasts => 'All Podcasts';

  @override
  String get categories => 'Categories';

  @override
  String get categoryQuran => 'Quran';

  @override
  String get categoryMusic => 'Music';

  @override
  String get categoryNews => 'News';

  @override
  String get categoryCulture => 'Culture';

  @override
  String get categoryClassics => 'Classics';

  @override
  String get categoryTechnology => 'Technology';

  @override
  String get categoryBusiness => 'Business';

  @override
  String get categoryStories => 'Stories';

  @override
  String get categorySelfDev => 'Self Development';

  @override
  String get categoryComedy => 'Comedy';

  @override
  String get favoriteChannels => 'Favorite Channels';

  @override
  String get noFavoritesYet => 'No Favorite Channels Yet';

  @override
  String get noFavoritesDescription =>
      'Add channels to your favorites by tapping the heart icon on any channel.';

  @override
  String get channelDetails => 'Channel Details';

  @override
  String get watchStream => 'Watch Stream';

  @override
  String get epgGuide => 'TV Schedule & Guide';

  @override
  String get noEpgAvailable => 'No schedule guide available for this channel';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get todaySchedule => 'Today\'s Schedule';

  @override
  String get streamInterrupted => 'Stream Interrupted';

  @override
  String get reconnectStream => 'Reconnect Stream';

  @override
  String get reconnectPrompt => 'Tap below to reconnect or switch feed';

  @override
  String get streamUnavailable => 'Stream Unavailable';

  @override
  String availableFeeds(int count) {
    return 'Available Stream Feeds ($count)';
  }

  @override
  String get fetchingStream => 'Fetching channel stream...';

  @override
  String get fetchingGuide => 'Fetching TV guide...';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get radioPlayer => 'Radio Player';

  @override
  String get buffering => 'Buffering...';

  @override
  String get playingLive => 'Playing Live';

  @override
  String get paused => 'Paused';

  @override
  String get liveRadio => 'LIVE RADIO';

  @override
  String get moreStations => 'More Stations';

  @override
  String get podcastDetails => 'Podcast Details';

  @override
  String get episodes => 'Episodes';

  @override
  String episodesCount(int count) {
    return '$count Episodes';
  }

  @override
  String get noEpisodesFound => 'No episodes available for this podcast';

  @override
  String get nowPlayingPodcast => 'Now Playing';

  @override
  String get speed => 'Speed';

  @override
  String get forward10 => '10s';

  @override
  String get replay10 => '10s';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemDefault => 'System Default';

  @override
  String get systemDefaultDesc => 'Follows your device system theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get lightModeDesc => 'Clean and bright appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeDesc => 'Deep dark purple theme for low light';

  @override
  String get language => 'Language';

  @override
  String get appLanguage => 'App Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get englishDefault => 'English (Default)';

  @override
  String get arabicOption => 'العربية (Arabic)';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get appDescription =>
      'Stream live TV channels, listen to Egyptian and international radio stations, and enjoy top podcasts all in one place.';
}
