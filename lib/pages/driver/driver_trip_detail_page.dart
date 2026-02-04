import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/location_service.dart';
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/widgets/swipe_action_button.dart';
import 'package:yazdrive/widgets/trip_instructions_modal.dart';
import 'package:yazdrive/widgets/trip_cancellation_modal.dart';
import 'package:yazdrive/utils/map_launcher.dart';
import 'package:yazdrive/theme.dart';
import 'package:yazdrive/widgets/trip_map.dart';

class DriverTripDetailPage extends StatefulWidget {
  final String tripId;

  const DriverTripDetailPage({super.key, required this.tripId});

  @override
  State<DriverTripDetailPage> createState() => _DriverTripDetailPageState();
}

class _DriverTripDetailPageState extends State<DriverTripDetailPage> {
  final _notesController = TextEditingController();
  final _milesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _notesController.dispose();
    _milesController.dispose();
    super.dispose();
  }

  Future<bool> _checkLocationProximity(double? lat, double? lng) async {
    if (lat == null || lng == null) return true;
    
    final locationService = context.read<LocationService>();
    final isNear = await locationService.isWithinRange(lat, lng, 1.0);
    
    if (!isNear && mounted) {
      _showWrongLocationAlert();
      return false;
    }
    return true;
  }

  void _showWrongLocationAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_off_rounded, color: AppColors.error, size: 48),
        title: Text('Location Mismatch', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: const Text(
          'You appear to be more than 1 mile away from the target location. Please ensure you have arrived before proceeding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSwipeAction(TripService tripService, TripModel trip) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      switch (trip.status) {
        case TripStatus.scheduled:
        case TripStatus.assigned:
          final confirmed = await TripInstructionsModal.show(context, trip);
          if (confirmed && mounted) {
            await tripService.startTrip(widget.tripId);
            _showSuccessSnackbar('Trip started - Navigate to pickup');
          }
          break;
          
        case TripStatus.enRoute:
          final isNear = await _checkLocationProximity(trip.pickupLatitude, trip.pickupLongitude);
          if (isNear) {
            await tripService.arriveAtPickup(widget.tripId);
            _showSuccessSnackbar('Arrived at pickup');
          }
          break;
          
        case TripStatus.arrived:
          await tripService.pickupMember(widget.tripId);
          _showSuccessSnackbar('Member picked up - Navigate to drop-off');
          break;
          
        case TripStatus.pickedUp:
          final isNearDropoff = await _checkLocationProximity(trip.dropoffLatitude, trip.dropoffLongitude);
          if (isNearDropoff && mounted) {
            context.push('/driver/trip/${widget.tripId}/complete');
          }
          break;
          
        default:
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.inter())),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _cancelTrip(TripService tripService) async {
    final result = await TripCancellationModal.show(context);
    
    if (result != null && mounted) {
      await tripService.cancelTrip(
        widget.tripId,
        result['reason']!,
        result['description']!,
      );
      if (mounted) {
        _showSuccessSnackbar('Trip cancelled');
        context.pop();
      }
    }
  }

  Future<void> _launchNavigation(String address, double? lat, double? lng) async {
    await MapLauncher.launchNavigation(
      context: context,
      latitude: lat,
      longitude: lng,
      address: address,
    );
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) return;
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _undoAction(TripService tripService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Undo Last Action?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: const Text('This will revert the trip status to the previous state.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Undo')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await tripService.undoLastAction(widget.tripId);
      if (mounted) _showSuccessSnackbar('Status reverted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripService = context.watch<TripService>();
    final userService = context.watch<UserService>();
    final trip = tripService.getTripById(widget.tripId);

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Not Found')),
        body: const Center(child: Text('Trip not found or access denied')),
      );
    }

    final member = userService.getUserById(trip.memberId);
    
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Trip Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.lightBorder, height: 1),
        ),
        actions: [
          if (trip.status != TripStatus.completed && trip.status != TripStatus.cancelled)
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                if (trip.status == TripStatus.enRoute || trip.status == TripStatus.arrived || trip.status == TripStatus.pickedUp)
                  PopupMenuItem(
                    value: 'undo',
                    child: Row(
                      children: [
                        const Icon(Icons.undo_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 12),
                        Text('Undo Action', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
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
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Text('Cancel Trip', style: GoogleFonts.inter(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'cancel') {
                  _cancelTrip(tripService);
                } else if (value == 'undo') {
                  _undoAction(tripService);
                } else if (value == 'info') {
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   TripMap(trip: trip),
                   const SizedBox(height: 20),
                   _StatusCard(trip: trip),
                   const SizedBox(height: 20),
                   _TripTimeline(
                     trip: trip, 
                     onNavigatePickup: () => _launchNavigation(trip.pickupAddress, trip.pickupLatitude, trip.pickupLongitude),
                     onNavigateDropoff: () => _launchNavigation(trip.dropoffAddress, trip.dropoffLatitude, trip.dropoffLongitude),
                   ),
                   const SizedBox(height: 20),
                   if (member != null || trip.customerName != null)
                     _MemberCard(
                       name: trip.customerName ?? member?.fullName ?? 'Guest',
                       phone: trip.customerPhone ?? member?.phoneNumber,
                       onCall: () => _makePhoneCall(trip.customerPhone ?? member?.phoneNumber),
                     ),
                   const SizedBox(height: 20),
                   _RequirementsCard(trip: trip),
                   const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          if (trip.status != TripStatus.completed && trip.status != TripStatus.cancelled)
            _ActionFooter(
              trip: trip,
              isProcessing: _isProcessing,
              onSwipe: () => _handleSwipeAction(tripService, trip),
            ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final TripModel trip;

  const _StatusCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String statusText;
    String subText;

    switch (trip.status) {
      case TripStatus.completed:
        backgroundColor = const Color(0xFFE0F2F1); // Light Mint Green
        textColor = const Color(0xFF009688); // Teal
        icon = Icons.check_circle_rounded;
        statusText = 'COMPLETED';
        subText = 'Scheduled for ${DateFormat('h:mm a').format(trip.scheduledPickupTime)}';
        break;
      case TripStatus.cancelled:
      case TripStatus.noShow:
        backgroundColor = const Color(0xFFFFEBEE); // Light Red
        textColor = AppColors.error;
        icon = Icons.cancel_rounded;
        statusText = 'CANCELLED';
        subText = 'Was scheduled for ${DateFormat('h:mm a').format(trip.scheduledPickupTime)}';
        break;
      default:
        // Active states
        backgroundColor = const Color(0xFFE3F2FD); // Light Blue
        textColor = AppColors.primary;
        icon = Icons.directions_car_rounded;
        statusText = trip.status.toString().split('.').last.toUpperCase();
        subText = 'Scheduled for ${DateFormat('h:mm a').format(trip.scheduledPickupTime)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: backgroundColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: textColor),
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          if (trip.tripNumber != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 8.0),
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                 decoration: BoxDecoration(
                   color: textColor.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(
                   'TRIP #${trip.tripNumber}',
                   style: GoogleFonts.robotoMono(
                     fontSize: 12,
                     fontWeight: FontWeight.w600,
                     color: textColor,
                   ),
                 ),
               ),
             ),
          Text(
            subText,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTimeline extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onNavigatePickup;
  final VoidCallback onNavigateDropoff;

  const _TripTimeline({required this.trip, required this.onNavigatePickup, required this.onNavigateDropoff});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _LocationItem(
            type: 'PICKUP',
            address: trip.pickupAddress,
            city: '${trip.pickupCity}, ${trip.pickupState}',
            isDone: true, // Always show checkmark style for visual matching as per request, or conditional
            showConnector: true,
          ),
          const Divider(height: 1, color: AppColors.lightBorder),
          _LocationItem(
            type: 'DROPOFF',
            address: trip.dropoffAddress,
            city: '${trip.dropoffCity}, ${trip.dropoffState}',
            isDone: true,
            showConnector: false,
          ),
        ],
      ),
    );
  }
}

class _LocationItem extends StatelessWidget {
  final String type;
  final String address;
  final String city;
  final bool isDone;
  final bool showConnector;

  const _LocationItem({
    required this.type,
    required this.address,
    required this.city,
    required this.isDone,
    this.showConnector = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.secondary, // Emerald green
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
              if (showConnector)
                Container(
                  width: 2,
                  height: 40,
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  margin: const EdgeInsets.only(top: 4),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  city,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String name;
  final String? phone;
  final VoidCallback onCall;

  const _MemberCard({required this.name, this.phone, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
         boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.lightSurface,
            child: Text(name.isNotEmpty ? name[0] : '?', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PASSENGER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
          if (phone != null)
            IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.phone_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  final TripModel trip;

  const _RequirementsCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    if (trip.mobilityAid == 'none' && !trip.requiresAttendant && !trip.oxygenRequired && trip.specialRequirements == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Requirements', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (trip.mobilityAid != 'none') _Badge(label: trip.mobilityAid, icon: Icons.accessible_forward, color: Colors.orange),
              if (trip.requiresAttendant) _Badge(label: 'Attendant', icon: Icons.people, color: Colors.blue),
              if (trip.oxygenRequired) _Badge(label: 'Oxygen', icon: Icons.air, color: Colors.teal),
            ],
          ),
          if (trip.specialRequirements != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.lightSurface, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.notes, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(trip.specialRequirements!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _ActionFooter extends StatelessWidget {
  final TripModel trip;
  final bool isProcessing;
  final VoidCallback onSwipe;

  const _ActionFooter({required this.trip, required this.isProcessing, required this.onSwipe});

  @override
  Widget build(BuildContext context) {
    String label = 'Swipe to Start';
    Color color = AppColors.primary;

    switch (trip.status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        label = 'Begin Pickup';
        color = AppColors.primary;
        break;
      case TripStatus.enRoute:
        label = 'Swipe to Arrive at Pickup';
        color = AppColors.warning; // Keeping as Warning/Blue-ish for en route
        break;
      case TripStatus.arrived:
        label = 'Swipe to Confirm Pickup';
        color = AppColors.info;
        break;
      case TripStatus.pickedUp:
        label = 'Swipe to Complete Drop-off';
        color = AppColors.success;
        break;
      default:
        break;
    }

    // Determine the relevant time to display
    // For pickup-related statuses, show Pickup Time. For dropoff, show intended dropoff time if available?
    // User reference image shows "Pickup: 04:10 PM".
    final timeText = 'Pickup: ${DateFormat('h:mm a').format(trip.scheduledPickupTime)}';

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Added Time Display
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              timeText,
              style: GoogleFonts.inter(
                fontSize: 16, 
                fontWeight: FontWeight.w700, 
                color: AppColors.textPrimary
              ),
            ),
          ),
          if (isProcessing)
             const CircularProgressIndicator()
          else
            SwipeActionButton(
              key: ValueKey(trip.status),
              text: label.toUpperCase(), // Uppercase to match reference
              color: color,
              onSwipeComplete: onSwipe,
              icon: Icons.double_arrow_rounded,
            ),
        ],
      ),
    );
  }
}
