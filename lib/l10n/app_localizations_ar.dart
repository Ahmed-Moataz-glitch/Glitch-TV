// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Glitch TV';

  @override
  String get home => 'الرئيسية';

  @override
  String get favorites => 'المفضلة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get liveMediaStreams => 'بثوث وقنوات مباشرة';

  @override
  String get live => 'مباشر';

  @override
  String get all => 'الكل';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get error => 'خطأ';

  @override
  String get clear => 'مسح';

  @override
  String get share => 'مشاركة';

  @override
  String get tv => 'تلفزيون';

  @override
  String get radio => 'راديو';

  @override
  String get podcasts => 'بودكاست';

  @override
  String get searchTvChannels => 'ابحث عن القنوات التلفزيونية...';

  @override
  String get searchRadioStations => 'ابحث عن محطات الراديو...';

  @override
  String get searchPodcasts => 'ابحث عن برامج البودكاست...';

  @override
  String get searchFavorites => 'ابحث في المفضلة...';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';

  @override
  String get noChannelsFound => 'لا توجد قنوات متاحة';

  @override
  String get noRadioStationsFound => 'لا توجد محطات راديو';

  @override
  String get noPodcastsFound => 'لا توجد برامج بودكاست';

  @override
  String get featuredChannels => 'القنوات المميزة';

  @override
  String get allChannels => 'جميع القنوات';

  @override
  String get popularStations => 'المحطات الشائعة';

  @override
  String get allStations => 'جميع المحطات';

  @override
  String get trendingPodcasts => 'بودكاست مميز';

  @override
  String get allPodcasts => 'جميع البودكاست';

  @override
  String get categories => 'التصنيفات';

  @override
  String get categoryQuran => 'القرآن الكريم';

  @override
  String get categoryMusic => 'موسيقى وأغاني';

  @override
  String get categoryNews => 'أخبار وحوارات';

  @override
  String get categoryCulture => 'ثقافة ومنوعات';

  @override
  String get categoryClassics => 'كلاسيكيات وطرب';

  @override
  String get categoryTechnology => 'تكنولوجيا';

  @override
  String get categoryBusiness => 'ريادة وأعمال';

  @override
  String get categoryStories => 'قصص وحكايات';

  @override
  String get categorySelfDev => 'تطوير الذات';

  @override
  String get categoryComedy => 'كوميديا وترفيه';

  @override
  String get favoriteChannels => 'القنوات المفضلة';

  @override
  String get noFavoritesYet => 'لا توجد قنوات مفضلة حتى الآن';

  @override
  String get noFavoritesDescription =>
      'أضف القنوات إلى قائمتك المفضلة بالضغط على أيقونة القلب في أي قناة.';

  @override
  String get channelDetails => 'تفاصيل القناة';

  @override
  String get watchStream => 'مشاهدة البث';

  @override
  String get epgGuide => 'دليل البرامج التلفزيونية';

  @override
  String get noEpgAvailable => 'لا يتوفر دليل برامج لهذه القناة حالياً';

  @override
  String get nowPlaying => 'يعرض الآن';

  @override
  String get upcoming => 'القادم';

  @override
  String get todaySchedule => 'جدول اليوم';

  @override
  String get streamInterrupted => 'انقطع البث';

  @override
  String get reconnectStream => 'إعادة الاتصال بالبث';

  @override
  String get reconnectPrompt => 'اضغط أدناه لإعادة الاتصال أو تبديل السيرفر';

  @override
  String get streamUnavailable => 'البث غير متاح';

  @override
  String availableFeeds(int count) {
    return 'سيرفرات البث المتاحة ($count)';
  }

  @override
  String get fetchingStream => 'جاري تحميل البث المباشر...';

  @override
  String get fetchingGuide => 'جاري تحميل دليل البرامج...';

  @override
  String get addedToFavorites => 'تمت الإضافة إلى المفضلة';

  @override
  String get removedFromFavorites => 'تمت الإزالة من المفضلة';

  @override
  String get radioPlayer => 'مشغل الراديو';

  @override
  String get buffering => 'جاري التحميل...';

  @override
  String get playingLive => 'بث مباشر يعمل الآن';

  @override
  String get paused => 'متوقف مؤقتاً';

  @override
  String get liveRadio => 'راديو مباشر';

  @override
  String get moreStations => 'محطات أخرى';

  @override
  String get podcastDetails => 'تفاصيل البودكاست';

  @override
  String get episodes => 'الحلقات';

  @override
  String episodesCount(int count) {
    return '$count حلقة';
  }

  @override
  String get noEpisodesFound => 'لا تتوفر حلقات لهذا البودكاست';

  @override
  String get nowPlayingPodcast => 'جاري الاستماع';

  @override
  String get speed => 'السرعة';

  @override
  String get forward10 => '10 ثوانٍ';

  @override
  String get replay10 => '10 ثوانٍ';

  @override
  String get appearance => 'المظهر';

  @override
  String get systemDefault => 'تلقائي حسب النظام';

  @override
  String get systemDefaultDesc => 'يتبع مظهر نظام جهازك';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get lightModeDesc => 'مظهر أنيق ومضيء';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get darkModeDesc => 'مظهر داكن مريح للعين في الإضاءة المنخفضة';

  @override
  String get language => 'اللغة';

  @override
  String get appLanguage => 'لغة التطبيق';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get englishDefault => 'English (Default)';

  @override
  String get arabicOption => 'العربية (Arabic)';

  @override
  String get about => 'حول التطبيق';

  @override
  String get appVersion => 'الإصدار 1.0.0';

  @override
  String get appDescription =>
      'شاهد القنوات التلفزيونية المباشرة واستمع لمحطات الراديو المصرية والعالمية وأفضل البودكاست في مكان واحد.';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get noInternetPrompt =>
      'يرجى التحقق من اتصالك بالشبكة والمحاولة مرة أخرى.';
}
