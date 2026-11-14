import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/analytics.dart';
import 'package:shuffle_alarm/core/fallback_tone.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/design/components/bar_chart.dart';
import 'package:shuffle_alarm/design/components/glass_card.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/month_calendar.dart';
import 'package:shuffle_alarm/design/components/section_label.dart';
import 'package:shuffle_alarm/design/components/status_view.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/insights/analytics_texts.dart';
import 'package:shuffle_alarm/features/ringing/morning_card.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';
import 'package:shuffle_alarm/l10n/texts.dart';

/// What the ring log and the answers of the Morning card say. It is read
/// again after each ring and each answer, and when the tab opens.
final analyticsProvider = FutureProvider<Analytics>((ref) async {
  ref
    ..watch(ringingProvider)
    ..watch(snoozedRingsProvider)
    ..watch(morningCardProvider);
  final sessions = await ref.watch(ringSessionRepositoryProvider).all();
  final answers = await ref.watch(morningAnswerRepositoryProvider).all();
  return Analytics(sessions: sessions, answers: answers);
});

/// The Analytics tab (ADR-005, task 2.8): a calendar with a mark on each day
/// an alarm rang, and the figures of the day, week, month or year that holds
/// the chosen day.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  static const path = '/analytics';

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.week;

  /// The chosen day. Null for today.
  DateTime? _day;

  /// The month the calendar shows. Null for the month of the chosen day.
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(analyticsProvider);
    final today = dayOf(ref.watch(clockProvider));
    return TabPage(
      title: Text(tr.tabAnalytics),
      actions: const [SettingsButton()],
      body: switch (analytics) {
        AsyncData(:final value) when value.isEmpty => StatusView(
          icon: Icons.bar_chart,
          title: tr.noMorningsYet,
          message: tr.afterFirstAlarm,
        ),
        AsyncData(:final value) => _content(value, today),
        AsyncError() => StatusView(
          icon: Icons.bar_chart,
          title: tr.couldNotReadMornings,
          error: true,
          action: FilledButton(
            onPressed: () => ref.invalidate(analyticsProvider),
            child: Text(tr.tryAgain),
          ),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _content(Analytics analytics, DateTime today) {
    final day = _day ?? today;
    final month = _month ?? day;
    final shown = DateTime(month.year, month.month);
    final first = analytics.mornings.first.day;
    final summary = analytics.summary(_period, day);
    final calendar = _Calendar(
      analytics: analytics,
      month: shown,
      day: day,
      today: today,
      // No month before the first ring, and none after this one.
      onPrevious: shown.isAfter(DateTime(first.year, first.month))
          ? () => setState(() => _month = DateTime(shown.year, shown.month - 1))
          : null,
      onNext: shown.isBefore(DateTime(today.year, today.month))
          ? () => setState(() => _month = DateTime(shown.year, shown.month + 1))
          : null,
      onDaySelected: (number) => setState(() {
        _day = DateTime(shown.year, shown.month, number);
        _month = null;
      }),
    );
    final periods = _Periods(
      period: _period,
      onChanged: (period) => setState(() => _period = period),
    );
    final figures = _Figures(
      summary: summary,
      title: _periodTitle(context, _period, day),
    );
    final chart = _period == AnalyticsPeriod.day
        ? null
        : _Chart(
            period: _period,
            points: analytics.chart(_period, day),
            summary: summary,
          );
    final best = _Best(summary: summary);
    final mornings = _Mornings(
      day: day,
      mornings: analytics.of(AnalyticsPeriod.day, day),
    );
    if (Layout.isWide(context)) {
      return ContentWidth(
        wide: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ListView(
                padding: const EdgeInsets.only(bottom: Space.s24),
                children: [calendar, mornings],
              ),
            ),
            Expanded(
              flex: 6,
              child: ListView(
                padding: const EdgeInsets.only(bottom: Space.s24),
                children: [periods, figures, ?chart, best],
              ),
            ),
          ],
        ),
      );
    }
    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.only(bottom: Space.s24),
        children: [calendar, periods, figures, ?chart, best, mornings],
      ),
    );
  }
}

/// The name of the [period] that holds [day], such as "Nov 9 – Nov 15".
String _periodTitle(
  BuildContext context,
  AnalyticsPeriod period,
  DateTime day,
) {
  final localizations = MaterialLocalizations.of(context);
  final (start, end) = periodBounds(period, day);
  final last = DateTime(end.year, end.month, end.day - 1);
  return switch (period) {
    AnalyticsPeriod.day => localizations.formatMediumDate(start),
    AnalyticsPeriod.week =>
      '${localizations.formatShortMonthDay(start)} – '
          '${localizations.formatShortMonthDay(last)}',
    AnalyticsPeriod.month => localizations.formatMonthYear(start),
    AnalyticsPeriod.year => '${start.year}',
  };
}

