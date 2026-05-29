import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/song.dart';

class SpotifySearchService {
  Uri buildSearchUri(Song song) {
    final trackName = song.trackName.replaceAll(RegExp(r'\s+'), '').trim();

    if (trackName.isEmpty) {
      return Uri.parse('https://open.spotify.com/search');
    }

    return Uri.parse('https://open.spotify.com/search/results/$trackName');
  }

  Future<bool> openSongOnSpotify(Song song) async {
    final uri = buildSearchUri(song);

    debugPrint('Spotify trackName: ${song.trackName}');
    debugPrint('Spotify url: $uri');

    final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);

    if (opened) return true;

    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}
