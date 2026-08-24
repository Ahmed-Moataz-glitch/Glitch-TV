import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Glitch TV'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @liveMediaStreams.
  ///
  /// In en, this message translates to:
  /// **'Live Media & Streams'**
  String get liveMediaStreams;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @tv.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get tv;

  /// No description provided for @radio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get radio;

  /// No description provided for @podcasts.
  ///
  /// In en, this message translates to:
  /// **'Podcasts'**
  String get podcasts;

  /// No description provided for @searchTvChannels.
  ///
  /// In en, this message translates to:
  /// **'Search TV channels...'**
  String get searchTvChannels;

  /// No description provided for @searchRadioStations.
  ///
  /// In en, this message translates to:
  /// **'Search radio stations...'**
  String get searchRadioStations;

  /// No description provided for @searchPodcasts.
  ///
  /// In en, this message translates to:
  /// **'Search podcasts...'**
  String get searchPodcasts;

  /// No description provided for @searchFavorites.
  ///
  /// In en, this message translates to:
  /// **'Search favorite channels...'**
  String get searchFavorites;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noChannelsFound.
  ///
  /// In en, this message translates to:
  /// **'No channels available'**
  String get noChannelsFound;

  /// No description provided for @noRadioStationsFound.
  ///
  /// In en, this message translates to:
  /// **'No radio stations found'**
  String get noRadioStationsFound;

  /// No description provided for @noPodcastsFound.
  ///
  /// In en, this message translates to:
  /// **'No podcasts found'**
  String get noPodcastsFound;

  /// No description provided for @featuredChannels.
  ///
  /// In en, this message translates to:
  /// **'Featured Channels'**
  String get featuredChannels;

  /// No description provided for @allChannels.
  ///
  /// In en, this message translates to:
  /// **'All Channels'**
  String get allChannels;

  /// No description provided for @popularStations.
  ///
  /// In en, this message translates to:
  /// **'Popular Stations'**
  String get popularStations;

  /// No description provided for @allStations.
  ///
  /// In en, this message translates to:
  /// **'All Stations'**
  String get allStations;

  /// No description provided for @trendingPodcasts.
  ///
  /// In en, this message translates to:
  /// **'Trending Podcasts'**
  String get trendingPodcasts;

  /// No description provided for @allPodcasts.
  ///
  /// In en, this message translates to:
  /// **'All Podcasts'**
  String get allPodcasts;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @categoryQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get categoryQuran;

  /// No description provided for @categoryMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get categoryMusic;

  /// No description provided for @categoryNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get categoryNews;

  /// No description provided for @categoryCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get categoryCulture;

  /// No description provided for @categoryClassics.
  ///
  /// In en, this message translates to:
  /// **'Classics'**
  String get categoryClassics;

  /// No description provided for @categoryTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get categoryTechnology;

  /// No description provided for @categoryBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get categoryBusiness;

  /// No description provided for @categoryStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get categoryStories;

  /// No description provided for @categorySelfDev.
  ///
  /// In en, this message translates to:
  /// **'Self Development'**
  String get categorySelfDev;

  /// No description provided for @categoryComedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get categoryComedy;

  /// No description provided for @favoriteChannels.
  ///
  /// In en, this message translates to:
  /// **'Favorite Channels'**
  String get favoriteChannels;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No Favorite Channels Yet'**
  String get noFavoritesYet;

  /// No description provided for @noFavoritesDescription.
  ///
  /// In en, this message translates to:
  /// **'Add channels to your favorites by tapping the heart icon on any channel.'**
  String get noFavoritesDescription;

  /// No description provided for @channelDetails.
  ///
  /// In en, this message translates to:
  /// **'Channel Details'**
  String get channelDetails;

  /// No description provided for @watchStream.
  ///
  /// In en, this message translates to:
  /// **'Watch Stream'**
  String get watchStream;

  /// No description provided for @epgGuide.
  ///
  /// In en, this message translates to:
  /// **'TV Schedule & Guide'**
  String get epgGuide;

  /// No description provided for @noEpgAvailable.
  ///
  /// In en, this message translates to:
  /// **'No schedule guide available for this channel'**
  String get noEpgAvailable;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @todaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get todaySchedule;

  /// No description provided for @streamInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Stream Interrupted'**
  String get streamInterrupted;

  /// No description provided for @reconnectStream.
  ///
  /// In en, this message translates to:
  /// **'Reconnect Stream'**
  String get reconnectStream;

  /// No description provided for @reconnectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap below to reconnect or switch feed'**
  String get reconnectPrompt;

  /// No description provided for @streamUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Stream Unavailable'**
  String get streamUnavailable;

  /// No description provided for @availableFeeds.
  ///
  /// In en, this message translates to:
  /// **'Available Stream Feeds ({count})'**
  String availableFeeds(int count);

  /// No description provided for @fetchingStream.
  ///
  /// In en, this message translates to:
  /// **'Fetching channel stream...'**
  String get fetchingStream;

  /// No description provided for @fetchingGuide.
  ///
  /// In en, this message translates to:
  /// **'Fetching TV guide...'**
  String get fetchingGuide;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @radioPlayer.
  ///
  /// In en, this message translates to:
  /// **'Radio Player'**
  String get radioPlayer;

  /// No description provided for @buffering.
  ///
  /// In en, this message translates to:
  /// **'Buffering...'**
  String get buffering;

  /// No description provided for @playingLive.
  ///
  /// In en, this message translates to:
  /// **'Playing Live'**
  String get playingLive;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @liveRadio.
  ///
  /// In en, this message translates to:
  /// **'LIVE RADIO'**
  String get liveRadio;

  /// No description provided for @moreStations.
  ///
  /// In en, this message translates to:
  /// **'More Stations'**
  String get moreStations;

  /// No description provided for @podcastDetails.
  ///
  /// In en, this message translates to:
  /// **'Podcast Details'**
  String get podcastDetails;

  /// No description provided for @episodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodes;

  /// No description provided for @episodesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Episodes'**
  String episodesCount(int count);

  /// No description provided for @noEpisodesFound.
  ///
  /// In en, this message translates to:
  /// **'No episodes available for this podcast'**
  String get noEpisodesFound;

  /// No description provided for @nowPlayingPodcast.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlayingPodcast;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @forward10.
  ///
  /// In en, this message translates to:
  /// **'10s'**
  String get forward10;

  /// No description provided for @replay10.
  ///
  /// In en, this message translates to:
  /// **'10s'**
  String get replay10;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @systemDefaultDesc.
  ///
  /// In en, this message translates to:
  /// **'Follows your device system theme'**
  String get systemDefaultDesc;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @lightModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean and bright appearance'**
  String get lightModeDesc;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Deep dark purple theme for low light'**
  String get darkModeDesc;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @englishDefault.
  ///
  /// In en, this message translates to:
  /// **'English (Default)'**
  String get englishDefault;

  /// No description provided for @arabicOption.
  ///
  /// In en, this message translates to:
  /// **'العربية (Arabic)'**
  String get arabicOption;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get appVersion;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Stream live TV channels, listen to Egyptian and international radio stations, and enjoy top podcasts all in one place.'**
  String get appDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
