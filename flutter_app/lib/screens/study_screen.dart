import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/study_model.dart';
import '../services/api_service.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<GateSubjectModel> _gateSubjects = [];
  List<SemesterSubjectModel> _semSubjects = [];
  bool _isLoading = true;

  // Placement training checklist state
  final Map<String, bool> _excelrChecklist = {
    'Resume & GitHub portfolio polish': true,
    'Technical coding practice (LeetCode / DSA)': false,
    'Aptitude & quantitative problem solving': false,
    'Mock technical interview preparation': false,
    'Database & SQL query revision': false,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final gate = await ApiService.getGateSubjects();
    final sem = await ApiService.getSemesterSubjects();
    if (mounted) {
      setState(() {
        _gateSubjects = gate;
        _semSubjects = sem;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeGateTopicStatus(GateTopicModel topic, String newStatus) async {
    await ApiService.updateGateTopicStatus(topic.id, newStatus);
    setState(() {
      _gateSubjects = _gateSubjects.map((s) {
        final updatedTopics = s.topics.map((t) {
          if (t.id == topic.id) {
            return t.copyWith(status: newStatus);
          }
          return t;
        }).toList();
        return GateSubjectModel(
          id: s.id,
          code: s.code,
          name: s.name,
          orderIndex: s.orderIndex,
          topics: updatedTopics,
        );
      }).toList();
    });
  }

  Future<void> _toggleSemesterUnit(SemesterUnitModel unit, bool isCompleted) async {
    await ApiService.toggleSemesterUnit(unit.id, isCompleted);
    setState(() {
      _semSubjects = _semSubjects.map((s) {
        final updatedUnits = s.units.map((u) {
          if (u.id == unit.id) {
            return u.copyWith(isCompleted: isCompleted);
          }
          return u;
        }).toList();
        return s.copyWith(units: updatedUnits);
      }).toList();
    });
  }

  void _showEditSubjectDialog(SemesterSubjectModel subject) {
    final controller = TextEditingController(text: subject.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${subject.code} Subject Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Subject Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await ApiService.renameSemesterSubject(subject.id, newName);
                setState(() {
                  _semSubjects = _semSubjects.map((s) {
                    if (s.id == subject.id) {
                      return s.copyWith(name: newName);
                    }
                    return s;
                  }).toList();
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study & Career Planning', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh syllabus',
              onPressed: _loadData,
            ),
          ],
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
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
    int totalTopics = 0;
    int completedTopics = 0;
    for (var s in _gateSubjects) {
      totalTopics += s.topics.length;
      completedTopics += s.topics.where((t) => t.status == 'Completed').length;
    }
    final pct = totalTopics > 0 ? ((completedTopics / totalTopics) * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Progress Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GATE CS 2027 Syllabus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
                  Text('$pct% Covered', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
                ],
              ),
              const SizedBox(height: 6),
              Text('$completedTopics of $totalTopics topics completed across 12 subjects', style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: totalTopics > 0 ? (completedTopics / totalTopics) : 0,
                backgroundColor: Colors.white.withOpacity(0.6),
                color: AppTheme.primaryColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Subjects Accordion
        for (var subject in _gateSubjects) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: subject.orderIndex == 0,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primarySoft,
                  child: Text(
                    subject.code,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
                title: Text(
                  subject.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  '${subject.topics.where((t) => t.status == "Completed").length}/${subject.topics.length} topics done',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                children: [
                  const Divider(height: 1),
                  for (var topic in subject.topics)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF0F4F2), width: 1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                topic.name,
                                style: const TextStyle(fontSize: 13, height: 1.3),
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            initialValue: topic.status,
                            onSelected: (newStatus) => _changeGateTopicStatus(topic, newStatus),
                            child: Chip(
                              label: Text(
                                topic.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(topic.status),
                                ),
                              ),
                              backgroundColor: _getStatusColor(topic.status).withOpacity(0.12),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'Not Started', child: Text('Not Started')),
                              const PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
                              const PopupMenuItem(value: 'Completed', child: Text('Completed')),
                              const PopupMenuItem(value: 'Needs Revision', child: Text('Needs Revision')),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade700;
      case 'In Progress':
        return Colors.blue.shade700;
      case 'Needs Revision':
        return Colors.orange.shade800;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildSemesterTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var subject in _semSubjects) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subject.code,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
                        tooltip: 'Rename Subject',
                        onPressed: () => _showEditSubjectDialog(subject),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subject.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Priority: ${subject.priority} • Difficulty: ${subject.difficulty}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const Divider(height: 20),
                  const Text('5 Units Checklist:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  for (var unit in subject.units)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: unit.isCompleted,
                      onChanged: (val) {
                        if (val != null) _toggleSemesterUnit(unit, val);
                      },
                      title: Text(
                        unit.title,
                        style: TextStyle(
                          fontSize: 13,
                          decoration: unit.isCompleted ? TextDecoration.lineThrough : null,
                          color: unit.isCompleted ? AppTheme.textLight : AppTheme.textMain,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExcelRTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('ExcelR Placement Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
                SizedBox(height: 10),
                Text('• Monday–Friday: 17:00 – 20:00 (Daily Interactive Sessions)', style: TextStyle(fontSize: 13, height: 1.4)),
                SizedBox(height: 4),
                Text('• Saturday: 14:00 – 17:00 (Weekend Workshop & Assessments)', style: TextStyle(fontSize: 13, height: 1.4)),
                SizedBox(height: 4),
                Text('• Sunday: Training Holiday (Catch-up & Mock practice)', style: TextStyle(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Placement Readiness Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
                const SizedBox(height: 8),
                for (var entry in _excelrChecklist.entries)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: entry.value,
                    onChanged: (val) {
                      setState(() {
                        _excelrChecklist[entry.key] = val ?? false;
                      });
                    },
                    title: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 13,
                        decoration: entry.value ? TextDecoration.lineThrough : null,
                        color: entry.value ? AppTheme.textLight : AppTheme.textMain,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
