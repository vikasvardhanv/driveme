import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/models/trip_model.dart';
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

  @override
  void dispose() {
    _notesController.dispose();
    _milesController.dispose();
    super.dispose();
  }

  Future<void> _updateTripStatus(TripService tripService, TripStatus newStatus) async {
    final trip = tripService.getTripById(widget.tripId);
    if (trip == null) return;

    switch (newStatus) {
      case TripStatus.enRoute:
        await tripService.startTrip(widget.tripId);
        break;
      case TripStatus.arrived:
        await tripService.arriveAtPickup(widget.tripId);
        break;
      case TripStatus.pickedUp:
        await tripService.pickupMember(widget.tripId);
        break;
      case TripStatus.completed:
        await _showCompleteDialog(tripService);
        return;
      default:
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip status updated')),
      );
    }
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
                labelText: 'Trip Notes',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Complete')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip completed successfully')),
        );
        context.pop();
      }
    }
  }

  Future<void> _launchMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=\$encodedAddress');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:\$phoneNumber');
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
      appBar: AppBar(title: const Text('Trip Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(trip: trip),
          const SizedBox(height: 16),
          _TripTimeCard(trip: trip, dateFormat: dateFormat, timeFormat: timeFormat),
          const SizedBox(height: 16),
          _LocationCard(
            title: 'Pickup Location',
            icon: Icons.trip_origin,
            iconColor: AppColors.primary,
            address: trip.pickupAddress,
            city: '\${trip.pickupCity}, \${trip.pickupState} \${trip.pickupZip}',
            notes: trip.pickupNotes,
            onTapDirections: () => _launchMaps('\${trip.pickupAddress}, \${trip.pickupCity}, \${trip.pickupState} \${trip.pickupZip}'),
          ),
          const SizedBox(height: 16),
          _LocationCard(
            title: 'Dropoff Location',
            icon: Icons.location_on,
            iconColor: AppColors.error,
            address: trip.dropoffAddress,
            city: '\${trip.dropoffCity}, \${trip.dropoffState} \${trip.dropoffZip}',
            notes: trip.dropoffNotes,
            onTapDirections: () => _launchMaps('\${trip.dropoffAddress}, \${trip.dropoffCity}, \${trip.dropoffState} \${trip.dropoffZip}'),
          ),
          const SizedBox(height: 16),
          if (member != null) _MemberInfoCard(member: member, onCall: () => _makePhoneCall(member.phoneNumber)),
          const SizedBox(height: 16),
          _TripRequirementsCard(trip: trip),
          const SizedBox(height: 24),
          _ActionButtons(trip: trip, onUpdateStatus: (status) => _updateTripStatus(tripService, status)),
        ],
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
    return trip.status.toString().split('.').last.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' \${match.group(0)}').trim();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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

  const _LocationCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.address,
    required this.city,
    this.notes,
    required this.onTapDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
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
                  color: AppColors.warning.withValues(alpha: 0.1),
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
            OutlinedButton.icon(
              onPressed: onTapDirections,
              icon: const Icon(Icons.directions),
              label: const Text('Get Directions'),
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
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(member.firstName[0] + member.lastName[0], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.fullName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      Text('ID: \${member.membershipId != null ? member.membershipId : "N/A"}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.phone),
              label: Text(member.phoneNumber),
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
              _RequirementChip(icon: Icons.accessible, label: 'Mobility Aid: \${trip.mobilityAid}'),
            if (trip.requiresAttendant)
              _RequirementChip(icon: Icons.people, label: 'Attendant Required (\${trip.attendantCount})'),
            if (trip.oxygenRequired)
              _RequirementChip(icon: Icons.air, label: 'Oxygen Required'),
            if (trip.specialRequirements != null) ...[
              const SizedBox(height: 8),
              Text('Special Notes:', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(trip.specialRequirements!, style: Theme.of(context).textTheme.bodySmall),
            ],
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

class _ActionButtons extends StatelessWidget {
  final TripModel trip;
  final Function(TripStatus) onUpdateStatus;

  const _ActionButtons({required this.trip, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    switch (trip.status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return ElevatedButton(
          onPressed: () => onUpdateStatus(TripStatus.enRoute),
          child: const Text('Start Trip'),
        );
      case TripStatus.enRoute:
        return ElevatedButton(
          onPressed: () => onUpdateStatus(TripStatus.arrived),
          child: const Text('Arrive at Pickup'),
        );
      case TripStatus.arrived:
        return ElevatedButton(
          onPressed: () => onUpdateStatus(TripStatus.pickedUp),
          child: const Text('Pick Up Member'),
        );
      case TripStatus.pickedUp:
        return ElevatedButton(
          onPressed: () => onUpdateStatus(TripStatus.completed),
          child: const Text('Complete Trip'),
        );
      case TripStatus.completed:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 8),
              Text('Trip Completed', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      case TripStatus.cancelled:
      case TripStatus.noShow:
        return const SizedBox.shrink();
    }
  }
}
