import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/location_service.dart';
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/widgets/swipe_action_button.dart';
import 'package:yazdrive/widgets/trip_instructions_modal.dart';
import 'package:yazdrive/widgets/trip_cancellation_modal.dart';
import 'package:yazdrive/utils/map_launcher.dart';
import 'package:yazdrive/theme.dart';

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

  /// Check if driver is within 1 mile of target location
  Future<bool> _checkLocationProximity(double? lat, double? lng) async {
    if (lat == null || lng == null) return true; // Skip check if no coordinates
    
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
        icon: Icon(Icons.wrong_location, color: AppColors.error, size: 48),
        title: const Text('Wrong Location'),
        content: const Text(
          'You appear to be more than 1 mile away from the destination. '
          'Please make sure you are at the correct location before proceeding.',
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
          // Show trip instructions modal first
          final confirmed = await TripInstructionsModal.show(context, trip);
          if (confirmed && mounted) {
            await tripService.startTrip(widget.tripId);
            _showSuccessSnackbar('Trip started - Navigate to pickup location');
          }
          break;
          
        case TripStatus.enRoute:
          // Check location before marking arrived
          final isNear = await _checkLocationProximity(
            trip.pickupLatitude,
            trip.pickupLongitude,
          );
          if (isNear) {
            await tripService.arriveAtPickup(widget.tripId);
            _showSuccessSnackbar('Arrived at pickup - Contact member');
          }
          break;
          
        case TripStatus.arrived:
          await tripService.pickupMember(widget.tripId);
          _showSuccessSnackbar('Member picked up - Navigate to drop-off');
          break;
          
        case TripStatus.pickedUp:
          // Check location before completing
          final isNearDropoff = await _checkLocationProximity(
            trip.dropoffLatitude,
            trip.dropoffLongitude,
          );
          if (isNearDropoff && mounted) {
            // Navigate to AHCCCS Trip Completion page
            context.push('/driver/trip/${widget.tripId}/complete');
          }
          break;
          
        default:
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showCompleteDialog(TripService tripService) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _milesController,
              decoration: const InputDecoration(
                labelText: 'Actual Miles',
                prefixIcon: Icon(Icons.route),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Trip Notes (Optional)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Complete Trip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final miles = double.tryParse(_milesController.text);
      await tripService.completeTrip(
        widget.tripId,
        actualMiles: miles,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      if (mounted) {
        _showSuccessSnackbar('Trip completed successfully!');
        context.pop();
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip cancelled')),
        );
        context.pop();
      }
    }
  }

  Future<void> _launchNavigation(String address, double? lat, double? lng) async {
    if (lat == null || lng == null) {
      _showSuccessSnackbar('Location coordinates missing');
      return;
    }
  
    await MapLauncher.launchNavigation(
      context: context,
      latitude: lat,
      longitude: lng,
      address: address,
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripService = context.watch<TripService>();
    final userService = context.watch<UserService>();
    final trip = tripService.getTripById(widget.tripId);

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: const Center(child: Text('Trip not found')),
      );
    }

    final member = userService.getUserById(trip.memberId);
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          // Options menu (three dots)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'cancel') {
                _cancelTrip(tripService);
              }
            },
            itemBuilder: (context) => [
              if (trip.status != TripStatus.completed && trip.status != TripStatus.cancelled)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Cancel Trip'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusCard(trip: trip),
                const SizedBox(height: 16),
                _TripTimeCard(trip: trip, dateFormat: dateFormat, timeFormat: timeFormat),
                const SizedBox(height: 16),
                _LocationCard(
                  title: 'Pickup Location',
                  icon: Icons.trip_origin,
                  iconColor: AppColors.success,
                  address: trip.pickupAddress,
                  city: '${trip.pickupCity}, ${trip.pickupState} ${trip.pickupZip}',
                  notes: trip.pickupNotes,
                  onTapDirections: () => _launchNavigation(
                    '${trip.pickupAddress}, ${trip.pickupCity}, ${trip.pickupState} ${trip.pickupZip}',
                    trip.pickupLatitude,
                    trip.pickupLongitude,
                  ),
                  isActive: trip.status == TripStatus.enRoute || trip.status == TripStatus.assigned,
               ),
                const SizedBox(height: 16),
                _LocationCard(
                  title: 'Drop-off Location',
                  icon: Icons.location_on,
                  iconColor: AppColors.error,
                  address: trip.dropoffAddress,
                  city: '${trip.dropoffCity}, ${trip.dropoffState} ${trip.dropoffZip}',
                  notes: trip.dropoffNotes,
                  onTapDirections: () => _launchNavigation(
                    '${trip.dropoffAddress}, ${trip.dropoffCity}, ${trip.dropoffState} ${trip.dropoffZip}',
                    trip.dropoffLatitude,
                    trip.dropoffLongitude,
                  ),
                  isActive: trip.status == TripStatus.pickedUp,
                ),
                const SizedBox(height: 16),
                if (member != null) 
                  _MemberInfoCard(
                    member: member,
                    onCall: () => _makePhoneCall(member.phoneNumber),
                  ),
                const SizedBox(height: 16),
                _TripRequirementsCard(trip: trip),
                const SizedBox(height: 100), // Space for bottom action
              ],
            ),
          ),
          
          // Bottom swipe action area
          if (trip.status != TripStatus.completed && trip.status != TripStatus.cancelled)
            _BottomActionArea(
              trip: trip,
              isProcessing: _isProcessing,
              onSwipeComplete: () => _handleSwipeAction(tripService, trip),
            ),
        ],
      ),
    );
  }
}

