import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood.dart';

class FirebaseMoodHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _user => _auth.currentUser;

  CollectionReference<Map<String, dynamic>>? get _historyRef {
    final user = _user;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('moodHistory');
  }

  Future<void> addMoodRecord(Mood mood) async {
    final ref = _historyRef;

    if (ref == null) {
      throw Exception('尚未登入，無法同步心情紀錄');
    }

    final now = DateTime.now();

    await ref.add({
      'title': mood.title,
      'emoji': mood.emoji,
      'keyword': mood.keyword,
      'color': mood.color.value,
      'date': '${now.year}/${now.month}/${now.day}',
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getMoodRecords() async {
    final ref = _historyRef;

    if (ref == null) {
      return [];
    }

    final snapshot = await ref.orderBy('createdAt', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'title': data['title'] ?? '未知心情',
        'emoji': data['emoji'] ?? '🌿',
        'keyword': data['keyword'] ?? '',
        'color': data['color'] ?? 0xFF95D5B2,
        'date': data['date'] ?? '',
        'time': data['time'] ?? '',
      };
    }).toList();
  }

  Future<void> clearHistory() async {
    final ref = _historyRef;

    if (ref == null) {
      return;
    }

    final snapshot = await ref.get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> addMoodRecordMap(Map<String, dynamic> record) async {
    final ref = _historyRef;

    if (ref == null) {
      throw Exception('尚未登入，無法同步心情紀錄');
    }

    await ref.add({
      'title': record['title'] ?? '未知心情',
      'emoji': record['emoji'] ?? '🌿',
      'keyword': record['keyword'] ?? '',
      'color': record['color'] ?? 0xFF95D5B2,
      'date': record['date'] ?? '',
      'time': record['time'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMoodRecord(Map<String, dynamic> record) async {
  final ref = _historyRef;

  if (ref == null) {
    return;
  }

  final id = record['id'];

  if (id == null || id.toString().isEmpty) {
    return;
  }

  await ref.doc(id).delete();
}

}
