import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/vehicle_service.dart';
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/models/vehicle_model.dart';
import 'package:yazdrive/theme.dart';
import 'package:yazdrive/widgets/driver_drawer.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  bool _hasFetchedData = false;
  String _selectedFilter = 'all'; // Filter: 'all', 'scheduled', 'inProgress', 'completed', 'cancelled'
  
  // For custom scrolling/refresh behavior
  late ScrollController _scrollController;

  late UserService _userService; // Store reference

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Store reference to UserService for cleanup
    _userService = context.read<UserService>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripService = context.read<TripService>();
      
      tripService.loadTrips();
      _checkAndConnect();
      _userService.addListener(_checkAndConnect);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _userService.removeListener(_checkAndConnect);
    super.dispose();
  }

  void _checkAndConnect() {
    if (!mounted) return;
    
    final userService = context.read<UserService>();
    final tripService = context.read<TripService>();
    final currentUser = userService.currentUser;

    if (currentUser != null) {
      tripService.initializeSocketConnection(currentUser.id);
      
      if (!_hasFetchedData) {
        tripService.fetchTripsFromBackend(currentUser.id);
        _hasFetchedData = true;
      }
    }
  }

  void _startTakingTrips() {
    context.go('/driver/vehicle-confirmation');
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final tripService = context.watch<TripService>();
    final vehicleService = context.watch<VehicleService>();
    final currentUser = userService.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final todayTrips = tripService.getTodayTrips(currentUser.id);
    final upcomingTrips = tripService.getUpcomingTrips(currentUser.id);
    final completedToday = tripService.getCompletedTripsForToday(currentUser.id).length;
    
    TripModel? activeTrip;
    final activeTrips = tripService.trips.where((t) => 
      t.driverId == currentUser.id && 
      (t.status == TripStatus.enRoute || t.status == TripStatus.arrived || t.status == TripStatus.pickedUp)
    );
    if (activeTrips.isNotEmpty) activeTrip = activeTrips.first;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      drawer: const DriverDrawer(), // Add Drawer
      appBar: AppBar(
        title: Text('DASHBOARD', style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        centerTitle: true,
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh trips',
            onPressed: () => tripService.loadTrips(),
          ),
          // Logout moved to Drawer
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.lightSurface,
        onRefresh: () async {
          if (currentUser != null) {
            await tripService.fetchTripsFromBackend(currentUser.id);
          } else {
            await tripService.loadTrips();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DriverInfoCard(driver: currentUser),
              const SizedBox(height: 24),
              
              // Action Button (Primary Call to Action)
              _StartTakingTripsButton(
                onPressed: _startTakingTrips,
                tripsCount: todayTrips.length,
                selectedVehicle: vehicleService.selectedVehicle,
              ),
              
              const SizedBox(height: 24),
              
              // Stats Overview
              _StatsRow(
                todayCount: todayTrips.length,
                completedCount: completedToday,
                upcomingCount: upcomingTrips.length,
              ),
              
              const SizedBox(height: 32),
              
              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TRIP OVERVIEW', 
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)
                  ),
                  InkWell(
                    onTap: () {
                      // Filter toggle logic could go here if expand to proper sheet
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.filter_list_rounded, color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Filter Chips
              _TripFilterChips(
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
                tripService: tripService,
                driverId: currentUser.id,
              ),
              
              const SizedBox(height: 16),

              // Active Trip Card (Highlighted)
              if (activeTrip != null) ...[
                _ActiveTripCard(trip: activeTrip),
                const SizedBox(height: 24),
              ],
              
              // Trip List
              _FilteredTripList(
                selectedFilter: _selectedFilter,
                tripService: tripService,
                driverId: currentUser.id,
              ),
              
              // Bottom padding for usability
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartTakingTripsButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int tripsCount;
  final VehicleModel? selectedVehicle;

  const _StartTakingTripsButton({
    required this.onPressed,
    required this.tripsCount,
    this.selectedVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOnline = selectedVehicle != null;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.lightSurface : AppColors.primary,
        gradient: isOnline ? null : LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AppColors.textPrimary : AppColors.primary).withOpacity(isOnline ? 0.05 : 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: isOnline ? Border.all(color: AppColors.primary, width: 2) : null, // Enhanced border when active
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.primary.withOpacity(0.1) : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOnline 
                        ? (selectedVehicle!.wheelchairAccessible 
                            ? Icons.accessible_forward_rounded 
                            : Icons.directions_car_rounded)
                        : Icons.play_arrow_rounded,
                    color: isOnline ? AppColors.primary : Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? selectedVehicle!.licensePlate : 'Start Taking Trips',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isOnline ? AppColors.textPrimary : Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isOnline
                            ? '${selectedVehicle!.year} ${selectedVehicle!.make} ${selectedVehicle!.model}'
                            : (tripsCount > 0 ? '$tripsCount trips scheduled today' : 'Go online to receive trips'),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isOnline ? AppColors.textSecondary : Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isOnline) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Tap to change vehicle',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined, size: 12, color: AppColors.primary)
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isOnline ? Icons.swap_horiz_rounded : Icons.arrow_forward_rounded,
                  color: isOnline ? AppColors.primary : Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverInfoCard extends StatelessWidget {
  final dynamic driver;

  const _DriverInfoCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/driver/profile'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3), // Border width
            decoration: const BoxDecoration(
              color: AppColors.lightSurface,
              shape: BoxShape.circle,
              boxShadow: [
                 BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                driver.firstName[0] + driver.lastName[0],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${driver.firstName}',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
              ),
              Text(
                'Good Morning', // TODO: Dynamic greeting based on time
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
               color: AppColors.lightSurface,
               shape: BoxShape.circle,
               border: Border.all(color: AppColors.lightBorder),
             ),
             child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int todayCount;
  final int completedCount;
  final int upcomingCount;

  const _StatsRow({
    required this.todayCount,
    required this.completedCount,
    required this.upcomingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.calendar_today_rounded, label: 'Today', count: todayCount, color: AppColors.info)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.check_circle_outline_rounded, label: 'Done', count: completedCount, color: AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.upcoming_outlined, label: 'Next', count: upcomingCount, color: AppColors.warning)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            count.toString(), 
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label, 
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _TripFilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final TripService tripService;
  final String driverId;

  const _TripFilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.tripService,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    final allTrips = tripService.getDriverTrips(driverId);
    final scheduled = allTrips.where((t) => t.status == TripStatus.scheduled || t.status == TripStatus.assigned).toList();
    final inProgress = allTrips.where((t) => t.status == TripStatus.enRoute || t.status == TripStatus.arrived || t.status == TripStatus.pickedUp).toList();
    final completed = allTrips.where((t) => t.status == TripStatus.completed).toList();
    
    // Custom Chip Design
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CustomFilterChip(label: 'All', count: allTrips.length, isSelected: selectedFilter == 'all', onTap: () => onFilterChanged('all')),
          _CustomFilterChip(label: 'Scheduled', count: scheduled.length, isSelected: selectedFilter == 'scheduled', onTap: () => onFilterChanged('scheduled')),
          _CustomFilterChip(label: 'Active', count: inProgress.length, isSelected: selectedFilter == 'inProgress', onTap: () => onFilterChanged('inProgress')),
          _CustomFilterChip(label: 'Done', count: completed.length, isSelected: selectedFilter == 'completed', onTap: () => onFilterChanged('completed')),
        ],
      ),
    );
  }
}

class _CustomFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomFilterChip({required this.label, required this.count, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilteredTripList extends StatelessWidget {
  final String selectedFilter;
  final TripService tripService;
  final String driverId;

  const _FilteredTripList({
    required this.selectedFilter,
    required this.tripService,
    required this.driverId,
  });

  List<TripModel> _getFilteredTrips() {
    final allTrips = tripService.getDriverTrips(driverId);
    
    switch (selectedFilter) {
      case 'scheduled':
        return allTrips.where((t) => t.status == TripStatus.scheduled || t.status == TripStatus.assigned).toList();
      case 'inProgress':
        return allTrips.where((t) => t.status == TripStatus.enRoute || t.status == TripStatus.arrived || t.status == TripStatus.pickedUp).toList();
      case 'completed':
        return allTrips.where((t) => t.status == TripStatus.completed).toList();
      case 'cancelled':
        return allTrips.where((t) => t.status == TripStatus.cancelled || t.status == TripStatus.noShow).toList();
      default:
        return allTrips;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = _getFilteredTrips();
    
    trips.sort((a, b) {
      if (selectedFilter == 'completed' || selectedFilter == 'cancelled') {
        return b.scheduledPickupTime.compareTo(a.scheduledPickupTime);
      }
      return a.scheduledPickupTime.compareTo(b.scheduledPickupTime);
    });

    if (trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightBorder, width: 1, style: BorderStyle.solid),
        ),
         child: Column(
           children: [
             Icon(Icons.inbox_rounded, size: 48, color: AppColors.textDisabled),
             const SizedBox(height: 16),
             Text(
               'No trips found',
               style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
             ),
           ],
         ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Handled by parent
      itemCount: trips.length,
      itemBuilder: (context, index) => _TripCard(trip: trips[index]),
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
      case TripStatus.arrived:
        return AppColors.warning;
      case TripStatus.pickedUp:
        return AppColors.primary;
      case TripStatus.completed:
        return AppColors.success;
      case TripStatus.cancelled:
      case TripStatus.noShow:
        return AppColors.error;
    }
  }
  
  String _getStatusText() {
    // ... same as before but formatted nicely
    return trip.status.toString().split('.').last.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final statusColor = _getStatusColor();
    final bool isCompleted = trip.status == TripStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
                    Text(
                      timeFormat.format(trip.scheduledPickupTime),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Pickup
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Column(
                       children: [
                         Icon(Icons.circle, size: 12, color: AppColors.primary),
                         Container(width: 2, height: 24, color: AppColors.lightBorder),
                         Icon(Icons.location_on, size: 12, color: AppColors.textTertiary),
                       ],
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             trip.pickupAddress,
                             style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           ),
                           const SizedBox(height: 12),
                           Text(
                             trip.dropoffAddress,
                             style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ],
                       ),
                     )
                  ],
                ),
                
                if (trip.mobilityAid != 'none' && !isCompleted) ...[
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                  Row(
                    children: [
                      Icon(Icons.accessible_forward_rounded, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text(
                        trip.mobilityAid.toUpperCase().replaceAll('_', ' '),
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final TripModel trip;

  const _ActiveTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/driver/trip/${trip.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'CURRENT TRIP',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.trip_origin, color: Colors.white, size: 20),
                        Container(
                          width: 2,
                          height: 30,
                          color: Colors.white.withOpacity(0.3),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        const Icon(Icons.location_on, color: AppColors.secondary, size: 20),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PICKUP', 
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7), letterSpacing: 1)
                          ),
                          Text(
                            trip.pickupAddress,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'DROPOFF', 
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7), letterSpacing: 1)
                          ),
                          Text(
                            trip.dropoffAddress,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoActiveTripCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.drive_eta, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              'No Active Trip',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start a scheduled trip to see it here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
