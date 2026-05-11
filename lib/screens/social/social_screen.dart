import 'package:flutter/material.dart';
import 'package:velocity_math/services/social_service.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialService _service = SocialService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        SoundService().playSwitch();
      }
    });
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final results = await _service.searchUsers(query);
      setState(() => _searchResults = results);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOCIAL HUB'),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "FRIENDS"),
            Tab(icon: Icon(Icons.person_add), text: "REQUESTS"),
            Tab(icon: Icon(Icons.search), text: "FIND"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildRequestsTab(),
          _buildSearchTab(),
        ],
      ),
    );
  }

  // --- 1. FRIENDS TAB ---
  Widget _buildFriendsTab() {
    return StreamBuilder<List<String>>(
      stream: _service.getFriends(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Center(child: Text("No friends yet. Go find some!", style: TextStyle(color: Colors.grey)));

        return FutureBuilder<Map<String, Map<String, dynamic>>>(
          future: _service.getUsersDetails(snapshot.data!),
          builder: (context, userSnapshot) {
             if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
             final userDetailsMap = userSnapshot.data!;
             final friendUids = snapshot.data!;
             
             return ListView.builder(
               itemCount: friendUids.length,
               itemBuilder: (context, index) {
                 final uid = friendUids[index];
                 final user = userDetailsMap[uid];
                 final username = user != null ? user['username'] : "Unknown User";
                 
                 return ListTile(
                   leading: CircleAvatar(
                     backgroundColor: AppTheme.primary, 
                     child: Text(username[0].toUpperCase())
                   ),
                   title: Text(username, style: const TextStyle(color: AppTheme.text)),
                   subtitle: user == null ? Text("UID: $uid", style: const TextStyle(color: Colors.grey, fontSize: 10)) : null,
                   trailing: IconButton(
                     icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primary),
                     onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(friendUid: uid, friendName: username)));
                     },
                   ),
                 );
               },
             );
          },
        );
      },
    );
  }

  // --- 2. REQUESTS TAB ---
  Widget _buildRequestsTab() {
     return StreamBuilder<List<String>>(
      stream: _service.getFriendRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Center(child: Text("No pending requests.", style: TextStyle(color: Colors.grey)));

        return FutureBuilder<Map<String, Map<String, dynamic>>>(
          future: _service.getUsersDetails(snapshot.data!),
          builder: (context, userSnapshot) {
             // Show loading only if we have no data
             if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
             final userDetailsMap = userSnapshot.data!;
             final requestUids = snapshot.data!;
             
             return ListView.builder(
               itemCount: requestUids.length,
               itemBuilder: (context, index) {
                 final uid = requestUids[index];
                 final user = userDetailsMap[uid];
                 final username = user != null ? user['username'] : "Unknown User";
                 
                 return ListTile(
                   leading: const Icon(Icons.person_outline, color: Colors.orange),
                   title: Text("$username wants to be friends", style: const TextStyle(color: AppTheme.text)),
                   subtitle: user == null ? Text("UID: $uid", style: const TextStyle(color: Colors.grey, fontSize: 10)) : null,
                   trailing: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.primary,
                       foregroundColor: Colors.black, // Dark text for visibility
                     ),
                     onPressed: () async {
                       await _service.acceptFriendRequest(uid);
                       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend Added!")));
                     },
                     child: const Text("ACCEPT"),
                   ),
                 );
               },
             );
          },
        );
      },
    );
  }

  // --- 3. SEARCH TAB ---
  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: const InputDecoration(
                    hintText: "Search Username...",
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              IconButton(onPressed: _performSearch, icon: const Icon(Icons.arrow_forward, color: AppTheme.primary)),
            ],
          ),
        ),
        if (_isSearching) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final user = _searchResults[index];
              return ListTile(
                title: Text(user['username'], style: const TextStyle(color: AppTheme.text)),
                subtitle: Text(user['email'], style: const TextStyle(color: Colors.grey)),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add, color: AppTheme.primary),
                  onPressed: () async {
                    await _service.sendFriendRequest(user['uid']);
                     if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Sent!")));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
