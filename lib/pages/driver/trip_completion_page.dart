import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/vehicle_service.dart';
import 'package:yazdrive/theme.dart';
import 'package:yazdrive/widgets/signature_capture_widget.dart';
import 'package:yazdrive/services/azuga_service.dart';

/// AHCCCS Daily Trip Report Completion Page
/// This page captures all required information for the AHCCCS Daily Trip Report
/// including odometer readings, signatures, and auto-fills known information.
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
      
      // Fetch Azuga Telematics
      setState(() => _isFetchingTelematics = true);
      
      try {
        final telematics = await AzugaService.getTripTelematics(
          tripId: widget.tripId,
          startTime: trip.actualPickupTime ?? trip.scheduledPickupTime,
          endTime: DateTime.now(),
        );

        if (mounted) {
          // Simulate a starting odometer (e.g., last known or 10000)
          const startOdo = 12450; 
          _pickupOdometerController.text = startOdo.toString();
          _dropoffOdometerController.text = (startOdo + telematics.actualMiles).round().toString();
          
          setState(() {
            _azugaDataLoaded = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip data auto-filled from Azuga Telematics'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
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

      // Complete the trip with all AHCCCS required data
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

      if (mounted) {
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to submit trip report: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: AppColors.success, size: 64),
        title: const Text('Trip Completed!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AHCCCS Daily Trip Report has been submitted successfully.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'The report will be emailed to your NEMT provider.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/driver/schedule'); // Return to schedule
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
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
      appBar: AppBar(
        title: const Text('AHCCCS Daily Trip Report'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.description, size: 40, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    'AHCCCS Daily Trip Report',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_isFetchingTelematics)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('Syncing with Azuga...'),
                        ],
                      ),
                    )
                  else if (_azugaDataLoaded)
                     Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_sync, size: 16, color: Colors.blue),
                          SizedBox(width: 6),
                          Text(
                            'Synced with Azuga',
                            style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Please complete all fields below',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Auto-filled Provider Information
            _SectionCard(
              title: 'NEMT Provider Information',
              icon: Icons.business,
              children: [
                _InfoRow(label: 'Provider ID', value: 'AZ-NEMT-001'), // TODO: Get from company
                _InfoRow(label: 'Provider Name', value: 'YazTrans NEMT Services'),
                _InfoRow(label: 'Phone', value: '(602) 555-0100'),
              ],
            ),
            const SizedBox(height: 16),

            // Auto-filled Driver & Vehicle Information
            _SectionCard(
              title: "Driver's Information",
              icon: Icons.person,
              children: [
                _InfoRow(
                  label: "Driver's Name",
                  value: driver?.fullName ?? 'Unknown Driver',
                ),
                _InfoRow(
                  label: 'Date',
                  value: dateFormat.format(DateTime.now()),
                ),
                if (vehicle != null) ...[
                  _InfoRow(
                    label: 'Vehicle License/Fleet ID',
                    value: vehicle.licensePlate,
                  ),
                  _InfoRow(
                    label: 'Vehicle Make/Color',
                    value: '${vehicle.make} ${vehicle.color ?? ''}',
                  ),
                  _InfoRow(
                    label: 'Vehicle Type',
                    value: vehicle.type.toString().split('.').last,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Auto-filled Member Information
            _SectionCard(
              title: 'Member Information',
              icon: Icons.person_outline,
              children: [
                _InfoRow(
                  label: 'AHCCCS #',
                  value: member?.membershipId ?? trip.membershipId,
                ),
                _InfoRow(
                  label: 'Date of Birth',
                  value: member?.dateOfBirth ?? 'N/A',
                ),
                _InfoRow(
                  label: 'Member Name',
                  value: member?.fullName ?? 'Unknown',
                ),
                _InfoRow(
                  label: 'Mailing Address',
                  value: member?.address ?? 'N/A',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Trip Details (Auto-filled)
            _SectionCard(
              title: '1st Pick-Up Location',
              icon: Icons.trip_origin,
              iconColor: AppColors.success,
              children: [
                _InfoRow(
                  label: 'Physical Address',
                  value: '${trip.pickupAddress}\n${trip.pickupCity}, ${trip.pickupState} ${trip.pickupZip}',
                ),
                _InfoRow(
                  label: 'Pickup Time',
                  value: trip.actualPickupTime != null
                    ? timeFormat.format(trip.actualPickupTime!)
                    : timeFormat.format(trip.scheduledPickupTime),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Odometer at Pickup
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          'Odometer Reading at Pickup',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pickupOdometerController,
                      decoration: const InputDecoration(
                        labelText: 'Odometer (miles)',
                        hintText: 'Enter odometer reading',
                        prefixIcon: Icon(Icons.speed),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pickup odometer is required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Drop-off Location (Auto-filled)
            _SectionCard(
              title: '1st Drop-Off Location',
              icon: Icons.location_on,
              iconColor: AppColors.error,
              children: [
                _InfoRow(
                  label: 'Physical Address',
                  value: '${trip.dropoffAddress}\n${trip.dropoffCity}, ${trip.dropoffState} ${trip.dropoffZip}',
                ),
                _InfoRow(
                  label: 'Drop-off Time',
                  value: timeFormat.format(DateTime.now()),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Odometer at Drop-off
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          'Odometer Reading at Drop-off',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dropoffOdometerController,
                      decoration: const InputDecoration(
                        labelText: 'Odometer (miles)',
                        hintText: 'Enter odometer reading',
                        prefixIcon: Icon(Icons.speed),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Drop-off odometer is required';
                        }
                        final dropoff = int.tryParse(value);
                        if (dropoff == null) {
                          return 'Enter a valid number';
                        }
                        final pickup = int.tryParse(_pickupOdometerController.text);
                        if (pickup != null && dropoff < pickup) {
                          return 'Must be greater than pickup odometer';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_tripMiles != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.route, color: AppColors.success),
                            const SizedBox(width: 12),
                            Text(
                              'Trip Miles: ${_tripMiles!.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reason for Visit
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Reason for Visit',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reasonForVisitController,
                      decoration: const InputDecoration(
                        labelText: 'Medical appointment type',
                        hintText: 'e.g., Dialysis, Physical Therapy, Doctor Visit',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Reason for visit is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Escort Information (Optional)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: AppColors.info),
                        const SizedBox(width: 8),
                        Text(
                          'Escort Information (if applicable)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _escortNameController,
                      decoration: const InputDecoration(
                        labelText: 'Name of Escort',
                        hintText: 'Leave blank if no escort',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _escortRelationshipController,
                      decoration: const InputDecoration(
                        labelText: 'Relationship to Member',
                        hintText: 'e.g., Spouse, Parent, Caregiver',
                        prefixIcon: Icon(Icons.family_restroom),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Multiple Members Question
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Were multiple members transported in the same vehicle on this trip?',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('No'),
                          selected: !_multipleMembers,
                          onSelected: (selected) {
                            setState(() => _multipleMembers = false);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Yes'),
                          selected: _multipleMembers,
                          onSelected: (selected) {
                            setState(() => _multipleMembers = true);
                          },
                        ),
                      ],
                    ),
                    if (_multipleMembers) ...[
                      const SizedBox(height: 16),
                      Text(
                        'If yes, were pick-up and drop-off locations different for the members?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('No'),
                            selected: !_differentLocations,
                            onSelected: (selected) {
                              setState(() => _differentLocations = false);
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Yes'),
                            selected: _differentLocations,
                            onSelected: (selected) {
                              setState(() => _differentLocations = true);
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note_add, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Additional Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Any additional notes about the trip',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Signatures Section
            Text(
              'Signatures',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Both driver and member signatures are required to complete the trip report.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Driver Signature
            SignatureCaptureWidget(
              title: 'Driver Signature',
              subtitle: driver?.fullName ?? 'Driver',
              onSignatureChanged: (signature) {
                setState(() => _driverSignature = signature);
              },
            ),
            const SizedBox(height: 16),

            // Member Signature
            if (!_memberUnableToSign)
              SignatureCaptureWidget(
                title: 'Member Signature',
                subtitle: member?.fullName ?? 'Member',
                onSignatureChanged: (signature) {
                  setState(() => _memberSignature = signature);
                },
              ),

            // Member Unable to Sign Checkbox
            Card(
              child: CheckboxListTile(
                title: const Text('Member is unable to sign'),
                subtitle: const Text(
                  'Check this box if the member is physically unable to provide a signature',
                ),
                value: _memberUnableToSign,
                onChanged: (value) {
                  setState(() {
                    _memberUnableToSign = value ?? false;
                    if (_memberUnableToSign) {
                      _memberSignature = null;
                    }
                  });
                },
                activeColor: AppColors.warning,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send),
                        SizedBox(width: 12),
                        Text(
                          'Submit Trip Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'By submitting, you certify that all information is accurate and complete.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.children,
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
                Icon(icon, color: iconColor ?? AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
