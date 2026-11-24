import 'package:flutter/material.dart';

class TimePicker12HDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;

  const TimePicker12HDialog({
    super.key,
    required this.initialTime,
    this.title = 'Select Time (AM / PM)',
  });

  static Future<TimeOfDay?> show(BuildContext context, {TimeOfDay? initialTime, String title = 'Select Time (AM / PM)'}) {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) => TimePicker12HDialog(
        initialTime: initialTime ?? TimeOfDay.now(),
        title: title,
      ),
    );
  }

  @override
  State<TimePicker12HDialog> createState() => _TimePicker12HDialogState();
}

class _TimePicker12HDialogState extends State<TimePicker12HDialog> {
  late int _selectedHour12;
  late int _selectedMinute;
  late bool _isAm;

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour;
    _isAm = h < 12;
    var h12 = h % 12;
    if (h12 == 0) h12 = 12;
    _selectedHour12 = h12;
    _selectedMinute = widget.initialTime.minute;
  }

  TimeOfDay _getCurrentTimeOfDay() {
    var h24 = _selectedHour12 % 12;
    if (!_isAm) h24 += 12;
    return TimeOfDay(hour: h24, minute: _selectedMinute);
  }

  void _applyPreset(int hour24, int minute) {
    setState(() {
      _isAm = hour24 < 12;
      var h12 = hour24 % 12;
      if (h12 == 0) h12 = 12;
      _selectedHour12 = h12;
      _selectedMinute = minute;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF131B2A) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Large 12H Time Display with AM/PM pill
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hour Box
                    _buildValueBox(
                      value: _selectedHour12.toString().padLeft(2, '0'),
                      label: 'Hour (1-12)',
                      primary: primary,
                      isDark: isDark,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ),
                    // Minute Box
                    _buildValueBox(
                      value: _selectedMinute.toString().padLeft(2, '0'),
                      label: 'Minutes (00-59)',
                      primary: primary,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 14),
                    // AM / PM Segment Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAmPmButton('AM', _isAm, primary),
                          _buildAmPmButton('PM', !_isAm, const Color(0xFFEC4899)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Hour Selection Chips (1 - 12)
              const Text('Select Hour:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: List.generate(12, (index) {
                  final h = index + 1;
                  final isSelected = _selectedHour12 == h;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedHour12 = h),
                    child: Container(
                      width: 44,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$h',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // Minute Quick Chips
              const Text('Select Minutes:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55].map((m) {
                  final isSelected = _selectedMinute == m;
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _selectedMinute = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.9)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        m.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Quick Presets
              const Text('Quick Presets:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('🌅 Morning 07:00 AM', 7, 0),
                    const SizedBox(width: 6),
                    _buildPresetChip('☀️ Class 10:00 AM', 10, 0),
                    const SizedBox(width: 6),
                    _buildPresetChip('🍽️ Lunch 01:00 PM', 13, 0),
                    const SizedBox(width: 6),
                    _buildPresetChip('💻 Lab 04:00 PM', 16, 0),
                    const SizedBox(width: 6),
                    _buildPresetChip('🌆 Study 08:00 PM', 20, 0),
                    const SizedBox(width: 6),
                    _buildPresetChip('🌙 Night 11:30 PM', 23, 30),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _getCurrentTimeOfDay(),
                        builder: (ctx, child) => MediaQuery(
                          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
                          child: child!,
                        ),
                      );
                      if (t != null) {
                        _applyPreset(t.hour, t.minute);
                      }
                    },
                    icon: const Icon(Icons.access_time, size: 16),
                    label: const Text('Clock Picker', style: TextStyle(fontSize: 12)),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(_getCurrentTimeOfDay());
                    },
                    child: const Text('Set Time', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueBox({
    required String value,
    required String label,
    required Color primary,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary.withValues(alpha: 0.5)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAmPmButton(String label, bool isSelected, Color activeColor) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() => _isAm = label == 'AM');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int hour24, int minute) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      onPressed: () => _applyPreset(hour24, minute),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}
