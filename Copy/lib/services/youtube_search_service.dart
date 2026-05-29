import 'package:url_launcher/url_launcher.dart';

import '../models/song.dart';

class YoutubeSearchService {
  Uri buildSearchUri(Song song) {
    final query = '${song.artistName} ${song.trackName}'.trim();
    return Uri.https('www.youtube.com', '/results', {'search_query': query});
  }

  Future<bool> openSongOnYoutube(Song song) async {
    final uri = buildSearchUri(song);

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}
