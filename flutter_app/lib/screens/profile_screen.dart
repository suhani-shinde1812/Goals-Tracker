import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../providers/dashboard_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showMonthlyReportDialog() async {
    final report = await ApiService.generateMonthlyReportText();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Progress Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: SelectableText(
                  report,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: report));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report copied to clipboard! Ready to paste or save.')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy / Export Report to Clipboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ApiService.isLoggedIn;
    final displayName = ApiService.userName ?? 'BloomTrack Wellness';
    final displayEmail = ApiService.userEmail ?? 'user@bloomtrack.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Account', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primarySoft,
              child: const Icon(Icons.person, size: 48, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Center(
            child: Text(displayEmail, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
          const SizedBox(height: 16),

          // Account Management Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/auth');
                },
                icon: const Icon(Icons.account_circle, size: 18),
                label: Text(isLoggedIn ? 'Switch / Create Account' : 'Sign In / Register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (isLoggedIn) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ApiService.logout();
                    ref.refresh(dashboardProvider);
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out')),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                  label: const Text('Log Out', style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.timer_outlined, color: AppTheme.primaryColor),
                  title: Text('Timezone'),
                  subtitle: Text('Asia/Kolkata (IST)'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.bedtime_outlined, color: AppTheme.primaryColor),
                  title: Text('Quiet Hours'),
                  subtitle: Text('22:15 – 06:30'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.water_drop_outlined, color: AppTheme.primaryColor),
                  title: Text('Daily Hydration Target'),
                  subtitle: Text('2,200 ml'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.fitness_center_outlined, color: AppTheme.primaryColor),
                  title: Text('Workout Preference'),
                  subtitle: Text('Beginner Home Workouts'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                  title: const Text('Download Monthly Progress Report'),
                  subtitle: const Text('Tasks, weight, hydration & PCOD tracking summary'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: _showMonthlyReportDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.accentMint),
                  title: const Text('Notifications & Reminders'),
                  subtitle: const Text('Enabled (Quiet hours respected)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined, color: AppTheme.accentBlue),
                  title: const Text('Cloud Sync Status'),
                  subtitle: Text(isLoggedIn ? 'Active and persistent on device' : 'Local mode active'),
                  trailing: Icon(
                    isLoggedIn ? Icons.check_circle : Icons.offline_bolt,
                    color: isLoggedIn ? Colors.green : Colors.orange,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
