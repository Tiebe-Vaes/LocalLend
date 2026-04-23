import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../widgets/section_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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

class _BookingTile extends ConsumerWidget {
  const _BookingTile({required this.booking});
  final Booking booking;

  void _showCancelConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
            'Are you sure you want to cancel your booking for "${booking.itemTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref.read(bookingRepositoryProvider).cancel(booking.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking cancelled')),
              );
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

class _ListingTile extends ConsumerWidget {
  const _ListingTile({required this.item});
  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
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
            icon: const Icon(Icons.chevron_right),
            onPressed: () => context.push('/item/${item.id}'),
          ),
        ],
      ),
    );
  }
}
