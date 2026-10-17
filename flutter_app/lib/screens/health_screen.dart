import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final Map<int, bool> _completedWorkouts = {};

  final List<Map<String, dynamic>> _workouts = [
    {
      'id': 1,
      'name': 'Brisk Morning Walk & Daylight',
      'category': 'Cardio & Sunlight',
      'duration': '30 mins',
      'desc': 'Gentle outdoor walk to absorb morning sunlight, wake up circadian rhythms, and elevate heart rate.',
    },
    {
      'id': 2,
      'name': 'Beginner Chair Squats',
      'category': 'Lower Body Strength',
      'duration': '10 mins',
      'desc': 'Sit back to lightly touch chair and stand up. Keep knees aligned over feet. 3 sets of 10-12 reps.',
    },
    {
      'id': 3,
      'name': 'Wall Push-ups',
      'category': 'Upper Body',
      'duration': '8 mins',
      'desc': 'Stand 2 feet from wall, palms flat. Lower chest toward wall and press back. 3 sets of 10 reps.',
    },
    {
      'id': 4,
      'name': 'Glute Bridges (Mat/Floor)',
      'category': 'Core & Glutes',
      'duration': '10 mins',
      'desc': 'Lie on back with knees bent, feet flat. Lift hips until thighs and torso align. 3 sets of 12 reps.',
    },
    {
      'id': 5,
      'name': 'Gentle Evening Post-Dinner Walk',
      'category': 'Digestive Movement',
      'duration': '15 mins',
      'desc': 'Light stroll at easy pace after dinner to encourage gastric motility and prevent acid reflux/bloating.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health, PCOD & Workouts', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Educational Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8E0D4)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'PCOD Wellness Advisory: Because cycles with PCOD often vary (occurring every 2–3 months), standard 28-day predictions are omitted. Consult your healthcare clinician if an interval exceeds 90 days.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF2B4C3F), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Health Context Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Personal Health Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
                    const SizedBox(height: 12),
                    _buildInfoRow('Height', '5 ft 4 in (162.6 cm)'),
                    _buildInfoRow('Current Weight', '66.0 kg (Target: 56.0 kg)'),
                    _buildInfoRow('Cycle Pattern', 'Irregular (approx 2–3 months)'),
                    _buildInfoRow('Digestion Context', 'Prone to bloating, gas, constipation'),
                    _buildInfoRow('Previous Hemoglobin', '11.4 g/dL (Historical entry)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gut Health Reminders
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Gut Health & Digestion Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
                    SizedBox(height: 8),
                    Text('• Chew meals thoroughly (20–30 times per bite) to reduce air ingestion.', style: TextStyle(fontSize: 13, height: 1.4)),
                    SizedBox(height: 4),
                    Text('• 15-minute gentle walk after dinner supports natural gut motility.', style: TextStyle(fontSize: 13, height: 1.4)),
                    SizedBox(height: 4),
                    Text('• Maintain 2.2L daily water intake spaced between meals (not during big bites).', style: TextStyle(fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Home Workouts
            const Text(
              'Beginner Home Workouts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
            ),
            const SizedBox(height: 10),

            for (var w in _workouts) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              w['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              w['duration'],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        w['desc'],
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _completedWorkouts[w['id']] = !(_completedWorkouts[w['id']] ?? false);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_completedWorkouts[w['id']] == true ? '${w['name']} logged for today!' : 'Workout uncompleted'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(
                            _completedWorkouts[w['id']] == true ? Icons.check_circle : Icons.fitness_center,
                            color: _completedWorkouts[w['id']] == true ? Colors.green : AppTheme.primaryColor,
                            size: 18,
                          ),
                          label: Text(
                            _completedWorkouts[w['id']] == true ? 'Completed Today' : 'Mark Completed Today',
                            style: TextStyle(
                              color: _completedWorkouts[w['id']] == true ? Colors.green : AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMain)),
        ],
      ),
    );
  }
}
