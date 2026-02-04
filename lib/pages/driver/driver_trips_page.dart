import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/theme.dart';
import 'package:yazdrive/widgets/swipe_action_button.dart';
import 'package:yazdrive/widgets/trip_instructions_modal.dart';
import 'package:yazdrive/widgets/driver_drawer.dart';

class DriverTripsPage extends StatefulWidget {
  const DriverTripsPage({super.key});

  @override
  State<DriverTripsPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverTripsPage> {
  @override
  Widget build(BuildContext context) {
    final tripService = context.watch<TripService>();
    final userService = context.watch<UserService>();
    final user = userService.currentUser;

    if (user == null) return const SizedBox();

    final allTrips = tripService.trips;
    final myTrips = allTrips.where((t) => t.driverId == user.id || t.status == TripStatus.assigned).toList();
    
    // Sort: Active first, then scheduled
    myTrips.sort((a, b) => a.scheduledPickupTime.compareTo(b.scheduledPickupTime));

    final activeTripsCount = myTrips.where((t) => 
      t.status == TripStatus.enRoute || t.status == TripStatus.arrived || t.status == TripStatus.pickedUp
    ).length;
    
    // Filter completed trips for bottom section
    final activeOrScheduled = myTrips.where((t) => t.status != TripStatus.completed && t.status != TripStatus.cancelled).toList();
    final doneTrips = myTrips.where((t) => t.status == TripStatus.completed).toList();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      drawer: const DriverDrawer(),
      appBar: AppBar(
        title: Text('SCHEDULE', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white, letterSpacing: 1.0)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
           TextButton(
             onPressed: () => context.go('/driver/dashboard'),
             child: Text('Overview', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          )
        ],
      ),
      body: Column(
        children: [
          // Subheader
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: AppColors.primaryDark,
            child: Text(
              'ACTIVE TRIPS: $activeTripsCount',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          
          Expanded(
            child: ListView(
              children: [
                if (activeOrScheduled.isEmpty && doneTrips.isEmpty)
                   Padding(
                     padding: const EdgeInsets.all(32.0),
                     child: Center(child: Text('No trips found', style: GoogleFonts.inter(color: AppColors.textSecondary))),
                   ),

                // Active/Scheduled List
                ...activeOrScheduled.map((trip) => _ScheduleTripCard(trip: trip)),
                
                // Done Header
                if (doneTrips.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: AppColors.lightSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Done Trips',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                  
                // Done List
                ...doneTrips.map((trip) => _DoneTripCard(trip: trip)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTripCard extends StatelessWidget {
  final TripModel trip;

  const _ScheduleTripCard({required this.trip});

  Future<void> _handleBeginPickup(BuildContext context) async {
    // Show trip instructions modal first
    final confirmed = await TripInstructionsModal.show(context, trip);

    if (confirmed && context.mounted) {
      // Start the trip
      final tripService = context.read<TripService>();
      await tripService.startTrip(trip.id);

      // Navigate to trip detail page
      if (context.mounted) {
        context.push('/driver/trip/${trip.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        border: Border(bottom: BorderSide(color: AppColors.lightBorder)),
      ),
      child: Column(
        children: [
          // Begin Pickup Swipe Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SwipeActionButton(
              text: 'BEGIN PICKUP',
              color: AppColors.primary,
              icon: Icons.double_arrow_rounded,
              onSwipeComplete: () => _handleBeginPickup(context),
            ),
          ),

          // Trip Info
          Container(
            color: AppColors.lightSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                         // Member Name - TODO: Get from member data
                        Text(
                          'Member',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz, color: AppColors.textTertiary),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'info',
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
                              const SizedBox(width: 12),
                              Text('Trip Info', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'info') {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Trip Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Trip ID:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                  Text(trip.id, style: GoogleFonts.robotoMono(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 12),
                                  Text('Scheduled Pickup:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                  Text(dateFormat.format(trip.scheduledPickupTime), style: GoogleFonts.inter()),
                                  const SizedBox(height: 12),
                                  Text('Full Pickup Address:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                  Text(trip.pickupAddress, style: GoogleFonts.inter()),
                                  const SizedBox(height: 12),
                                  Text('Full Dropoff Address:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                  Text(trip.dropoffAddress, style: GoogleFonts.inter()),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      'Member #${trip.memberId.length >= 8 ? trip.memberId.substring(0, 8) : trip.memberId}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Address
                Row(
                  children: [
                     const Icon(Icons.location_on, color: AppColors.textTertiary, size: 24),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             trip.pickupAddress,
                             style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                             maxLines: 1, overflow: TextOverflow.ellipsis,
                           ),
                           const SizedBox(height: 4),
                           Text(
                             'Pickup: ${dateFormat.format(trip.scheduledPickupTime)}',
                             style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                           ),
                         ],
                       ),
                     ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneTripCard extends StatelessWidget {
  final TripModel trip;

  const _DoneTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: AppColors.lightSurfaceVariant, 
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                 text: TextSpan(
                   children: [
                     TextSpan(
                       text: 'Trip Done: ',
                       style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary), 
                     ),
                     TextSpan(
                       text: 'G. MEMBER',
                       style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                     ),
                   ],
                 ),
              ),
              Text(
                'Trip #${trip.id.length >= 7 ? trip.id.substring(0, 7) : trip.id}',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
