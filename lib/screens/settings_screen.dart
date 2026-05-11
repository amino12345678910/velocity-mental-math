import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/social_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'admin/admin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with current name if possible, or leave empty to fetch? 
    // Ideally we fetch from SocialService or AuthProvider.
    // For now, let's leave blank or use a placeholder.
    // Actually, let's try to get it from context if AuthProvider has it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final auth = context.read<AuthProvider>();
       _usernameController.text = auth.username ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle(context, 'ACCOUNT'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: InputDecoration(
                    labelText: "Username",
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5))),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black, // Dark text on bright button
                ),
                onPressed: () async {
                   final newName = _usernameController.text.trim();
                   if (newName.isNotEmpty) {
                     await SocialService().updateUsername(newName);
                     if (mounted) {
                       context.read<AuthProvider>().updateLocalUsername(newName);
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username Saved!")));
                     }
                   }
                },
                child: const Text("SAVE"),
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (SocialService().isAdmin)
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("ADMIN DASHBOARD"),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                },
              ),
            ),
          
          const SizedBox(height: 32),
          
          _buildSectionTitle(context, 'SPEED (ms)'),
          Slider(
            value: settings.speedMs.toDouble(),
            min: 200,
            max: 2000,
            divisions: 18,
            activeColor: AppTheme.primary,
            label: '${settings.speedMs} ms',
            onChanged: (val) {
               settings.setSpeed(val.round());
            },
            onChangeEnd: (_) => SoundService().playSwitch(),
          ),
          Center(child: Text('${settings.speedMs} ms', style: const TextStyle(color: AppTheme.primary))),
          
          const SizedBox(height: 32),
          
          _buildSectionTitle(context, 'DIGIT COUNT'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [1, 2, 3].map((count) {
              final isSelected = settings.digits == count;
              return ChoiceChip(
                label: Text('$count', style: TextStyle(color: isSelected ? Colors.black : Colors.white)),
                selected: isSelected,
                selectedColor: AppTheme.primary,
                backgroundColor: AppTheme.surface,
                onSelected: (_) {
                  SoundService().playClick();
                  settings.setDigits(count);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          _buildSectionTitle(context, 'SEQUENCE LENGTH'),
          Slider(
            value: settings.sequenceLength.toDouble(),
            min: 3,
            max: 20,
            divisions: 17,
            activeColor: AppTheme.accent,
            label: '${settings.sequenceLength}',
            onChanged: (val) => settings.setSequenceLength(val.round()),
            onChangeEnd: (_) => SoundService().playSwitch(),
          ),
          Center(child: Text('${settings.sequenceLength} items', style: const TextStyle(color: AppTheme.accent))),
          
          const SizedBox(height: 48),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = FirebaseAuth.instance.currentUser;
              return Column(
                children: [
                   Text(
                     "Logged in as: ${auth.username ?? 'Guest'}",
                     style: const TextStyle(color: Colors.grey, fontSize: 10),
                   ),
                   if (user?.email != null)
                     Text(
                       "(${user!.email})",
                       style: const TextStyle(color: Colors.grey, fontSize: 10),
                     ),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.text.withOpacity(0.7),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
