import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../models/routine_block.dart';
import '../models/routine_template.dart';
import '../models/task_item.dart';
import '../services/time_utils.dart';
import '../theme/app_theme.dart';
import 'card_3d.dart';

class TemplatePickerDialog extends StatefulWidget {
  final AppData data;
  final Future<void> Function() onTemplateApplied;

  const TemplatePickerDialog({
    super.key,
    required this.data,
    required this.onTemplateApplied,
  });

  static Future<void> show(BuildContext context, {required AppData data, required Future<void> Function() onTemplateApplied}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TemplatePickerDialog(
        data: data,
        onTemplateApplied: onTemplateApplied,
      ),
    );
  }

  @override
  State<TemplatePickerDialog> createState() => _TemplatePickerDialogState();
}

class _TemplatePickerDialogState extends State<TemplatePickerDialog> {
  final customNameCtrl = TextEditingController();

  @override
  void dispose() {
    customNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyTemplate(RoutineTemplate tpl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apply "${tpl.title}"?'),
        content: Text(
          'This will replace your current timetable with "${tpl.title}" and automatically reschedule all alarms.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apply Template'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.data.blocks
        ..clear()
        ..addAll(tpl.blocks.map((b) => RoutineBlock(
              id: DateTime.now().millisecondsSinceEpoch.toString() + b.id,
              name: b.name,
              cat: b.cat,
              start: b.start,
              end: b.end,
              remind: b.remind,
            )));
      widget.data.tasks
        ..clear()
        ..addAll(tpl.tasks.map((t) => TaskItem(
              id: DateTime.now().millisecondsSinceEpoch.toString() + t.id,
              name: t.name,
              duration: t.duration,
              priority: t.priority,
              scheduled: t.scheduled,
              ss: t.ss,
              se: t.se,
              isCompleted: t.isCompleted,
            )));
      widget.data.practice = tpl.practice;
      widget.data.social = tpl.social;

      await widget.onTemplateApplied();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to "${tpl.title}"! Alarms & free time re-synced.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  Future<void> _saveCurrentAsTemplate() async {
    final name = customNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your custom template.')),
      );
      return;
    }

    final newTpl = RoutineTemplate(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: name,
      icon: '⭐',
      description: 'Custom saved routine with ${widget.data.blocks.length} blocks and ${widget.data.tasks.length} tasks.',
      blocks: widget.data.blocks.map((b) => RoutineBlock.fromJson(b.toJson())).toList(),
      tasks: widget.data.tasks.map((t) => TaskItem.fromJson(t.toJson())).toList(),
      practice: widget.data.practice,
      social: widget.data.social,
    );

    setState(() {
      widget.data.customTemplates = [...widget.data.customTemplates, newTpl];
    });
    customNameCtrl.clear();
    await widget.onTemplateApplied();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Custom template "$name" saved!')),
      );
    }
  }

  void _deleteCustomTemplate(String id) async {
    setState(() {
      widget.data.customTemplates = widget.data.customTemplates.where((t) => t.id != id).toList();
    });
    await widget.onTemplateApplied();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final builtIns = RoutineTemplate.builtInTemplates();
    final customs = widget.data.customTemplates;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Routine Templates & Modes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Switch your daily timetable in 1 click or save your current routine setup as a custom preset.',
              style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Built-in Templates Section
            const Text(
              'Pre-Built Templates',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            const SizedBox(height: 8),
            ...builtIns.map((tpl) => _buildTemplateCard(tpl, false)),

            // Custom Templates Section
            if (customs.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'My Saved Templates',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.secondary),
              ),
              const SizedBox(height: 8),
              ...customs.map((tpl) => _buildTemplateCard(tpl, true)),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),

            // Save Current as Template Section
            const Text(
              '💾 Save Current Routine as Custom Preset',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customNameCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g., Friday Routine, Gym Heavy Day',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                  label: const Text('Save'),
                  onPressed: _saveCurrentAsTemplate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(RoutineTemplate tpl, bool isCustom) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TiltCard3D(
        maxTiltAngle: 0.04,
        glowColor: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(tpl.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tpl.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          tpl.description,
                          style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (isCustom)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      tooltip: 'Delete custom template',
                      onPressed: () => _deleteCustomTemplate(tpl.id),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Routine Block Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tpl.blocks.map((b) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.getCategoryColor(b.cat).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.getCategoryColor(b.cat).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${b.name} (${hhmmStr12(b.start)})',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.getCategoryColor(b.cat)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Apply This Routine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => _applyTemplate(tpl),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
