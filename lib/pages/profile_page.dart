import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  Future<void> _signIn() async {
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google 登入失敗：$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          backgroundColor: const Color(0xFFF3FBF6),
          appBar: AppBar(
            title: const Text('我的'),
            backgroundColor: const Color(0xFFF3FBF6),
            foregroundColor: const Color(0xFF1F5C49),
            elevation: 0,
            actions: [
              if (user != null)
                IconButton(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(22),
            child: user == null ? _buildLoginCard() : _buildUserCard(user),
          ),
        );
      },
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE1F0E8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_circle_rounded,
            size: 80,
            color: Color(0xFF2E7D62),
          ),
          const SizedBox(height: 18),
          const Text(
            '登入 Moodify',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F5C49),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '使用 Google 登入後，之後可以同步收藏歌曲與心情紀錄。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF6D8B7D),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _signIn,
              icon: const Icon(Icons.login_rounded),
              label: const Text(
                '使用 Google 登入',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D62),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE1F0E8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 42,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: Color(0xFF2E7D62),
                  )
                : null,
          ),
          const SizedBox(height: 18),
          Text(
            user.displayName ?? 'Moodify 使用者',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F5C49),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email ?? '',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6D8B7D)),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('登出'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D62),
                side: const BorderSide(color: Color(0xFF2E7D62)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
