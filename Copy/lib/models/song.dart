class Song {
  final String trackName;
  final String artistName;
  final String collectionName;
  final String artworkUrl;
  final String previewUrl;
  final String spotifyUrl;

  final String moodTitle;
  final String moodEmoji;
  final int moodColor;

  const Song({
    required this.trackName,
    required this.artistName,
    required this.collectionName,
    required this.artworkUrl,
    required this.previewUrl,
    this.spotifyUrl = '',
    this.moodTitle = '',
    this.moodEmoji = '',
    this.moodColor = 0xFF95D5B2,
  });


  static String _cleanSpotifyUrl(dynamic value) {
    final url = value?.toString().trim() ?? '';
    if (url.contains('/search/recent')) return '';
    return url;
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      trackName: json['trackName'] ?? '未知歌曲',
      artistName: json['artistName'] ?? '未知歌手',
      collectionName: json['collectionName'] ?? '未知專輯',
      artworkUrl: json['artworkUrl100'] ?? json['artworkUrl'] ?? '',
      previewUrl: json['previewUrl'] ?? '',
      spotifyUrl: _cleanSpotifyUrl(json['spotifyUrl'] ?? ''),
      moodTitle: json['moodTitle'] ?? '',
      moodEmoji: json['moodEmoji'] ?? '',
      moodColor: json['moodColor'] ?? 0xFF95D5B2,
    );
  }

  factory Song.fromITunesResult(Map<String, dynamic> item) {
    final trackName = item['trackName'] ?? '未知歌曲';
    final artistName = item['artistName'] ?? '未知歌手';
    final artwork = (item['artworkUrl100'] ?? '').toString();

    return Song(
      trackName: trackName,
      artistName: artistName,
      collectionName: item['collectionName'] ?? 'iTunes Preview',
      artworkUrl: artwork.replaceAll('100x100bb', '600x600bb'),
      previewUrl: item['previewUrl'] ?? '',
      spotifyUrl: '',
    );
  }

  factory Song.fromSpotifyTrack(Map<String, dynamic> track) {
    final album = track['album'] as Map<String, dynamic>? ?? {};
    final artists = (track['artists'] as List?) ?? const [];
    final images = (album['images'] as List?) ?? const [];
    final externalUrls = track['external_urls'] as Map<String, dynamic>? ?? {};

    String artistName = '未知歌手';
    if (artists.isNotEmpty && artists.first is Map<String, dynamic>) {
      artistName = (artists.first as Map<String, dynamic>)['name'] ?? '未知歌手';
    }

    String artworkUrl = '';
    if (images.isNotEmpty && images.first is Map<String, dynamic>) {
      artworkUrl = (images.first as Map<String, dynamic>)['url'] ?? '';
    }

    return Song(
      trackName: track['name'] ?? '未知歌曲',
      artistName: artistName,
      collectionName: album['name'] ?? 'Spotify',
      artworkUrl: artworkUrl,
      previewUrl: track['preview_url'] ?? '',
      spotifyUrl: externalUrls['spotify'] ?? '',
    );
  }

  Song copyWithMood({
    required String moodTitle,
    required String moodEmoji,
    required int moodColor,
  }) {
    return Song(
      trackName: trackName,
      artistName: artistName,
      collectionName: collectionName,
      artworkUrl: artworkUrl,
      previewUrl: previewUrl,
      spotifyUrl: spotifyUrl,
      moodTitle: moodTitle,
      moodEmoji: moodEmoji,
      moodColor: moodColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trackName': trackName,
      'artistName': artistName,
      'collectionName': collectionName,
      'artworkUrl': artworkUrl,
      'previewUrl': previewUrl,
      'spotifyUrl': spotifyUrl,
      'moodTitle': moodTitle,
      'moodEmoji': moodEmoji,
      'moodColor': moodColor,
    };
  }
}
