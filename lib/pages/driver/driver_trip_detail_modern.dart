import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/location_service.dart';
import 'package:yazdrive/services/geocoding_service.dart';
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/widgets/swipe_action_button.dart';
import 'package:yazdrive/widgets/trip_instructions_modal.dart';
import 'package:yazdrive/widgets/trip_cancellation_modal.dart';
import 'package:yazdrive/utils/map_launcher.dart';
import 'package:yazdrive/theme.dart';
import 'package:yazdrive/widgets/trip_map.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverTripDetailModernPage extends StatefulWidget {
  final String tripId;

  const DriverTripDetailModernPage({super.key, required this.tripId});

  @override
  State<DriverTripDetailModernPage> createState() => _DriverTripDetailModernPageState();
}

class _DriverTripDetailModernPageState extends State<DriverTripDetailModernPage> {
  bool _isProcessing = false;
  bool _isGeocoding = false;
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;
  final GeocodingService _geocodingService = GeocodingService();

  @override
  void initState() {
    super.initState();
    // Geocode addresses if needed after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geocodeAddressesIfNeeded();
    });
  }

  /// Build full address for better geocoding
  String _buildFullAddress(String address, String city, String state, String zip) {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (zip.isNotEmpty) parts.add(zip);
    return parts.join(', ');
  }

  Future<void> _geocodeAddressesIfNeeded() async {
    final tripService = context.read<TripService>();
    final trip = tripService.getTripById(widget.tripId);

    if (trip == null) return;

    // Check if we need to geocode
    final needsPickupGeocode = trip.pickupLatitude == null || trip.pickupLongitude == null;
    final needsDropoffGeocode = trip.dropoffLatitude == null || trip.dropoffLongitude == null;

    if (!needsPickupGeocode && !needsDropoffGeocode) {
      // Already have coordinates
      setState(() {
        _pickupLat = trip.pickupLatitude;
        _pickupLng = trip.pickupLongitude;
        _dropoffLat = trip.dropoffLatitude;
        _dropoffLng = trip.dropoffLongitude;
      });
      return;
    }

    setState(() => _isGeocoding = true);

    try {
      // Geocode pickup address if needed
      if (needsPickupGeocode) {
        final fullPickupAddress = _buildFullAddress(
          trip.pickupAddress,
          trip.pickupCity,
          trip.pickupState,
          trip.pickupZip,
        );
        debugPrint('Geocoding full pickup address: $fullPickupAddress');
        final pickupCoords = await _geocodingService.geocodeAddress(fullPickupAddress);
        if (pickupCoords != null) {
          _pickupLat = pickupCoords[0];
          _pickupLng = pickupCoords[1];
          debugPrint('Pickup geocoded to: $_pickupLat, $_pickupLng');
        }
      } else {
        _pickupLat = trip.pickupLatitude;
        _pickupLng = trip.pickupLongitude;
      }

      // Geocode dropoff address if needed
      if (needsDropoffGeocode) {
        final fullDropoffAddress = _buildFullAddress(
          trip.dropoffAddress,
          trip.dropoffCity,
          trip.dropoffState,
          trip.dropoffZip,
        );
        debugPrint('Geocoding full dropoff address: $fullDropoffAddress');
        final dropoffCoords = await _geocodingService.geocodeAddress(fullDropoffAddress);
        if (dropoffCoords != null) {
          _dropoffLat = dropoffCoords[0];
          _dropoffLng = dropoffCoords[1];
          debugPrint('Dropoff geocoded to: $_dropoffLat, $_dropoffLng');
        }
      } else {
        _dropoffLat = trip.dropoffLatitude;
        _dropoffLng = trip.dropoffLongitude;
      }
    } catch (e) {
      debugPrint('Error geocoding addresses: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeocoding = false);
      }
    }
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
          await tripService.arriveAtPickup(widget.tripId);
          _showSuccessSnackbar('Arrived at pickup');
          break;

        case TripStatus.arrived:
          await tripService.pickupMember(widget.tripId);
          _showSuccessSnackbar('Member picked up - Navigate to drop-off');
          break;

        case TripStatus.pickedUp:
          if (mounted) {
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

  Future<void> _launchNavigation(String address, double? lat, double? lng) async {
    // Launch navigation even without coordinates - MapLauncher can use address
    await MapLauncher.launchNavigation(
      context: context,
      latitude: lat,
      longitude: lng,
      address: address,
    );
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

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) return;
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
        _showSuccessSnackbar('Trip cancelled');
        context.pop();
      }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Trip Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (trip.status != TripStatus.completed && trip.status != TripStatus.cancelled)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
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
                }
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen map with geocoded coordinates
          _FullScreenMap(
            trip: trip,
            pickupLat: _pickupLat ?? trip.pickupLatitude,
            pickupLng: _pickupLng ?? trip.pickupLongitude,
            dropoffLat: _dropoffLat ?? trip.dropoffLatitude,
            dropoffLng: _dropoffLng ?? trip.dropoffLongitude,
            isGeocoding: _isGeocoding,
          ),

          // Bottom info card overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomInfoCard(
              trip: trip,
              member: member,
              onNavigate: () => _launchNavigation(
                trip.status == TripStatus.pickedUp ? trip.dropoffAddress : trip.pickupAddress,
                trip.status == TripStatus.pickedUp
                    ? (_dropoffLat ?? trip.dropoffLatitude)
                    : (_pickupLat ?? trip.pickupLatitude),
                trip.status == TripStatus.pickedUp
                    ? (_dropoffLng ?? trip.dropoffLongitude)
                    : (_pickupLng ?? trip.pickupLongitude),
              ),
              onSwipe: () => _handleSwipeAction(tripService, trip),
              onCall: () => _makePhoneCall(trip.customerPhone ?? member?.phoneNumber),
              isProcessing: _isProcessing,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenMap extends StatelessWidget {
  final TripModel trip;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final bool isGeocoding;

  const _FullScreenMap({
    required this.trip,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.isGeocoding = false,
  });

  @override
  Widget build(BuildContext context) {
    // Debug logging
    print('DEBUG: Pickup coordinates: $pickupLat, $pickupLng');
    print('DEBUG: Dropoff coordinates: $dropoffLat, $dropoffLng');
    print('DEBUG: Is geocoding: $isGeocoding');

    // Show loading while geocoding
    if (isGeocoding) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading map...',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if we have coordinates
    if (pickupLat == null || pickupLng == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.navigation_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Map Preview Unavailable',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Use the Navigate button below to get directions',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pickup = LatLng(pickupLat!, pickupLng!);
    final dropoff = (dropoffLat != null && dropoffLng != null)
        ? LatLng(dropoffLat!, dropoffLng!)
        : null;

    return FlutterMap(
      options: MapOptions(
        initialCenter: pickup,
        initialZoom: 14.0,
        initialCameraFit: dropoff != null
            ? CameraFit.bounds(
                bounds: LatLngBounds(pickup, dropoff),
                padding: const EdgeInsets.all(80),
              )
            : null,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.yaztrans.yazdrive',
        ),
        if (dropoff != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [pickup, dropoff],
                strokeWidth: 5,
                color: AppColors.primary,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: pickup,
              width: 50,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.location_on, color: AppColors.primary, size: 32),
              ),
            ),
            if (dropoff != null)
              Marker(
                point: dropoff,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on, color: AppColors.success, size: 32),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BottomInfoCard extends StatelessWidget {
  final TripModel trip;
  final dynamic member;
  final VoidCallback onNavigate;
  final VoidCallback onSwipe;
  final VoidCallback onCall;
  final bool isProcessing;

  const _BottomInfoCard({
    required this.trip,
    required this.member,
    required this.onNavigate,
    required this.onSwipe,
    required this.onCall,
    required this.isProcessing,
  });

  String _getPersonName() {
    if (member != null) {
      return '${member.firstName} ${member.lastName}';
    } else if (trip.customerName != null && trip.customerName!.isNotEmpty) {
      return trip.customerName!;
    }
    return 'Guest';
  }

  String _getInitials() {
    if (member != null) {
      return '${member.firstName[0]}${member.lastName[0]}';
    } else if (trip.customerName != null && trip.customerName!.isNotEmpty) {
      final nameParts = trip.customerName!.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}';
      } else if (nameParts.isNotEmpty) {
        return nameParts[0][0];
      }
    }
    return 'G';
  }

  String _getNextDestination() {
    switch (trip.status) {
      case TripStatus.enRoute:
      case TripStatus.arrived:
        return trip.pickupAddress;
      case TripStatus.pickedUp:
        return trip.dropoffAddress;
      default:
        return trip.pickupAddress;
    }
  }

  String _getStatusText() {
    switch (trip.status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return 'Scheduled';
      case TripStatus.enRoute:
        return 'En Route';
      case TripStatus.arrived:
        return 'Arrived';
      case TripStatus.pickedUp:
        return 'Picked Up';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor() {
    switch (trip.status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return Colors.blue;
      case TripStatus.enRoute:
        return Colors.orange;
      case TripStatus.arrived:
        return Colors.purple;
      case TripStatus.pickedUp:
        return AppColors.primary;
      case TripStatus.completed:
        return AppColors.success;
      case TripStatus.cancelled:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getSwipeText(TripStatus status) {
    switch (status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return 'Swipe to start trip';
      case TripStatus.enRoute:
        return 'Swipe to arrive at pickup';
      case TripStatus.arrived:
        return 'Swipe to pickup member';
      case TripStatus.pickedUp:
        return 'Swipe to complete trip';
      default:
        return 'Swipe to continue';
    }
  }

  Color _getSwipeColor(TripStatus status) {
    switch (status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return AppColors.primary;
      case TripStatus.enRoute:
        return Colors.orange;
      case TripStatus.arrived:
        return Colors.purple;
      case TripStatus.pickedUp:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final pickupTime = timeFormat.format(trip.scheduledPickupTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Trip: ${_getNextDestination().split(',').first}',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Pickup time: $pickupTime',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (trip.tripNumber != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: Text(
                                  '#${trip.tripNumber}',
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: _getStatusColor(),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getStatusText(),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Member/Customer info with Navigate button - ALWAYS SHOW
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      _getInitials(),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passenger',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPersonName(),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 48,
                    width: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onNavigate,
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.navigation, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Navigate',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Call Button (Small)
              if (trip.customerPhone != null || (member != null && member.phoneNumber != null))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.phone, size: 18),
                      label: Text('Call Passenger', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              if (trip.status != TripStatus.completed && trip.status != TripStatus.cancelled)
                SwipeActionButton(
                  key: ValueKey(trip.status),
                  text: _getSwipeText(trip.status),
                  icon: Icons.double_arrow_rounded,
                  color: _getSwipeColor(trip.status),
                  onSwipeComplete: onSwipe,
                  isEnabled: !isProcessing,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
