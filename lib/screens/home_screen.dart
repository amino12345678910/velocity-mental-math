import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/social_service.dart';
import '../services/sound_service.dart';

import 'game_screen.dart';
import 'settings_screen.dart';
import 'multiplayer/lobby_screen.dart';
import 'social/social_screen.dart';
import 'admin/admin_screen.dart';
import 'premium_screen.dart';
import 'leaderboard_screen.dart';

import '../components/ticket_indicator.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final highScore = context.select((GameProvider p) => p.highScore);
    final username = context.select((AuthProvider p) => p.username);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.shield_outlined, color: AppTheme.primary), 
          onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: AnimatedBackground(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(SocialService().currentUserId).snapshots(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final int tickets = userData['tickets'] ?? 0;
            final bool isPremium = userData['isPremium'] == true;
            
            if (snapshot.hasData) {
               SocialService().checkAndRegenerateTickets(SocialService().currentUserId);
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ticket Header
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                      child: TicketIndicator(userData: userData)
                          .animate().slideY(begin: -2, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Title Logo
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'VELOCITY\nMATH',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 56,
                          height: 0.9,
                          shadows: [
                            BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 20),
                          ],
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(period: 5.seconds))
                    .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.3)),

                    const SizedBox(height: 16),
                    
                    if (username != null)
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Welcome, $username', 
                          style: const TextStyle(color: Colors.white70, fontSize: 16)
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 24),
                    
                    // High Score
                     Column(
                        children: [
                          const Text('HIGH SCORE', style: TextStyle(color: AppTheme.primary, letterSpacing: 3, fontSize: 12)),
                          Text(
                            '$highScore', 
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
                          ),
                        ],
                      ).animate().scale(delay: 400.ms),

                    const SizedBox(height: 48),

                    // Main Actions
                    NeonButton(
                      text: 'START GAME',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GameScreen()),
                        );
                      },
                      isPrimary: true,
                    ).animate().slideY(begin: 1, delay: 500.ms).fadeIn(),

                    const SizedBox(height: 24),

                    NeonButton(
                      text: (tickets > 0 || isPremium) ? 'ONLINE DUEL' : 'NO TICKETS',
                      color: AppTheme.secondary,
                      isPrimary: false,
                      onPressed: (tickets > 0 || isPremium) 
                        ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LobbyScreen()))
                        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                    ).animate().slideY(begin: 1, delay: 600.ms).fadeIn(),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMiniButton(
                          icon: Icons.settings, 
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))
                        ),
                        const SizedBox(width: 24),
                        _buildMiniButton(
                          icon: Icons.leaderboard, 
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))
                        ),
                        const SizedBox(width: 24),
                        _buildMiniButton(
                          icon: Icons.people, 
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialScreen()))
                        ),
                      ],
                    ).animate().slideY(begin: 1, delay: 700.ms).fadeIn(),

                    const SizedBox(height: 24),
                    
                    // Debug Info (Hidden/Subtle)
                     Opacity(
                       opacity: 0.3,
                       child: Text(
                         "v2.0 • ${FirebaseAuth.instance.currentUser?.email ?? 'Guest'}",
                         style: const TextStyle(fontSize: 10, color: Colors.white),
                       ),
                     ),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildMiniButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.5),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70),
        onPressed: () {
          SoundService().playClick();
          onPressed();
        },
      ),
    );
  }
}