/// The strength, from 1 to 3, that stands for [mark] in the design system.
int _strengthOf(DayMark mark) => mark.index + 1;

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.analytics,
    required this.month,
    required this.day,
    required this.today,
    required this.onPrevious,
    required this.onNext,
    required this.onDaySelected,
  });

  final Analytics analytics;
  final DateTime month;
  final DateTime day;
  final DateTime today;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onDaySelected;

  bool _inMonth(DateTime date) =>
      date.year == month.year && date.month == month.month;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final marks = {
      for (final MapEntry(key: date, value: mark) in analytics.marks.entries)
        if (_inMonth(date)) date.day: mark,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        Space.s8,
        Layout.gutter,
        Space.s12,
      ),
      child: GlassCard(
        radius: Corners.hero,
        padding: const EdgeInsets.fromLTRB(
          Space.s12,
          Space.s8,
          Space.s12,
          Space.s16,
        ),
        child: Column(
          children: [
            MonthCalendar(
              previousLabel: tr.previousMonth,
              nextLabel: tr.nextMonth,
              month: month,
              marks: {
                for (final MapEntry(:key, :value) in marks.entries)
                  key: _strengthOf(value),
              },
              selected: _inMonth(day) ? day.day : null,
              today: _inMonth(today) ? today.day : null,
              dayLabel: (number) {
                final date = DateTime(month.year, month.month, number);
                final mark = marks[number];
                return [
                  localizations.formatFullDate(date),
                  if (mark == null) tr.noAlarmThatDay else markName(mark),
                ].join(', ');
              },
              onDaySelected: onDaySelected,
              onPrevious: onPrevious,
              onNext: onNext,
            ),
            const SizedBox(height: Space.s12),
            const _Legend(),
          ],
        ),
      ),
    );
  }
}

/// What the three colors of the calendar mean.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: Wrap(
        spacing: Space.s16,
        runSpacing: Space.s4,
        alignment: WrapAlignment.center,
        children: [
          for (final mark in DayMark.values)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: c.strength(_strengthOf(mark))),
                const SizedBox(width: Space.s8),
                Text(
                  markName(mark),
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// The keys of the period: Day, Week, Month, Year.
class _Periods extends StatelessWidget {
  const _Periods({required this.period, required this.onChanged});

  final AnalyticsPeriod period;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        Space.s8,
        Layout.gutter,
        Space.s12,
      ),
      child: SegmentedButton<AnalyticsPeriod>(
        showSelectedIcon: false,
        segments: [
          for (final period in AnalyticsPeriod.values)
            ButtonSegment(value: period, label: Text(periodName(period))),
        ],
        selected: {period},
        onSelectionChanged: (periods) => onChanged(periods.single),
      ),
    );
  }
}

/// The figures of the period, as four tiles under its [title].
class _Figures extends StatelessWidget {
  const _Figures({required this.summary, required this.title});

  final AnalyticsSummary summary;
  final String title;

  @override
  Widget build(BuildContext context) {
    final average = summary.averageToStop;
    final tiles = [
      _Figure(
        label: tr.gotUp,
        value: '${summary.gotUp}',
        note: summary.missed == 0
            ? tr.noneMissed
            : tr.missedCount(summary.missed),
      ),
      _Figure(
        label: tr.alarmToStop,
        value: average == null ? '–' : spanText(average),
        note: tr.onAverage,
        semanticsValue: average == null ? tr.noStopYet : null,
      ),
      _Figure(label: tr.snoozes, value: '${summary.snoozes}'),
      _Figure(label: tr.soundsPlayed, value: '${summary.soundsPlayed}'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Layout.gutter,
            0,
            Layout.gutter,
            Space.s12,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Two in a row, or one where large text needs the width.
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final columns = constraints.maxWidth < 300 * scale ? 1 : 2;
              final width =
                  (constraints.maxWidth - Space.s12 * (columns - 1)) / columns;
              return Wrap(
                spacing: Space.s12,
                runSpacing: Space.s12,
                children: [
                  for (final tile in tiles) SizedBox(width: width, child: tile),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.note,
    this.semanticsValue,
  });

  final String label;
  final String value;
  final String? note;

  /// What screen readers say for [value], when it is a sign.
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = WakemixType.of(context);
    return GlassCard(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: type.caption),
            const SizedBox(height: Space.s4),
            // On one line: smaller where a long value needs it.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.headlineLarge,
                maxLines: 1,
                semanticsLabel: semanticsValue,
              ),
            ),
            if (note != null) Text(note!, style: type.meta),
          ],
        ),
      ),
    );
  }
}

