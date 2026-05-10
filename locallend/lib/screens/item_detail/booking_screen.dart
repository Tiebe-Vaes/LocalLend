import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/booking.dart';
import '../../providers/providers.dart';
import '../../services/notification_service.dart';
import '../../widgets/primary_button.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.itemId});
  final String itemId;
  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _start;
  DateTime? _end;
  Set<String> _blocked = {};
  bool _loading = true;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _loadBlocked();
  }

  Future<void> _loadBlocked() async {
    final booked = await ref
        .read(bookingRepositoryProvider)
        .bookedDayKeysForItem(widget.itemId);
    if (mounted) {
      setState(() {
        _blocked = booked;
        _loading = false;
      });
    }
  }

  List<DateTime> _selectedDays() {
    if (_start == null) return const [];
    final s = _start!;
    final e = _end ?? _start!;
    final out = <DateTime>[];
    for (var d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
      out.add(d);
    }
    return out;
  }

  bool _rangeHasBlocked(DateTime s, DateTime e) {
    for (var d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
      if (_blocked.contains(dayKey(d))) return true;
    }
    return false;
  }

  void _onTapDay(DateTime day) {
    final today = dayOnly(DateTime.now());
    if (day.isBefore(today)) return;
    if (_blocked.contains(dayKey(day))) return;

    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else {
        if (day.isBefore(_start!)) {
          _start = day;
          _end = null;
        } else {
          if (_rangeHasBlocked(_start!, day)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Range overlaps a booked day. Pick another.')),
            );
            _start = day;
            _end = null;
          } else {
            _end = day;
          }
        }
      }
    });
  }

  Future<void> _place() async {
    final days = _selectedDays();
    if (days.isEmpty) return;
    final me = ref.read(appUserProvider).value;
    final item =
        await ref.read(itemRepositoryProvider).fetchItem(widget.itemId);
    if (me == null || item == null) return;
    setState(() => _placing = true);
    try {
      final booking = Booking(
        id: '',
        itemId: item.id,
        itemTitle: item.title,
        ownerId: item.ownerId,
        renterId: me.id,
        renterName: me.displayName,
        days: days,
        totalPrice: days.length * item.pricePerDay,
        status: BookingStatus.upcoming,
        createdAt: DateTime.now(),
      );
      final saved =
          await ref.read(bookingRepositoryProvider).createBooking(booking);
      await NotificationService.instance.scheduleRentalEndingSoon(
        id: saved.id.hashCode,
        itemTitle: item.title,
        lastDay: booking.lastDay,
      );
      if (mounted) _showSuccess(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Booking confirmed 🎉'),
        content: const Text(
            'Your reservation has been placed. Payment is mocked for this demo.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/dashboard');
            },
            child: const Text('Go to dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(itemProvider(widget.itemId)).value;
    final days = _daysInMonth(_month);
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final selectedDays = _selectedDays();
    final totalPrice = selectedDays.length * (item?.pricePerDay ?? 0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Pick rental dates'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _start == null
                          ? 'Tap a day to start. Tap a second day for a range, or rent a single day.'
                          : _end == null
                              ? 'Start: ${_fmt(_start!)} — tap an end day, or place order for 1 day.'
                              : '${_fmt(_start!)}  →  ${_fmt(_end!)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _month =
                            DateTime(_month.year, _month.month - 1)),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _monthLabel(_month),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _month =
                            DateTime(_month.year, _month.month + 1)),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                        .map((d) => Expanded(
                              child: Center(
                                child: Text(d,
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: days.length + (firstWeekday - 1),
                      itemBuilder: (_, i) {
                        if (i < firstWeekday - 1) {
                          return const SizedBox.shrink();
                        }
                        final day = days[i - (firstWeekday - 1)];
                        return _buildDayCell(day);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text('${selectedDays.length} day(s)'),
                        const Spacer(),
                        Text('€${totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Place order',
                    loading: _placing,
                    onPressed: selectedDays.isEmpty ? null : _place,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDayCell(DateTime day) {
    final today = dayOnly(DateTime.now());
    final isPast = dayOnly(day).isBefore(today);
    final isBlocked = _blocked.contains(dayKey(day)) || isPast;

    final s = _start;
    final e = _end ?? _start;
    final inRange = s != null &&
        e != null &&
        !day.isBefore(dayOnly(s)) &&
        !day.isAfter(dayOnly(e));
    final isStart = s != null && dayOnly(day) == dayOnly(s);
    final isEnd = e != null && dayOnly(day) == dayOnly(e);

    Color bg;
    Color fg;
    if (isBlocked) {
      bg = AppColors.background;
      fg = AppColors.textMuted;
    } else if (inRange) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else {
      bg = AppColors.surface;
      fg = AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: isBlocked ? null : () => _onTapDay(day),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: (isStart || isEnd)
                ? AppColors.primaryDark
                : (inRange ? AppColors.primary : AppColors.border),
            width: (isStart || isEnd) ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: fg,
              decoration: isBlocked ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  List<DateTime> _daysInMonth(DateTime m) {
    final last = DateTime(m.year, m.month + 1, 0).day;
    return [for (var i = 1; i <= last; i++) DateTime(m.year, m.month, i)];
  }

  String _monthLabel(DateTime m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[m.month - 1]} ${m.year}';
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month.toString().padLeft(2, '0')}';
}
