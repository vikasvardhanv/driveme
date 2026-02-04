import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/theme.dart';

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

    final allTrips = tripService.trips;
    final myTrips = allTrips.where((t) => t.driverId == user.id || t.status == TripStatus.assigned).toList();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Trips',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.lightBorder, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => tripService.loadTrips(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _TripFilterChips(
              selectedFilter: _selectedFilter,
              onFilterSelected: (filter) => setState(() => _selectedFilter = filter),
              trips: myTrips,
            ),
          ),
          Expanded(
            child: myTrips.isEmpty
                ? _EmptyState()
                : _FilteredTripList(
                    filter: _selectedFilter,
                    trips: myTrips,
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            'No trips assigned yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your scheduled trips will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textTertiary,
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
    final filters = ['All', 'Scheduled', 'Active', 'Done', 'Cancelled'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;
          final count = _getFilterCount(filter);
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => onFilterSelected(filter),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.lightBorder,
                  ),
                  boxShadow: isSelected 
                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                      : null,
                ),
                child: Row(
                  children: [
                    Text(
                      filter,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                     const SizedBox(width: 6),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: isSelected ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                         borderRadius: BorderRadius.circular(10),
                       ),
                       child: Text(
                         '$count',
                         style: GoogleFonts.inter(
                           fontSize: 12,
                           fontWeight: FontWeight.w700,
                           color: isSelected ? Colors.white : AppColors.textSecondary,
                         ),
                       ),
                     ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'All': return trips.length;
      case 'Scheduled': return trips.where((t) => t.status == TripStatus.scheduled || t.status == TripStatus.assigned).length;
      case 'Active': return trips.where((t) => t.status == TripStatus.enRoute || t.status == TripStatus.arrived || t.status == TripStatus.pickedUp).length;
      case 'Done': return trips.where((t) => t.status == TripStatus.completed).length;
      case 'Cancelled': return trips.where((t) => t.status == TripStatus.cancelled || t.status == TripStatus.noShow).length;
      default: return 0;
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
      case 'Active':
        return trips.where((t) => t.status == TripStatus.enRoute || t.status == TripStatus.arrived || t.status == TripStatus.pickedUp).toList();
      case 'Done':
        return trips.where((t) => t.status == TripStatus.completed).toList();
      case 'Cancelled':
        return trips.where((t) => t.status == TripStatus.cancelled || t.status == TripStatus.noShow).toList();
      default: return trips;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTrips;
    
    filtered.sort((a, b) {
      if (filter == 'Done' || filter == 'Cancelled') {
        return b.scheduledPickupTime.compareTo(a.scheduledPickupTime);
      }
      return a.scheduledPickupTime.compareTo(b.scheduledPickupTime);
    });

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              'No $filter trips found',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d');
    final isUpcoming = trip.scheduledPickupTime.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/driver/trip/${trip.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStatusColor().withOpacity(0.2)),
                      ),
                      child: Text(
                        trip.status.toString().split('.').last.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(trip.scheduledPickupTime),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time_rounded, size: 14, color: AppColors.textPrimary),
                    const SizedBox(width: 4),
                    Text(
                      timeFormat.format(trip.scheduledPickupTime),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.lightBorder),
                ),

                // Pickup
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.circle, size: 12, color: AppColors.primary),
                        Container(width: 2, height: 28, color: AppColors.lightBorder),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PICKUP', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(trip.pickupAddress, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Dropoff
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 12, color: AppColors.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DROPOFF', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(trip.dropoffAddress, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),

                // Footer Info
                if (trip.notes != null || trip.wheelchairRequired) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (trip.wheelchairRequired)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.accessible_forward, size: 16, color: AppColors.textSecondary),
                        ),
                      if (trip.notes != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.notes, size: 16, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trip.notes!, 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (trip.status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return AppColors.info;
      case TripStatus.enRoute:
      case TripStatus.arrived:
      case TripStatus.pickedUp:
        return AppColors.primary;
      case TripStatus.completed:
        return AppColors.success;
      case TripStatus.cancelled:
      case TripStatus.noShow:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
