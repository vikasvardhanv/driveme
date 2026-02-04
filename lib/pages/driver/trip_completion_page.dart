import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/vehicle_service.dart';
import 'package:yazdrive/theme.dart';
import 'package:yazdrive/widgets/signature_capture_widget.dart';
import 'package:yazdrive/services/azuga_service.dart';

class TripCompletionPage extends StatefulWidget {
  final String tripId;

  const TripCompletionPage({super.key, required this.tripId});

  @override
  State<TripCompletionPage> createState() => _TripCompletionPageState();
}

class _TripCompletionPageState extends State<TripCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickupOdometerController = TextEditingController();
  final _dropoffOdometerController = TextEditingController();
  final _reasonForVisitController = TextEditingController();
  final _escortNameController = TextEditingController();
  final _escortRelationshipController = TextEditingController();
  final _notesController = TextEditingController();

  String? _driverSignature;
  String? _memberSignature;
  bool _memberUnableToSign = false;
  bool _isSubmitting = false;
  bool _multipleMembers = false;
  bool _differentLocations = false;
  bool _isFetchingTelematics = false;
  bool _azugaDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  Future<void> _prefillData() async {
    final tripService = context.read<TripService>();
    final trip = tripService.getTripById(widget.tripId);
    if (trip != null) {
      _reasonForVisitController.text = trip.appointmentType ?? '';
      
      setState(() => _isFetchingTelematics = true);
      
      try {
        final telematics = await AzugaService.getTripTelematics(
          tripId: widget.tripId,
          startTime: trip.actualPickupTime ?? trip.scheduledPickupTime,
          endTime: DateTime.now(),
        );

        if (mounted) {
          const startOdo = 12450; 
          _pickupOdometerController.text = startOdo.toString();
          _dropoffOdometerController.text = (startOdo + telematics.actualMiles).round().toString();
          
          setState(() => _azugaDataLoaded = true);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Trip data auto-filled from Azuga Telematics'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to fetch telematics: $e');
      } finally {
        if (mounted) setState(() => _isFetchingTelematics = false);
      }
    }
  }

  @override
  void dispose() {
    _pickupOdometerController.dispose();
    _dropoffOdometerController.dispose();
    _reasonForVisitController.dispose();
    _escortNameController.dispose();
    _escortRelationshipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _tripMiles {
    final pickup = int.tryParse(_pickupOdometerController.text);
    final dropoff = int.tryParse(_dropoffOdometerController.text);
    if (pickup != null && dropoff != null && dropoff > pickup) {
      return (dropoff - pickup).toDouble();
    }
    return null;
  }

  Future<void> _submitTripReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_driverSignature == null) {
      _showError('Driver signature is required');
      return;
    }

    if (_memberSignature == null && !_memberUnableToSign) {
      _showError('Member signature is required (or mark as unable to sign)');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tripService = context.read<TripService>();
      final pickupOdometer = int.tryParse(_pickupOdometerController.text);
      final dropoffOdometer = int.tryParse(_dropoffOdometerController.text);

      await tripService.completeTripWithReport(
        widget.tripId,
        pickupOdometer: pickupOdometer,
        dropoffOdometer: dropoffOdometer,
        actualMiles: _tripMiles,
        reasonForVisit: _reasonForVisitController.text,
        escortName: _escortNameController.text.isNotEmpty ? _escortNameController.text : null,
        escortRelationship: _escortRelationshipController.text.isNotEmpty ? _escortRelationshipController.text : null,
        driverSignature: _driverSignature,
        memberSignature: _memberUnableToSign ? 'UNABLE_TO_SIGN' : _memberSignature,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) _showSuccess();
    } catch (e) {
      if (mounted) _showError('Failed to submit trip report: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
        title: Text('Report Submitted', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'AHCCCS Daily Trip Report has been successfully filed.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
             onPressed: () {
               Navigator.pop(context);
               context.go('/driver/dashboard'); // Back to dashboard usually
             },
             child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripService = context.watch<TripService>();
    final userService = context.watch<UserService>();
    final vehicleService = context.watch<VehicleService>();
    final trip = tripService.getTripById(widget.tripId);

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complete Trip')),
        body: const Center(child: Text('Trip not found')),
      );
    }

    final member = userService.getUserById(trip.memberId);
    final driver = userService.currentUser;
    final vehicle = vehicleService.selectedVehicle;
    final dateFormat = DateFormat('MM/dd/yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Trip Report', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
         bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.lightBorder, height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                   Text(
                     'AHCCCS REQUIREMENT', 
                     style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     'Please complete all fields to finalize this trip.',
                     textAlign: TextAlign.center,
                     style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                   ),
                   if (_isFetchingTelematics)
                     Padding(
                       padding: const EdgeInsets.only(top: 12),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                           const SizedBox(width: 8),
                           Text('Syncing Azuga...', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                         ],
                       ),
                     ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Provider & Driver Info
            _SectionHeader(title: 'General Information', icon: Icons.info_outline),
            _InfoCard(
              children: [
                _InfoRow(label: 'Provider', value: 'YazTrans NEMT Services'),
                if (driver != null) _InfoRow(label: 'Driver', value: driver.fullName),
                _InfoRow(label: 'Date', value: dateFormat.format(DateTime.now())),
                if (vehicle != null) _InfoRow(label: 'Vehicle', value: '${vehicle.make} (${vehicle.licensePlate})'),
              ],
            ),
            const SizedBox(height: 20),

             // Member Info
            _SectionHeader(title: 'Member Information', icon: Icons.person_outline),
            _InfoCard(
              children: [
                _InfoRow(label: 'Name', value: member?.fullName ?? 'Unknown'),
                _InfoRow(label: 'AHCCCS ID', value: member?.membershipId ?? trip.membershipId ?? 'N/A'),
                _InfoRow(label: 'DOB', value: member?.dateOfBirth ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 20),

            // Trip Details
            _SectionHeader(title: 'Trip Details', icon: Icons.map_outlined),
            _InfoCard(
              children: [
                _InfoRow(label: 'Pickup', value: trip.pickupAddress, isAddress: true),
                _InfoRow(label: 'Time', value: trip.actualPickupTime != null ? timeFormat.format(trip.actualPickupTime!) : 'N/A'),
                const Divider(height: 24),
                _InfoRow(label: 'Dropoff', value: trip.dropoffAddress, isAddress: true),
                _InfoRow(label: 'Time', value: timeFormat.format(DateTime.now())),
              ],
            ),
            const SizedBox(height: 20),

            // Odometer Readings
            _SectionHeader(title: 'Odometer Readings', icon: Icons.speed_rounded),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.lightBorder)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _OdometerField(
                      controller: _pickupOdometerController,
                      label: 'Pickup Odometer',
                      icon: Icons.trip_origin,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    _OdometerField(
                      controller: _dropoffOdometerController,
                      label: 'Drop-off Odometer',
                      icon: Icons.location_on,
                      color: AppColors.error,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_tripMiles != null) ...[
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Distance', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          Text('${_tripMiles!.toStringAsFixed(1)} mi', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Visit Reason
            _SectionHeader(title: 'Visit Information', icon: Icons.medical_services_outlined),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.lightBorder)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _reasonForVisitController,
                      decoration: InputDecoration(
                        labelText: 'Reason for Visit',
                        hintText: 'e.g. Diagnosis, Therapy',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                     TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Signatures
            _SectionHeader(title: 'Signatures', icon: Icons.draw_outlined),
            Text(
              'I certify that the information provided is accurate.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            
            SignatureCaptureWidget(
              title: 'Driver Signature',
              subtitle: driver?.fullName ?? 'Driver',
              onSignatureChanged: (s) => setState(() => _driverSignature = s),
            ),
            const SizedBox(height: 16),
            
            Opacity(
              opacity: _memberUnableToSign ? 0.5 : 1.0,
              child: IgnorePointer(
                ignoring: _memberUnableToSign,
                child: SignatureCaptureWidget(
                  title: 'Member Signature',
                  subtitle: member?.fullName ?? 'Member',
                  onSignatureChanged: (s) => setState(() => _memberSignature = s),
                ),
              ),
            ),
            
            Transform.translate(
              offset: const Offset(-8, 0),
              child: CheckboxListTile(
                title: Text('Member unable to sign', style: GoogleFonts.inter(fontSize: 14)),
                value: _memberUnableToSign,
                activeColor: AppColors.warning,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) => setState(() {
                  _memberUnableToSign = val ?? false;
                  if (_memberUnableToSign) _memberSignature = null;
                }),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTripReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isSubmitting 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Submit Report', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isAddress;

  const _InfoRow({required this.label, required this.value, this.isAddress = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value, 
              style: GoogleFonts.inter(
                fontSize: 14, 
                fontWeight: FontWeight.w600, 
                color: AppColors.textPrimary
              ),
              maxLines: isAddress ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OdometerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<String>? onChanged;

  const _OdometerField({required this.controller, required this.label, required this.icon, required this.color, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 2)),
      ),
    );
  }
}