/// The time from the alarm to Stop: per day of a week or a month, per month
/// of a year.
class _Chart extends StatelessWidget {
  const _Chart({
    required this.period,
    required this.points,
    required this.summary,
  });

  final AnalyticsPeriod period;
  final List<ChartPoint> points;
  final AnalyticsSummary summary;

  String _label(BuildContext context, ChartPoint point) {
    final localizations = MaterialLocalizations.of(context);
    final start = point.start;
    return switch (period) {
      AnalyticsPeriod.week =>
        localizations.narrowWeekdays[start.weekday % DateTime.daysPerWeek],
      // Every fifth day, so the numbers have room.
      AnalyticsPeriod.month =>
        start.day == 1 || start.day % 5 == 0 ? '${start.day}' : '',
      // "J", "F", "M", …
      _ => localizations.formatMonthYear(start).substring(0, 1),
    };
  }

  @override
  Widget build(BuildContext context) {
    final type = WakemixType.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        0,
        Layout.gutter,
        Space.s12,
      ),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Text(tr.alarmToStop, style: type.caption)),
            const SizedBox(height: Space.s12),
            BarChart(
              semanticsLabel: chartSummary(summary),
              bars: [
                for (final point in points)
                  ChartBar(
                    value: point.average?.inSeconds.toDouble(),
                    label: _label(context, point),
                    flagged: point.missed > 0,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Wakes you best": the sound named most often on the Morning card.
class _Best extends ConsumerWidget {
  const _Best({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final type = WakemixType.of(context);
    final id = summary.bestSoundId;
    final title = id == null ? null : _soundTitle(ref, id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        0,
        Layout.gutter,
        Space.s12,
      ),
      child: GlassCard(
        child: MergeSemantics(
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(Icons.wb_sunny_outlined, color: c.accentText),
              ),
              const SizedBox(width: Space.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.wakesYouBest, style: type.caption),
                    const SizedBox(height: Space.s4),
                    Text(
                      title ?? tr.notKnownYet,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      title == null
                          ? tr.answerMorningCard
                          : namedText(summary.bestSoundCount),
                      style: type.meta,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The title of the sound [id], or what to call a sound deleted since.
String _soundTitle(WidgetRef ref, String id) {
  if (id == fallbackTone.id) return tr.alarmTone;
  final stored = ref.watch(storedSoundsProvider).value ?? [];
  for (final sound in stored) {
    if (sound.sound.id == id) return sound.sound.title;
  }
  return tr.deletedSound;
}

/// What happened on the chosen [day], from the log.
class _Mornings extends ConsumerWidget {
  const _Mornings({required this.day, required this.mornings});

  final DateTime day;
  final List<LoggedMorning> mornings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final type = WakemixType.of(context);
    final localizations = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(localizations.formatFullDate(day)),
        if (mornings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Layout.gutter),
            child: Text(
              tr.noAlarmRang,
              style: theme.textTheme.bodyMedium!.copyWith(color: c.textMuted),
            ),
          ),
        for (final morning in mornings)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Layout.gutter,
              0,
              Layout.gutter,
              Space.s12,
            ),
            child: GlassCard(
              child: MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _Dot(color: c.strength(_strengthOf(morning.mark))),
                    ),
                    const SizedBox(width: Space.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _alarmText(context, morning),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: Space.s4),
                          Text(
                            morningLine(morning),
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: c.textMuted,
                            ),
                          ),
                          if (_sounds(ref, morning) case final sounds?)
                            Text(sounds, style: type.meta),
                          if (morning.wokeSoundId case final id?)
                            Text(
                              tr.wokeYou(_soundTitle(ref, id)),
                              style: type.meta,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// "7:00 AM alarm".
  String _alarmText(BuildContext context, LoggedMorning morning) {
    final time = TimeOfDay.fromDateTime(morning.session.scheduledFor.toLocal());
    return tr.alarmAt(time.format(context));
  }

  /// The sounds that played, in order, each once. Null when none did.
  String? _sounds(WidgetRef ref, LoggedMorning morning) {
    final ids = <String>{
      for (final event in morning.session.events)
        if (event.played) event.soundId,
    };
    if (ids.isEmpty) return null;
    return tr.playedSounds(ids.map((id) => _soundTitle(ref, id)).join(', '));
  }
}
