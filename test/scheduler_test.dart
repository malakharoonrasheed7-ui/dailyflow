import 'package:flutter_test/flutter_test.dart';
import 'package:dailyflow/models/routine_block.dart';
import 'package:dailyflow/services/scheduler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  test('timezone initialization', () {
    tzdata.initializeTimeZones();
    final now = DateTime.now();
    final offset = now.timeZoneOffset;

    tz.Location? matchedLocation;
    try {
      if (tz.timeZoneDatabase.locations.containsKey(now.timeZoneName)) {
        matchedLocation = tz.getLocation(now.timeZoneName);
      }
    } catch (_) {}

    if (matchedLocation == null) {
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offset.inMilliseconds) {
          matchedLocation = loc;
          break;
        }
      }
    }
    expect(matchedLocation != null, true);
  });

  test('adding and deleting a routine block updates free time gaps automatically', () {
    final blocks = <RoutineBlock>[
      RoutineBlock(id: 'class', name: 'Class', cat: 'class', start: '14:00', end: '16:00', remind: false),
    ];

    final gapBefore = Scheduler.freeGaps(blocks).first;
    expect(gapBefore['se'], 480);

    blocks.add(RoutineBlock(id: 'new', name: 'New routine', cat: 'class', start: '12:00', end: '14:00', remind: false));
    final gapAfterAdd = Scheduler.freeGaps(blocks).first;
    expect(gapAfterAdd['se'], 360);

    blocks.removeWhere((block) => block.id == 'new');
    final gapAfterDelete = Scheduler.freeGaps(blocks).first;
    expect(gapAfterDelete['se'], 480);
  });
}