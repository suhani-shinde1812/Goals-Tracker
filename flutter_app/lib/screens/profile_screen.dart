import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primarySoft,
              child: Icon(Icons.person, size: 48, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'BloomTrack Wellness',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const Center(
            child: Text('user@bloomtrack.com', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
          const SizedBox(height: 24),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer_outlined, color: AppTheme.primaryColor),
                  title: const Text('Timezone'),
                  subtitle: const Text('Asia/Kolkata (IST)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bedtime_outlined, color: AppTheme.primaryColor),
                  title: const Text('Quiet Hours'),
                  subtitle: const Text('22:15 – 06:30'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.water_drop_outlined, color: AppTheme.primaryColor),
                  title: const Text('Daily Hydration Target'),
                  subtitle: const Text('2,200 ml'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.fitness_center_outlined, color: AppTheme.primaryColor),
                  title: const Text('Workout Preference'),
                  subtitle: const Text('Beginner Home Workouts'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.accentMint),
                  title: const Text('Notifications & Reminders'),
                  subtitle: const Text('Enabled (Quiet hours respected)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: AppTheme.accentBlue),
                  title: const Text('Export My Data'),
                  subtitle: const Text('JSON & CSV formats'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
