import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../widgets/section_header.dart';

/// Personal dashboard: my rentals (as renter) and my listings (as owner).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// Asks the user to confirm before wiping and re-seeding the database.
  Future<void> _confirmReseed(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reseed demo data?'),
        content: const Text(
            'This deletes ALL items, bookings and reviews, then restores the demo dataset. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reseed',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Reseeding…')),
    );
    try {
      await ref.read(seedServiceProvider).reseedAll();
      messenger.showSnackBar(
        const SnackBar(content: Text('Reseed complete')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Reseed failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(appUserProvider).value;
    if (me == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final rentals = ref.watch(bookingsAsRenterProvider(me.id));
    final listings = ref.watch(itemsByOwnerProvider(me.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Reseed demo data',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => _confirmReseed(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader('My rentals'),
          const SizedBox(height: 8),
          rentals.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) {
              debugPrint('Rentals error: $e');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text('Error loading rentals',
                        style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.refresh(bookingsAsRenterProvider(me.id)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
            data: (list) {
              if (list.isEmpty) {
                return const Text('No rentals yet.',
                    style: TextStyle(color: AppColors.textMuted));
              }
              final grouped = _groupByStatus(list);
              return Column(
                children: [
                  for (final s in BookingStatus.values)
                    if (grouped[s]?.isNotEmpty ?? false) ...[
                      _StatusLabel(status: s),
                      for (final b in grouped[s]!)
                        _BookingTile(booking: b),
                    ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader('My listings'),
          const SizedBox(height: 8),
          listings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) {
              debugPrint('Listings error: $e');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text('Error loading listings',
                        style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.refresh(itemsByOwnerProvider(me.id)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
            data: (items) {
              if (items.isEmpty) {
                return const Text('You have no listings yet.',
                    style: TextStyle(color: AppColors.textMuted));
              }
              return Column(
                children: items.map((i) => _ListingTile(item: i)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Buckets bookings by their *computed* live status for display.
  Map<BookingStatus, List<Booking>> _groupByStatus(List<Booking> list) {
    final now = DateTime.now();
    final map = <BookingStatus, List<Booking>>{
      BookingStatus.active: [],
      BookingStatus.upcoming: [],
      BookingStatus.past: [],
      BookingStatus.cancelled: [],
    };
    for (final b in list) {
      final s = b.computeStatus(now);
      map[s]!.add(b);
    }
    return map;
  }
}

/// Section header showing one booking status as a label.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      BookingStatus.active => 'Active',
      BookingStatus.upcoming => 'Upcoming',
      BookingStatus.past => 'Past',
      BookingStatus.cancelled => 'Cancelled',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.textMuted)),
    );
  }
}

/// One row in the rentals list with a contextual cancel button.
class _BookingTile extends ConsumerWidget {
  const _BookingTile({required this.booking});
  final Booking booking;

  /// Confirms then cancels the booking, surfacing the result via a snackbar.
  void _showCancelConfirm(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(bookingRepositoryProvider);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
            'Are you sure you want to cancel your booking for "${booking.itemTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await repo.cancel(booking.id);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Booking cancelled')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Cancel failed: $e')),
                );
              }
            },
            child: const Text('Cancel booking',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = DateFormat.MMMd();
    final canCancel = booking.status == BookingStatus.upcoming ||
        booking.status == BookingStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.itemTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      '${f.format(booking.firstDay)} – ${f.format(booking.lastDay)} · ${booking.days.length} day(s)',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text('€${booking.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => context.push('/item/${booking.itemId}'),
              ),
            ],
          ),
          if (canCancel) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Cancel booking'),
                onPressed: () => _showCancelConfirm(context, ref),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One row in the listings list with an availability toggle.
class _ListingTile extends ConsumerWidget {
  const _ListingTile({required this.item});
  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsByItemProvider(item.id));
    final now = DateTime.now();
    final activeBookings = bookingsAsync.value
            ?.where((b) => b.computeStatus(now) == BookingStatus.active)
            .toList() ??
        const <Booking>[];
    final upcomingBookings = bookingsAsync.value
            ?.where((b) => b.computeStatus(now) == BookingStatus.upcoming)
            .toList() ??
        const <Booking>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      item.available ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        color: item.available
                            ? AppColors.success
                            : AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: item.available,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => ref
                    .read(itemRepositoryProvider)
                    .updateAvailability(item.id, v),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/item/${item.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => context.push('/item/${item.id}'),
              ),
            ],
          ),
          if (activeBookings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final b in activeBookings)
              _RentedOutBanner(booking: b, isActive: true),
          ],
          if (upcomingBookings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final b in upcomingBookings)
              _RentedOutBanner(booking: b, isActive: false),
          ],
        ],
      ),
    );
  }
}

/// Banner showing who has rented an owner's item and when, with a cancel action.
class _RentedOutBanner extends ConsumerWidget {
  const _RentedOutBanner({required this.booking, required this.isActive});
  final Booking booking;
  final bool isActive;

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(bookingRepositoryProvider);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel reservation?'),
        content: Text(
            'Cancel ${booking.renterName}\'s reservation for "${booking.itemTitle}"? They will see this in their dashboard as cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await repo.cancel(booking.id);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Reservation cancelled')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Cancel failed: $e')),
                );
              }
            },
            child: const Text('Cancel reservation',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = DateFormat.MMMd();
    final color = isActive ? AppColors.primary : AppColors.textMuted;
    final label = isActive ? 'Currently rented by' : 'Reserved by';
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isActive ? Icons.lock_clock : Icons.event,
                  size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$label ${booking.renterName} · ${f.format(booking.firstDay)} – ${f.format(booking.lastDay)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Cancel reservation'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onPressed: () => _confirmCancel(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
