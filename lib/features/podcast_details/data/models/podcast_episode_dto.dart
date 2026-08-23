import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';
import 'package:xml/xml.dart';

class PodcastEpisodeDto {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String duration;
  final String pubDate;
  final String artworkUrl;
  final String episodeNumber;

  PodcastEpisodeDto({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.duration,
    required this.pubDate,
    required this.artworkUrl,
    required this.episodeNumber,
  });

  factory PodcastEpisodeDto.fromXmlElement(
    XmlElement itemElement, {
    String fallbackArtwork = '',
  }) {
    // 1. Title
    final titleEl = itemElement.findElements('title');
    final title = titleEl.isNotEmpty
        ? _cleanText(titleEl.first.innerText)
        : 'Untitled Episode';

    // 2. Audio URL from Enclosure
    final enclosureElements = itemElement.findElements('enclosure');
    String audioUrl = '';
    if (enclosureElements.isNotEmpty) {
      audioUrl = enclosureElements.first.getAttribute('url') ?? '';
    }

    // Fallback: search for media:content if enclosure is not present
    if (audioUrl.isEmpty) {
      final mediaContents = itemElement.findElements('media:content');
      if (mediaContents.isNotEmpty) {
        audioUrl = mediaContents.first.getAttribute('url') ?? '';
      }
    }

    // 3. ID / Guid
    final guidEl = itemElement.findElements('guid');
    final id = guidEl.isNotEmpty
        ? _cleanText(guidEl.first.innerText)
        : (audioUrl.isNotEmpty ? audioUrl : title);

    // 4. Description / Summary
    final descEl = itemElement.findElements('description');
    final itunesSummaryEl = itemElement.findElements('itunes:summary');
    final contentEl = itemElement.findElements('content:encoded');
    
    String rawDesc = '';
    if (descEl.isNotEmpty && descEl.first.innerText.trim().isNotEmpty) {
      rawDesc = descEl.first.innerText;
    } else if (itunesSummaryEl.isNotEmpty) {
      rawDesc = itunesSummaryEl.first.innerText;
    } else if (contentEl.isNotEmpty) {
      rawDesc = contentEl.first.innerText;
    }
    final description = _cleanHtmlAndText(rawDesc);

    // 5. Pub Date
    final pubDateEl = itemElement.findElements('pubDate');
    final pubDate = pubDateEl.isNotEmpty
        ? _formatPubDate(_cleanText(pubDateEl.first.innerText))
        : '';

    // 6. Duration
    final itunesDurationEl = itemElement.findElements('itunes:duration');
    final duration = itunesDurationEl.isNotEmpty
        ? _formatDuration(_cleanText(itunesDurationEl.first.innerText))
        : '';

    // 7. Artwork URL
    final itunesImageEl = itemElement.findElements('itunes:image');
    String artworkUrl = '';
    if (itunesImageEl.isNotEmpty) {
      artworkUrl = itunesImageEl.first.getAttribute('href') ?? '';
    }
    if (artworkUrl.isEmpty) {
      artworkUrl = fallbackArtwork;
    }

    // 8. Episode Number
    final itunesEpEl = itemElement.findElements('itunes:episode');
    final episodeNumber =
        itunesEpEl.isNotEmpty ? _cleanText(itunesEpEl.first.innerText) : '';

    return PodcastEpisodeDto(
      id: id,
      title: title,
      description: description,
      audioUrl: audioUrl,
      duration: duration,
      pubDate: pubDate,
      artworkUrl: artworkUrl,
      episodeNumber: episodeNumber,
    );
  }

  static List<PodcastEpisodeDto> fromXmlDocument(
    XmlDocument document, {
    String fallbackArtwork = '',
  }) {
    final items = document.findAllElements('item');
    final List<PodcastEpisodeDto> list = [];

    for (final item in items) {
      final dto = PodcastEpisodeDto.fromXmlElement(
        item,
        fallbackArtwork: fallbackArtwork,
      );
      if (dto.audioUrl.isNotEmpty) {
        list.add(dto);
      }
    }
    return list;
  }

  PodcastEpisodeEntity toEntity() {
    return PodcastEpisodeEntity(
      id: id,
      title: title,
      description: description,
      audioUrl: audioUrl,
      duration: duration,
      pubDate: pubDate,
      artworkUrl: artworkUrl,
      episodeNumber: episodeNumber,
    );
  }

  static String _cleanText(String s) {
    return s
        .replaceAll('<![CDATA[', '')
        .replaceAll(']]>', '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  static String _cleanHtmlAndText(String htmlString) {
    if (htmlString.isEmpty) return '';
    var text = _cleanText(htmlString);
    // Strip HTML tags like <p>, <br>, <a>, etc.
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    // Remove extra whitespaces and newlines
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  static String _formatDuration(String rawDuration) {
    if (rawDuration.isEmpty) return '';
    // If it's already in format HH:MM:SS or MM:SS
    if (rawDuration.contains(':')) {
      final parts = rawDuration.split(':');
      if (parts.length == 2) {
        return '${parts[0]}m ${parts[1]}s';
      } else if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        if (hours > 0) {
          return '${hours}h ${minutes}m';
        }
        return '${minutes}m';
      }
      return rawDuration;
    }

    // If it's in seconds
    final totalSeconds = int.tryParse(rawDuration);
    if (totalSeconds != null && totalSeconds > 0) {
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${minutes}m';
    }

    return rawDuration;
  }

  static String _formatPubDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      // Common RSS date format: "Tue, 15 Oct 2024 14:30:00 +0000" or similar
      final parts = rawDate.split(' ');
      if (parts.length >= 4) {
        // e.g. "15 Oct 2024"
        return '${parts[1]} ${parts[2]} ${parts[3]}';
      }
    } catch (_) {}
    return rawDate;
  }
}
