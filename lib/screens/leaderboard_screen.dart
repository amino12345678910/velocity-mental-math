import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:velocity_math/services/social_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text("LEADERBOARD"),
          bottom: const TabBar(
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(text: "GLOBAL"),
              Tab(text: "FRIENDS"), // Placeholder for now or future impl
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.background, Color(0xFF0F0F1E)],
            ),
          ),
          child: TabBarView(
            children: [
              _buildGlobalLeaderboard(),
              const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SocialService().getMonthlyLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: AppTheme.error)));
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text("No rankings yet this month!", style: TextStyle(color: Colors.grey)));
        }

        final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 60;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final int points = user['points'] ?? 0;
            final String rank = SocialService().getRank(points);
            final bool isTop3 = index < 3;
            
            return GlassContainer(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank Number
                  Container(
                     width: 40,
                     height: 40,
                     alignment: Alignment.center,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: isTop3 ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
                       border: isTop3 ? Border.all(color: AppTheme.primary) : null,
                     ),
                     child: Text(
                       "#${index + 1}",
                       style: TextStyle(
                         color: isTop3 ? AppTheme.primary : Colors.grey,
                         fontWeight: FontWeight.bold,
                         fontSize: 18,
                       ),
                     ),
                  ),
                  const SizedBox(width: 16),
                  
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['username'] ?? 'Unknown',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildRankBadge(rank),
                            const SizedBox(width: 8),
                            Text("$points pts", style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Wins
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("WINS", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text("${user['wins'] ?? 0}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.5, delay: (index * 50).ms).fadeIn();
          },
        );
      },
    );
  }

  Widget _buildRankBadge(String rank) {
    Color color;
    switch (rank) {
      case 'Diamond': color = Colors.cyanAccent; break;
      case 'Gold': color = Colors.amber; break;
      case 'Silver': color = Colors.grey.shade300; break;
      case 'Bronze': color = Colors.brown.shade300; break;
      default: color = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(rank.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
