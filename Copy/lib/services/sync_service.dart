import '../services/favorite_service.dart';
import '../services/firebase_favorite_service.dart';
import '../services/mood_history_service.dart';
import '../services/firebase_mood_history_service.dart';

class SyncService {
  final FavoriteService _localFavoriteService = FavoriteService();
  final FirebaseFavoriteService _firebaseFavoriteService =
      FirebaseFavoriteService();

  final MoodHistoryService _localMoodHistoryService = MoodHistoryService();
  final FirebaseMoodHistoryService _firebaseMoodHistoryService =
      FirebaseMoodHistoryService();

  Future<void> syncLocalDataToFirebase() async {
    await _syncFavoriteSongs();
    await _syncMoodHistory();
  }

  Future<void> _syncFavoriteSongs() async {
    final localSongs = await _localFavoriteService.getFavoriteSongs();

    for (final song in localSongs) {
      await _firebaseFavoriteService.addFavoriteSong(song);
    }
  }

  Future<void> _syncMoodHistory() async {
    final localRecords = await _localMoodHistoryService.getMoodRecords();

    for (final record in localRecords) {
      await _firebaseMoodHistoryService.addMoodRecordMap(record);
    }
  }
}
