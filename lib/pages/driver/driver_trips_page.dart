import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/models/trip_model.dart'; // Make sure this import is correct based on your project
import 'package:yazdrive/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DriverTripsPage extends StatefulWidget {
  const DriverTripsPage({super.key});

  @override
  State<DriverTripsPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverTripsPage> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final tripService = context.watch<TripService>();
    final userService = context.watch<UserService>();
    final user = userService.currentUser;

    if (user == null) return const SizedBox();

    final allTrips = tripService.trips; // Assuming all trips are loaded
    // Filter trips for the current driver
    final myTrips = allTrips.where((t) => t.driverId == user.id || t.status == TripStatus.assigned).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => tripService.loadTrips(),
          ),
        ],
      ),
      body: Column(
        children: [
          _TripFilterChips(
            selectedFilter: _selectedFilter,
            onFilterSelected: (filter) => setState(() => _selectedFilter = filter),
            trips: myTrips,
          ),
          Expanded(
            child: _FilteredTripList(
              filter: _selectedFilter,
              trips: myTrips,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripFilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;
  final List<TripModel> trips;

  const _TripFilterChips({
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.trips,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Scheduled', 'In Progress', 'Completed', 'Cancelled'];
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;
          final count = _getFilterCount(filter);
          
          return FilterChip(
            selected: isSelected,
            label: Text('$filter ($count)'),
            onSelected: (_) => onFilterSelected(filter),
            backgroundColor: AppColors.lightSurface,
            selectedColor: AppColors.primary.withOpacity(0.1),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.lightBorder,
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'All':
        return trips.length;
      case 'Scheduled':
        return trips.where((t) => t.status == TripStatus.scheduled || t.status == TripStatus.assigned).length;
      case 'In Progress':
        return trips.where((t) => t.status == TripStatus.enRoute || t.status == TripStatus.arrived || t.status == TripStatus.pickedUp).length;
      case 'Completed':
        return trips.where((t) => t.status == TripStatus.completed).length;
      case 'Cancelled':
        return trips.where((t) => t.status == TripStatus.cancelled || t.status == TripStatus.noShow).length;
      default:
        return 0;
    }
  }
}

class _FilteredTripList extends StatelessWidget {
  final String filter;
  final List<TripModel> trips;

  const _FilteredTripList({required this.filter, required this.trips});

  List<TripModel> get _filteredTrips {
    switch (filter) {
      case 'Scheduled':
        return trips.where((t) => t.status == TripStatus.scheduled || t.status == TripStatus.assigned).toList();
      case 'In Progress':
        return trips.where((t) => t.status == TripStatus.enRoute || t.status == TripStatus.arrived || t.status == TripStatus.pickedUp).toList();
      case 'Completed':
        return trips.where((t) => t.status == TripStatus.completed).toList();
      case 'Cancelled':
        return trips.where((t) => t.status == TripStatus.cancelled || t.status == TripStatus.noShow).toList();
      default: // All
        return trips;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTrips;
    
    // Sort: Active/Scheduled by time (ascending), Completed/Cancelled by time (descending)
    filtered.sort((a, b) {
      if (filter == 'Completed' || filter == 'Cancelled') {
        return b.scheduledPickupTime.compareTo(a.scheduledPickupTime);
      }
      return a.scheduledPickupTime.compareTo(b.scheduledPickupTime);
    });

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              'No trips found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _TripCard(trip: filtered[index]);
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;

  const _TripCard({required this.trip});

  Color _getStatusColor() {
    switch (trip.status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return AppColors.info;
      case TripStatus.enRoute:
        return AppColors.warning;
      case TripStatus.arrived:
        return Colors.orange;
      case TripStatus.pickedUp:
        return AppColors.success;
      case TripStatus.completed:
        return Colors.grey;
      case TripStatus.cancelled:
      case TripStatus.noShow:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final timeFormat = DateFormat('MMM d, h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/driver/trip/${trip.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trip.status.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    timeFormat.format(trip.scheduledPickupTime),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.trip_origin, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.pickupAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.dropoffAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
