import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & PCOD Wellness', style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Personal Health Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

            // Digestive Health Recommendations
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gut Health Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('• Chew meals slowly (20-30 times per bite) to reduce air ingestion.', style: TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 4),
                    const Text('• 15-minute gentle walk after dinner supports natural gut motility.', style: TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 4),
                    const Text('• Maintain 2.2L daily water intake spaced between meals.', style: TextStyle(fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ),
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
