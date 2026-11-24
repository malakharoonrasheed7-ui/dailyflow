import 'package:flutter/material.dart';
import '../models/schedule_segment.dart';
import '../services/time_utils.dart';
import '../theme/app_theme.dart';

class TimelineVisualizer extends StatelessWidget {
  final List<ScheduleSegment> segments;
  final Function(ScheduleSegment)? onSegmentTap;

  const TimelineVisualizer({
    super.key,
    required this.segments,
    this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentShifted = getCurrentShiftedMinutes();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.timeline_rounded, size: 18, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '24-Hour Day Flow',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Live Now indicator badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Now: ${hhmm12(unshiftMin(currentShifted))}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 24H Segmented Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 28,
              child: Stack(
                children: [
                  // Segments
                  Row(
                    children: segments.map((seg) {
                      final flex = (seg.se - seg.ss).clamp(1, 1440);
                      final color = AppTheme.getCategoryColor(seg.cat);
                      return Expanded(
                        flex: flex,
                        child: Tooltip(
                          message: '${seg.name}\n${hhmm12(unshiftMin(seg.ss))} – ${hhmm12(unshiftMin(seg.se))}',
                          child: InkWell(
                            onTap: () => onSegmentTap?.call(seg),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                              decoration: BoxDecoration(
                                color: seg.isOpen ? color.withValues(alpha: 0.3) : color,
                                border: seg.isOpen
                                    ? Border.all(color: color.withValues(alpha: 0.7), width: 1)
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: flex >= 70
                                  ? Text(
                                      seg.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: seg.isOpen ? color : Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Live NOW Cursor Needle
                  if (currentShifted >= 0 && currentShifted <= 1440)
                    Positioned(
                      left: (MediaQuery.of(context).size.width - 64) * (currentShifted / 1440.0),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: const [
                            BoxShadow(color: AppTheme.accent, blurRadius: 6, spreadRadius: 2),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Time Markers (06 AM, 12 PM, 06 PM, 12 AM, 06 AM)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('06 AM', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
              Text('12 PM', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
              Text('06 PM', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
              Text('12 AM', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
              Text('06 AM', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
