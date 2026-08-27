class VerifiedChannelStream {
  final String title;
  final String url;
  final String quality;
  final String? referrer;
  final String? userAgent;

  const VerifiedChannelStream({
    required this.title,
    required this.url,
    required this.quality,
    this.referrer,
    this.userAgent,
  });
}

List<String> channels = [
  'MBC3USA.us',
  'MBCMasr2.eg',
  'MBCMasr.eg',
  'OmanTV.om',
  'Alarabiya.ae',
  'NogoumFMTV.eg',
  'WatanTV.eg',
  'AlQuranAlKareemTV.sa',
  'OmanTVCultural.om',
  'MonsterJam.us',
  'RedBullTV.at',
  'RallyTV.us',
  'Aflam.sa',
  'MBCDrama.ae',
  'AlResalah.sa',
  'LBC.sa',
  'RotanaCinemaEgypt.eg',
  'RotanaCinemaKSA.sa',
  'RotanaClassic.sa',
  'RotanaClip.sa',
  'RotanaComedy.sa',
  'RotanaDrama.sa',
  'RotanaKhalijia.sa',
  'RotanaMusic.sa',  
  'SpacetoonArabic.ae',
];

const Map<String, VerifiedChannelStream> verifiedChannelStreams = {
  'MBC3USA.us': VerifiedChannelStream(
    title: 'MBC 3 (USA/HD)',
    url: 'https://shd-gcp-live.edgenextcdn.net/live/bitmovin-mbc-3-usa/5d58265a862a476dc7f97694addb5ded/index.m3u8',
    quality: '1080p',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'MBCMasr2.eg': VerifiedChannelStream(
    title: 'MBC Masr 2',
    url: 'https://shd-gcp-live.edgenextcdn.net/live/bitmovin-mbc-masr-2/754931856515075b0aabf0e583495c68/index.m3u8',
    quality: '1080p',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'MBCMasr.eg': VerifiedChannelStream(
    title: 'MBC Masr',
    url: 'https://shd-gcp-live.edgenextcdn.net/live/bitmovin-mbc-masr/956eac069c78a35d47245db6cdbb1575/index.m3u8',
    quality: '1080p',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'OmanTV.om': VerifiedChannelStream(
    title: 'Oman TV (Akamai HD)',
    url: 'https://cdn-globecast.akamaized.net/live/eds/oman_tv/hls_roku/index.m3u8',
    quality: '1080p',
  ),
  'Alarabiya.ae': VerifiedChannelStream(
    title: 'Al Arabiya News',
    url: 'https://live.alarabiya.net/alarabiapublish/alarabiya.smil/playlist.m3u8',
    quality: '1080p',
  ),
  'NogoumFMTV.eg': VerifiedChannelStream(
    title: 'Nogoum FM TV',
    url: 'https://nogoumtv.nrpstream.com/hls/stream.m3u8',
    quality: '720p',
  ),
  'WatanTV.eg': VerifiedChannelStream(
    title: 'Watan TV',
    url: 'https://rp.tactivemedia.com/watantv_source/live/playlist.m3u8',
    quality: '1080p',
  ),
  'AlQuranAlKareemTV.sa': VerifiedChannelStream(
    title: 'Saudi Quran TV (HD)',
    url: 'https://cdn-globecast.akamaized.net/live/eds/saudi_quran/hls_roku/index.m3u8',
    quality: '720p',
  ),
  'OmanTVCultural.om': VerifiedChannelStream(
    title: 'Oman TV Cultural',
    url: 'https://partwota.cdn.mgmlcdn.com/omcultural/smil:omcultural.stream.smil/chunklist.m3u8',
    quality: '1080p',
  ),
  'MonsterJam.us': VerifiedChannelStream(
    title: 'Monster Jam TV',
    url: 'https://4b9627c7.wurl.com/master/f36d25e7e52f1ba8d7e56eb859c636563214f541/UmFrdXRlblRWLWV1X01vbnN0ZXJKYW1fSExT/playlist.m3u8',
    quality: '720p',
  ),
  'RedBullTV.at': VerifiedChannelStream(
    title: 'Red Bull TV',
    url: 'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
    quality: '1080p',
  ),
  'RallyTV.us': VerifiedChannelStream(
    title: 'Rally TV',
    url: 'https://rally-tv-live.akamaized.net/hls/live/2117704/RallyTV-Pri/master.m3u8',
    quality: '1080p',
  ),
  'Aflam.sa': VerifiedChannelStream(
    title: 'Aflam TV',
    url: 'https://shd-amg-fast.edgenextcdn.net/tx001/playlist.m3u8',
    quality: '1080p',
  ),
  'MBCDrama.ae': VerifiedChannelStream(
    title: 'MBC Drama',
    url: 'https://shd-gcp-live.edgenextcdn.net/live/bitmovin-mbc-drama/2c28a458e2f3253e678b07ac7d13fe71/index.m3u8',
    quality: '1080p',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'AlResalah.sa': VerifiedChannelStream(
    title: 'Al Resalah TV',
    url: 'https://rotana.hibridcdn.net/rotananet/risala_net-7Y83PP5adWixDF93/playlist.m3u8',
    quality: '1080p',
    referrer: 'https://rotana.net/',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'LBC.sa': VerifiedChannelStream(
    title: 'LBC Sat',
    url: 'https://rotana.hibridcdn.net/rotananet/lbc_net-7Y83PP5adWixDF93/playlist.m3u8',
    quality: '1080p',
    referrer: 'https://rotana.net/',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'RotanaCinemaEgypt.eg': VerifiedChannelStream(
    title: 'Rotana Cinema Masr',
    url: 'https://rotana.hibridcdn.net/rotananet/cinemamasr_net-7Y83PP5adWixDF93/playlist.m3u8',
    quality: '1080p',
    referrer: 'https://rotana.net/',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'RotanaCinemaKSA.sa': VerifiedChannelStream(
    title: 'Rotana Cinema KSA',
    url: 'https://rotana.hibridcdn.net/rotananet/cinema_net-7Y83PP5adWixDF93/playlist.m3u8',
    quality: '1080p',
    referrer: 'https://rotana.net/',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'RotanaClassic.sa': VerifiedChannelStream(
    title: 'Rotana Classic',
    url: 'https://rotana.hibridcdn.net/rotananet/classical_net-7Y83PP5adWixDF93/playlist.m3u8',
    quality: '1080p',
    referrer: 'https://rotana.net/',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'RotanaClip.sa': VerifiedChannelStream(
    title: 'Rotana Clip',
    url: 'https://rotana.hibridcdn.net/rotananet/clip_net-7Y83PP5adWixDF93/playlist.m3u8',
    quality: '1080p',
    referrer: 'https://rotana.net/',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'RotanaComedy.sa': VerifiedChannelStream(
    title: 'Rotana Comedy',
    url: 'https://rotana.hibridcdn.net/rotananet/comedy_net-7Y83PP5adWixDF93/playlist.m3u8',
    quality: '1080p',
    referrer: 'https://rotana.net/',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'RotanaDrama.sa': VerifiedChannelStream(
    title: 'Rotana Drama',
    url: 'https://rotana.hibridcdn.net/rotananet/drama_net-7Y83PP5adWixDF93/playlist.m3u8',
    quality: '1080p',
    referrer: 'https://rotana.net/',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'RotanaKhalijia.sa': VerifiedChannelStream(
    title: 'Rotana Khalijia',
    url: 'https://rotana.hibridcdn.net/rotananet/khaleejiya_net-7Y83PP5adWixDF93/playlist.m3u8',
    quality: '1080p',
    referrer: 'https://rotana.net/',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'RotanaMusic.sa': VerifiedChannelStream(
    title: 'Rotana Music',
    url: 'https://rotana.hibridcdn.net/rotananet/music_net-7Y83PP5adWixDF93/playlist.m3u8',
    quality: '1080p',
    referrer: 'https://rotana.net/',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  ),
  'SpacetoonArabic.ae': VerifiedChannelStream(
    title: 'Spacetoon Arabic',
    url: 'https://live-uae-next.spacetoongo.com/ST_MENA_NEXT/hls/r9p2hjipmw2kl.m3u8',
    quality: '576p',
  ),
};
