class Song {
  final String trackName;
  final String artistName;
  final String collectionName;
  final String artworkUrl;
  final String previewUrl;

  final String moodTitle;
  final String moodEmoji;
  final int moodColor;

  const Song({
    required this.trackName,
    required this.artistName,
    required this.collectionName,
    required this.artworkUrl,
    required this.previewUrl,
    this.moodTitle = '',
    this.moodEmoji = '',
    this.moodColor = 0xFF95D5B2,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      trackName: json['trackName'] ?? '未知歌曲',
      artistName: json['artistName'] ?? '未知歌手',
      collectionName: json['collectionName'] ?? '未知專輯',
      artworkUrl: json['artworkUrl100'] ?? json['artworkUrl'] ?? '',
      previewUrl: json['previewUrl'] ?? '',
      moodTitle: json['moodTitle'] ?? '',
      moodEmoji: json['moodEmoji'] ?? '',
      moodColor: json['moodColor'] ?? 0xFF95D5B2,
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
      'moodTitle': moodTitle,
      'moodEmoji': moodEmoji,
      'moodColor': moodColor,
    };
  }
}
