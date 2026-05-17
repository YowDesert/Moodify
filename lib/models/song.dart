class Song {
  final String trackName;
  final String artistName;
  final String collectionName;
  final String artworkUrl;
  final String previewUrl;

  const Song({
    required this.trackName,
    required this.artistName,
    required this.collectionName,
    required this.artworkUrl,
    required this.previewUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      trackName: json['trackName'] ?? '未知歌曲',
      artistName: json['artistName'] ?? '未知歌手',
      collectionName: json['collectionName'] ?? '未知專輯',
      artworkUrl: json['artworkUrl100'] ?? json['artworkUrl'] ?? '',
      previewUrl: json['previewUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trackName': trackName,
      'artistName': artistName,
      'collectionName': collectionName,
      'artworkUrl': artworkUrl,
      'previewUrl': previewUrl,
    };
  }
}
