import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study & Career Planning', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: [
              Tab(text: 'GATE CS 2027'),
              Tab(text: 'Semester Exams'),
              Tab(text: 'ExcelR Placement'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGateTab(),
            _buildSemesterTab(),
            _buildExcelRTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGateTab() {
    final subjects = [
      'Engineering Mathematics',
      'Discrete Mathematics',
      'Digital Logic',
      'Computer Organization & Architecture',
      'Programming & Data Structures',
      'Algorithms',
      'Theory of Computation',
      'Compiler Design',
      'Operating Systems',
      'Databases',
      'Computer Networks',
      'General Aptitude',
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primarySoft,
              child: Text('${index + 1}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
            title: Text(subjects[index], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Official 2027 CS Syllabus', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLight),
          ),
        );
      },
    );
  }

  Widget _buildSemesterTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (int i = 1; i <= 5; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subject S$i', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Exam: Dec 2026', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('5 Units Syllabus Coverage', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.2 * i,
                    backgroundColor: AppTheme.borderColor,
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExcelRTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Placement Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Text('• Monday–Friday: 17:00 – 20:00', style: TextStyle(fontSize: 13)),
                Text('• Saturday: 14:00 – 17:00', style: TextStyle(fontSize: 13)),
                Text('• Sunday: Training Holiday', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Readiness Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Text('• Resume & GitHub portfolio polish', style: TextStyle(fontSize: 13)),
                Text('• Technical coding practice (LeetCode / DSA)', style: TextStyle(fontSize: 13)),
                Text('• Mock interview preparation', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