class _BottomActionArea extends StatelessWidget {
  final TripModel trip;
  final bool isProcessing;
  final VoidCallback onSwipeComplete;

  const _BottomActionArea({
    required this.trip,
    required this.isProcessing,
    required this.onSwipeComplete,
  });

  String _getActionText() {
    switch (trip.status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return 'Begin Pickup';
      case TripStatus.enRoute:
        return 'Arrived at Pickup';
      case TripStatus.arrived:
        return 'Pickup is Done';
      case TripStatus.pickedUp:
        return 'Drop-off is Done';
      default:
        return '';
    }
  }

  Color _getActionColor() {
    switch (trip.status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return AppColors.primary;
      case TripStatus.enRoute:
        return AppColors.warning;
      case TripStatus.arrived:
        return AppColors.info;
      case TripStatus.pickedUp:
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon() {
    switch (trip.status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return Icons.play_arrow;
      case TripStatus.enRoute:
        return Icons.location_on;
      case TripStatus.arrived:
        return Icons.person_add;
      case TripStatus.pickedUp:
        return Icons.check_circle;
      default:
        return Icons.check;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isProcessing
          ? Center(
              child: CircularProgressIndicator(color: _getActionColor()),
            )
          : SwipeActionButton(
              key: ValueKey(trip.status),
              text: _getActionText(),
              icon: _getActionIcon(),
              color: _getActionColor(),
              onSwipeComplete: onSwipeComplete,
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final TripModel trip;

  const _StatusCard({required this.trip});

  Color _getStatusColor() {
    switch (trip.status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return AppColors.info;
      case TripStatus.enRoute:
      case TripStatus.arrived:
        return AppColors.warning;
      case TripStatus.pickedUp:
        return AppColors.success;
      case TripStatus.completed:
        return AppColors.success;
      case TripStatus.cancelled:
      case TripStatus.noShow:
        return AppColors.error;
    }
  }

  String _getStatusText() {
    return trip.status.toString().split('.').last.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').trim();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: statusColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trip Status', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(_getStatusText().toUpperCase(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTimeCard extends StatelessWidget {
  final TripModel trip;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  const _TripTimeCard({required this.trip, required this.dateFormat, required this.timeFormat});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scheduled Time', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(dateFormat.format(trip.scheduledPickupTime), style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(timeFormat.format(trip.scheduledPickupTime), style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String address;
  final String city;
  final String? notes;
  final VoidCallback onTapDirections;
  final bool isActive;

  const _LocationCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.address,
    required this.city,
    this.notes,
    required this.onTapDirections,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive ? BorderSide(color: iconColor, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('NEXT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(address, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            Text(city, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            if (notes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(child: Text(notes!, style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTapDirections,
                icon: const Icon(Icons.navigation),
                label: const Text('Navigate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberInfoCard extends StatelessWidget {
  final dynamic member;
  final VoidCallback onCall;

  const _MemberInfoCard({required this.member, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member Information', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(member.firstName[0] + member.lastName[0], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.fullName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      Text('ID: ${member.membershipId ?? "N/A"}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone),
                label: Text('Call ${member.phoneNumber}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripRequirementsCard extends StatelessWidget {
  final TripModel trip;

  const _TripRequirementsCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trip Requirements', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (trip.mobilityAid != 'none')
              _RequirementChip(icon: Icons.accessible, label: 'Mobility Aid: ${trip.mobilityAid}'),
            if (trip.requiresAttendant)
              _RequirementChip(icon: Icons.people, label: 'Attendant Required (${trip.attendantCount})'),
            if (trip.oxygenRequired)
              _RequirementChip(icon: Icons.air, label: 'Oxygen Required'),
            if (trip.specialRequirements != null) ...[
              const SizedBox(height: 8),
              Text('Special Notes:', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(trip.specialRequirements!, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (trip.mobilityAid == 'none' && !trip.requiresAttendant && !trip.oxygenRequired && trip.specialRequirements == null)
              Text('No special requirements', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RequirementChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
