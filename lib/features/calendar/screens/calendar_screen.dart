import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/data/providers/premium_shared_providers.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/fab_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/calendar_event_list_sliver.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_form_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/calendar_grid.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/calendar_header.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/day_events_sheet.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_detail_modal.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_form_sheet.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/calendar_week_view.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/calendar_day_view.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart'; // Cross-feature import: banding action for calendar events linked to chicks
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_bell_button.dart'; // Cross-feature import: app-shell AppBar widget shared across all main screens
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_button.dart'; // Cross-feature import: app-shell AppBar widget shared across all main screens
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

part 'calendar_screen_bodies.dart';

/// Main calendar screen with month grid and selected day events.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    // IMPROVED: keep realtime subscription alive for cross-device sync
    ref.watch(eventRealtimeSyncProvider(userId));
    final eventsAsync = ref.watch(eventsStreamProvider(userId));
    final displayedMonth = ref.watch(displayedMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final eventsMap = ref.watch(eventsForMonthProvider(displayedMonth));
    final selectedEvents = ref.watch(eventsForSelectedDateProvider);
    final viewMode = ref.watch(calendarViewProvider);
    final weekEvents = ref.watch(eventsForWeekProvider);

    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(
          title: 'calendar.title'.tr(),
          iconAsset: AppIcons.calendar,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calendarCheck),
            onPressed: _goToToday,
            tooltip: 'calendar.today'.tr(),
          ),
          const NotificationBellButton(),
          const ProfileMenuButton(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppSpacing.xxxl + AppSpacing.lg),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: SegmentedButton<CalendarViewMode>(
                      segments: [
                        ButtonSegment(
                          value: CalendarViewMode.month,
                          label: Text('calendar.month_view'.tr()),
                          icon: const AppIcon(AppIcons.calendar, size: 18),
                        ),
                        ButtonSegment(
                          value: CalendarViewMode.week,
                          label: Text('calendar.week_view'.tr()),
                          icon: const Icon(LucideIcons.columns, size: 18),
                        ),
                        ButtonSegment(
                          value: CalendarViewMode.day,
                          label: Text('calendar.day_view'.tr()),
                          icon: const Icon(LucideIcons.layoutList, size: 18),
                        ),
                      ],
                      selected: {viewMode},
                      onSelectionChanged: (s) {
                        AppHaptics.selectionClick();
                        ref
                            .read(calendarViewProvider.notifier)
                            .setViewMode(s.first);
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Center(
            child: AdBannerWidget(
              isPremiumProvider: isPremiumProvider,
              adBannerLoader: () => defaultAdBannerLoader(ref),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) => _onSwipe(details, viewMode),
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(eventsStreamProvider(userId));
                },
                child: eventsAsync.when(
                  loading: () =>
                      const LoadingState(),
                  error: (error, _) => ErrorState(
                    message: 'calendar.load_error'.tr(),
                    onRetry: () => ref.invalidate(eventsStreamProvider(userId)),
                  ),
                  data: (_) => switch (viewMode) {
                    CalendarViewMode.month => _CalendarBody(
                      displayedMonth: displayedMonth,
                      selectedDate: selectedDate,
                      eventsMap: eventsMap,
                      selectedEvents: selectedEvents,
                      onDateSelected: (date) => _selectDate(date),
                      onDateLongPress: (date) => _showDaySheet(
                        date,
                        eventsMap[DateTime(date.year, date.month, date.day)] ??
                            [],
                      ),
                      onEventTap: (event) => _showEventDetail(event),
                      onEditEvent: (event) =>
                          showEventFormSheet(context, existingEvent: event),
                      onDeleteEvent: (event) => _confirmDelete(event),
                    ),
                    CalendarViewMode.week => _WeekBody(
                      selectedDate: selectedDate,
                      weekEvents: weekEvents,
                      selectedEvents: selectedEvents,
                      onDateSelected: (date) => _selectDate(date),
                      onEventTap: (event) => _showEventDetail(event),
                      onEditEvent: (event) =>
                          showEventFormSheet(context, existingEvent: event),
                      onDeleteEvent: (event) => _confirmDelete(event),
                    ),
                    CalendarViewMode.day => CalendarDayView(
                      selectedDate: selectedDate,
                      events: selectedEvents,
                      onEventTap: (event) => _showEventDetail(event),
                      onEditEvent: (event) =>
                          showEventFormSheet(context, existingEvent: event),
                      onDeleteEvent: (event) => _confirmDelete(event),
                    ),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FabButton(
        icon: const AppIcon(AppIcons.add),
        tooltip: 'calendar.add_event'.tr(),
        onPressed: () => showEventFormSheet(context, initialDate: selectedDate),
      ),
    );
  }

  void _selectDate(DateTime date) {
    ref.read(selectedDateProvider.notifier).state = date;
  }

  void _goToToday() {
    final now = DateTime.now();
    ref.read(displayedMonthProvider.notifier).state = DateTime(
      now.year,
      now.month,
    );
    ref.read(selectedDateProvider.notifier).state = now;
  }

  /// Swipe to navigate months (month view) or weeks (week view).
  void _onSwipe(DragEndDetails details, CalendarViewMode viewMode) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return; // Ignore slow swipes

    final delta = velocity < 0 ? 1 : -1; // Left swipe → next, right → prev
    AppHaptics.lightImpact();

    if (viewMode == CalendarViewMode.month) {
      _changeMonth(delta);
    } else if (viewMode == CalendarViewMode.week) {
      _changeWeek(delta);
    } else {
      _changeDay(delta);
    }
  }

  void _changeMonth(int delta) {
    final current = ref.read(displayedMonthProvider);
    ref.read(displayedMonthProvider.notifier).state = DateTime(
      current.year,
      current.month + delta,
    );
  }

  void _changeWeek(int delta) {
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state = current.add(
      Duration(days: 7 * delta),
    );
  }

  void _changeDay(int delta) {
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state = current.add(
      Duration(days: delta),
    );
  }

  void _showDaySheet(DateTime date, List<Event> events) {
    showDayEventsSheet(context, date: date, events: events);
  }

  void _showEventDetail(Event event) {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) {
      _openEventDetail(event);
      return;
    }
    ref
        .read(adServiceProvider)
        .showInterstitialAd(
          onAdClosed: () {
            if (mounted) _openEventDetail(event);
          },
        );
  }

  void _openEventDetail(Event event) {
    // IMPROVED: pass banding callback to decouple modal from chicks feature
    showEventDetailModal(
      context,
      event: event,
      onEdit: () => showEventFormSheet(context, existingEvent: event),
      onDelete: () => _confirmDelete(event),
      onStatusChange: (status) => _changeEventStatus(event.id, status),
      onBandingComplete: event.chickId != null
          ? () => ref
                .read(bandingActionProvider.notifier)
                .markBandingComplete(event.chickId!)
          : null,
    );
  }

  void _changeEventStatus(String eventId, EventStatus status) {
    ref
        .read(eventFormStateProvider.notifier)
        .updateEventStatus(eventId, status);
  }

  Future<void> _confirmDelete(Event event) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'calendar.delete_event'.tr(),
      message: 'calendar.delete_event_confirm'.tr(),
      isDestructive: true,
    );
    if (!mounted) return;
    if (confirmed == true) {
      ref.read(eventFormStateProvider.notifier).deleteEvent(event.id);
    }
  }
}
