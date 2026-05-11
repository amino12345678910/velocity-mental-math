import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velocity_math/services/social_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialService _service = SocialService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.isAdmin) {
       return const Scaffold(body: Center(child: Text("ACCESS DENIED")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("ADMIN DASHBOARD"),
        backgroundColor: Colors.red[900], // Admin color
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "USERS"),
            Tab(icon: Icon(Icons.games), text: "MATCHES"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildMatchesTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Username', style: TextStyle(color: AppTheme.primary))),
                DataColumn(label: Text('Email', style: TextStyle(color: AppTheme.primary))),
                DataColumn(label: Text('UID', style: TextStyle(color: AppTheme.primary))),
                DataColumn(label: Text('Created', style: TextStyle(color: AppTheme.primary))),
              ],
              rows: users.map((user) {
                DateTime created = DateTime.now();
                if (user['createdAt'] is Timestamp) {
                  created = (user['createdAt'] as Timestamp).toDate();
                }
                    
                return DataRow(cells: [
                  DataCell(Text(user['username'] ?? "N/A", style: const TextStyle(color: Colors.white))),
                  DataCell(Text(user['email'] ?? "N/A", style: const TextStyle(color: Colors.white))),
                  DataCell(Text((user['uid'] ?? "").substring(0, 8) + "...", style: const TextStyle(color: Colors.grey))),
                  DataCell(Text(DateFormat('MM/dd HH:mm').format(created), style: const TextStyle(color: Colors.grey))),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getActiveMatches(),
      builder: (context, snapshot) {
         if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
         final matches = snapshot.data!;

         if (matches.isEmpty) return const Center(child: Text("No active matches", style: TextStyle(color: Colors.grey)));

         return ListView.builder(
           itemCount: matches.length,
           itemBuilder: (context, index) {
             final match = matches[index];
             final p1 = match['player1'];
             final p2 = match['player2'];
             final p1Name = p1 != null ? p1['name'] : "Unknown";
             final p2Name = p2 != null ? p2['name'] : "Waiting...";

             return Card(
               color: Colors.grey[900],
               margin: const EdgeInsets.all(8),
               child: ListTile(
                 title: Text("$p1Name vs $p2Name", style: const TextStyle(color: AppTheme.primary)),
                 subtitle: Text("Status: ${match['status']} | ID: ${match['matchId']}", style: const TextStyle(color: Colors.grey)),
                 trailing: IconButton(
                   icon: const Icon(Icons.stop_circle, color: Colors.red),
                   onPressed: () async {
                      await _service.forceEndMatch(match['matchId']);
                      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match Terminated")));
                   },
                 ),
               ),
             );
           },
         );
      },
    );
  }
}
