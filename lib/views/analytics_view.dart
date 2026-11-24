import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../models/study_session.dart';
import '../services/study_tracker_service.dart';
import '../theme/app_theme.dart';
import '../widgets/card_3d.dart';

class AnalyticsView extends StatefulWidget {
  final AppData data;
  final Future<void> Function() onChange;

  const AnalyticsView({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;

  int _selectedFilterTab = 0; // 0 = Daily (Today), 1 = Weekly (7 Days), 2 = Monthly (30 Days)
  final TextEditingController _sessionTitleCtrl = TextEditingController(text: 'Deep Study & Focus');
  String _selectedCategory = 'study';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Auto-update daily streak on open
    widget.data.autoCheckInToday();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _sessionTitleCtrl.dispose();
    super.dispose();
  }

  // --- CALCULATIONS FOR DAILY, WEEKLY & MONTHLY ---

  List<StudySession> _getFilteredSessions(int tab) {
    final now = DateTime.now();
    if (tab == 0) {
      // Daily (Today)
      final startOfDay = DateTime(now.year, now.month, now.day);
      return widget.data.studySessions.where((s) => s.startTime.isAfter(startOfDay)).toList();
    } else if (tab == 1) {
      // Weekly (Last 7 Days)
      final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      return widget.data.studySessions.where((s) => s.startTime.isAfter(sevenDaysAgo)).toList();
    } else {
      // Monthly (Last 30 Days)
      final thirtyDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
      return widget.data.studySessions.where((s) => s.startTime.isAfter(thirtyDaysAgo)).toList();
    }
  }

  int _calculateTotalMinutes(List<StudySession> sessions) {
    return sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  // Calculate 7-day breakdown for weekly chart
  List<double> _calculateWeeklyDayHours() {
    final now = DateTime.now();
    final List<double> dayHours = List.filled(7, 0.0);
    final currentWeekDay = now.weekday; // 1 = Mon, 7 = Sun

    for (int idx = 0; idx < 7; idx++) {
      final dayOffset = idx + 1 - currentWeekDay;
      final targetDate = now.add(Duration(days: dayOffset));
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final sessions = widget.data.studySessions.where((s) {
        return s.startTime.isAfter(startOfDay) && s.startTime.isBefore(endOfDay);
      });

      int mins = sessions.fold(0, (sum, s) => sum + s.durationMinutes);
      dayHours[idx] = mins / 60.0;
    }
    return dayHours;
  }

  Future<void> _handleStopSession() async {
    final session = StudyTrackerService.stopAndSave();
    if (session != null) {
      setState(() {
        widget.data.studySessions = [session, ...widget.data.studySessions];
      });
      await widget.onChange();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('🎉 Focus Session Logged! ${session.durationMinutes} mins added to study history.'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredSessions = _getFilteredSessions(_selectedFilterTab);
    final totalMinutes = _calculateTotalMinutes(filteredSessions);
    final totalHoursStr = (totalMinutes / 60.0).toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 🔥 AUTO STREAK & HABIT BANNER
        _buildAutoStreakHeader(isDark),
        const SizedBox(height: 12),

        // ⏱️ LIVE STUDY / FOCUS STOPWATCH TRACKER
        _buildLiveFocusStopwatchCard(isDark),
        const SizedBox(height: 14),

        // 📊 STUDY TIME ESTIMATES & ANALYTICS (DAILY / WEEKLY / MONTHLY)
        _buildTimeAnalyticsSection(isDark, filteredSessions, totalMinutes, totalHoursStr),
        const SizedBox(height: 14),

        // 💡 SMART AI STUDY INSIGHTS
        _buildAiRecommendationsCard(isDark),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildAutoStreakHeader(bool isDark) {
    return TiltCard3D(
      maxTiltAngle: 0.04,
      glowColor: const Color(0xFFFF6B00),
      borderRadius: BorderRadius.circular(16),
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF241408), const Color(0xFF131B2A)]
                : [const Color(0xFFFFF7ED), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseScale,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9F1C), Color(0xFFFF3366)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5722).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${widget.data.currentStreak} DAYS STREAK',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFFF6B00)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'AUTO-SYNCED ✅',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Best Record: ${widget.data.bestStreak} Days Streak 🏆',
                          style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildWeekDayStrip(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveFocusStopwatchCard(bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: StudyTrackerService.isRunningNotifier,
      builder: (ctx, isRunning, _) {
        return TiltCard3D(
          maxTiltAngle: 0.05,
          glowColor: isRunning ? const Color(0xFF10B981) : const Color(0xFF0284C7),
          borderRadius: BorderRadius.circular(18),
          margin: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        isRunning ? const Color(0xFF062419) : const Color(0xFF0C192E),
                        const Color(0xFF111827),
                      ]
                    : [
                        isRunning ? const Color(0xFFF0FDF4) : const Color(0xFFF0F9FF),
                        Colors.white,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isRunning
                    ? const Color(0xFF10B981).withValues(alpha: 0.6)
                    : const Color(0xFF0284C7).withValues(alpha: 0.35),
                width: isRunning ? 1.6 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: isRunning
                                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                  : [const Color(0xFF0284C7), const Color(0xFF00D2FF)],
                            ),
                          ),
                          child: Icon(
                            isRunning ? Icons.timer_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRunning ? 'Live Study Session Active' : 'Start Study / Focus Timer',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isRunning ? 'Tracking exact time live in real-time...' : 'Tap Start to log study duration',
                              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isRunning)
                      ScaleTransition(
                        scale: _pulseScale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                              SizedBox(width: 4),
                              Text('REC', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Large Stopwatch Display
                ValueListenableBuilder<int>(
                  valueListenable: StudyTrackerService.elapsedSecondsNotifier,
                  builder: (ctx, elapsedSec, _) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0B1120) : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isRunning
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          StudyTrackerService.formatDuration(elapsedSec),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            fontFamily: 'monospace',
                            color: isRunning ? const Color(0xFF10B981) : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Activity Category Chips
                if (!isRunning) ...[
                  TextField(
                    controller: _sessionTitleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Study Subject / Topic',
                      hintText: 'e.g. Python AI, Networking, Exam Revision',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildCategoryChip('study', '📚 Study & Classes', const Color(0xFF3B82F6)),
                      _buildCategoryChip('coding', '💻 Coding & Project', const Color(0xFF10B981)),
                      _buildCategoryChip('reading', '📖 Reading & Notes', const Color(0xFF8B5CF6)),
                      _buildCategoryChip('practice', '🎯 Practice Lab', const Color(0xFFF59E0B)),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Action Controls (Start / Pause / Stop)
                Row(
                  children: [
                    if (!isRunning)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: const Text('Start Live Study Timer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          onPressed: () {
                            StudyTrackerService.start(
                              title: _sessionTitleCtrl.text.trim().isEmpty ? 'Deep Study & Focus' : _sessionTitleCtrl.text.trim(),
                              category: _selectedCategory,
                            );
                            setState(() {});
                          },
                        ),
                      )
                    else ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.stop_rounded, size: 22),
                          label: const Text('Stop & Log Study Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          onPressed: _handleStopSession,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String catKey, String label, Color color) {
    final isSelected = _selectedCategory == catKey;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = catKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeAnalyticsSection(
    bool isDark,
    List<StudySession> sessions,
    int totalMinutes,
    String totalHoursStr,
  ) {
    final weeklyDayHours = _calculateWeeklyDayHours();

    return TiltCard3D(
      maxTiltAngle: 0.04,
      glowColor: const Color(0xFF3B82F6),
      borderRadius: BorderRadius.circular(16),
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics_rounded, color: Color(0xFF3B82F6), size: 20),
                    SizedBox(width: 8),
                    Text('Study Time Estimation & History', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$totalHoursStr Hours Logged',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3B82F6), fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Tabs (Daily | Weekly | Monthly)
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _buildTabOption(0, '📅 Daily (Today)'),
                  _buildTabOption(1, '📊 Weekly (7-Days)'),
                  _buildTabOption(2, '📈 Monthly (30-Days)'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tab-specific Breakdown
            if (_selectedFilterTab == 0) ...[
              // Daily View
              Row(
                children: [
                  Expanded(
                    child: _buildMetricMiniCard('Today Focus Time', '$totalHoursStr hrs', '${totalMinutes}m logged', const Color(0xFF3B82F6)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricMiniCard(
                      'Daily Goal',
                      '${(widget.data.dailyStudyGoalMinutes / 60).toStringAsFixed(1)} hrs',
                      '${((totalMinutes / widget.data.dailyStudyGoalMinutes) * 100).clamp(0, 200).toStringAsFixed(0)}% reached',
                      const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ] else if (_selectedFilterTab == 1) ...[
              // Weekly 7-Day Visual Bar Chart
              _buildWeeklyBarChart(isDark, weeklyDayHours),
            ] else ...[
              // Monthly View
              Row(
                children: [
                  Expanded(
                    child: _buildMetricMiniCard('Monthly Focus', '$totalHoursStr hrs', '${sessions.length} sessions', const Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricMiniCard(
                      'Avg Daily Study',
                      '${(totalMinutes / 30.0 / 60.0).toStringAsFixed(1)} h/day',
                      'Consistent flow',
                      const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // Logged Sessions List
            const Text('Recent Study Logs', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'No sessions logged for this period yet. Start a live timer above!',
                    style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...sessions.take(4).map((s) => _buildSessionLogItem(s, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabOption(int tabIdx, String title) {
    final isSelected = _selectedFilterTab == tabIdx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterTab = tabIdx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricMiniCard(String title, String val, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          Text(sub, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(bool isDark, List<double> dayHours) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxH = dayHours.fold<double>(4.0, (max, h) => h > max ? h : max);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final h = dayHours[i];
          final fillPercent = (h / maxH).clamp(0.08, 1.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${h.toStringAsFixed(1)}h',
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                width: 22,
                height: 56 * fillPercent,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: h > 0
                        ? [const Color(0xFF3B82F6), const Color(0xFF00D2FF)]
                        : [Colors.grey.shade400, Colors.grey.shade600],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                days[i],
                style: TextStyle(
                  fontSize: 10.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSessionLogItem(StudySession s, bool isDark) {
    Color catColor = const Color(0xFF3B82F6);
    IconData catIcon = Icons.school_rounded;

    if (s.category == 'coding') {
      catColor = const Color(0xFF10B981);
      catIcon = Icons.code_rounded;
    } else if (s.category == 'reading') {
      catColor = const Color(0xFF8B5CF6);
      catIcon = Icons.book_rounded;
    } else if (s.category == 'practice') {
      catColor = const Color(0xFFF59E0B);
      catIcon = Icons.fitness_center_rounded;
    }

    final startHHMM = '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}';
    final dateStr = '${s.startTime.day}/${s.startTime.month}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Icon(catIcon, color: catColor, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text('$dateStr at $startHHMM', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(
              '${s.durationMinutes} mins',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: catColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiRecommendationsCard(bool isDark) {
    return TiltCard3D(
      maxTiltAngle: 0.04,
      glowColor: const Color(0xFF8B5CF6),
      borderRadius: BorderRadius.circular(16),
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 18),
                SizedBox(width: 8),
                Text('AI Study & Habit Recommendations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            _buildAiBullet('🔥 Auto-Streak System', 'App open karte hi streak auto-increment ho jata hai aur consistency track hoti hai.'),
            const SizedBox(height: 6),
            _buildAiBullet('⏱️ Focus Stopwatch', 'Study ya coding shuru karne se pehle timer start karein aur session ke baad Stop karein taake exact hours log hon.'),
            const SizedBox(height: 6),
            _buildAiBullet('🎯 3-Hour Daily Goal', 'Weekly consistency maintain karne ke liye roozana 3 hours deep study ka target pura karein.'),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBullet(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.arrow_right_rounded, size: 18, color: Color(0xFF8B5CF6)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 11.5, height: 1.4, color: Theme.of(context).textTheme.bodyMedium?.color),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDayStrip() {
    final now = DateTime.now();
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final currentWeekDay = now.weekday;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (idx) {
        final dayOffset = idx + 1 - currentWeekDay;
        final targetDate = now.add(Duration(days: dayOffset));
        final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        final isCompleted = widget.data.completedDates.contains(dateStr);
        final isToday = idx + 1 == currentWeekDay;

        return Column(
          children: [
            Text(
              weekDays[idx],
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? const Color(0xFFFF6B00) : null,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : isToday
                        ? const Color(0xFFFF6B00).withValues(alpha: 0.15)
                        : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : isToday
                          ? const Color(0xFFFF6B00)
                          : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        targetDate.day.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? const Color(0xFFFF6B00) : null,
                        ),
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
