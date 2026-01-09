import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/vehicle_service.dart';
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/models/user_model.dart';
import 'package:yazdrive/theme.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickupAddressController = TextEditingController();
  final _pickupCityController = TextEditingController();
  final _pickupZipController = TextEditingController();
  final _dropoffAddressController = TextEditingController();
  final _dropoffCityController = TextEditingController();
  final _dropoffZipController = TextEditingController();
  final _authNumberController = TextEditingController();
  final _facilityNameController = TextEditingController();
  
  String? _selectedMemberId;
  String? _selectedDriverId;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 9, minute: 0);
  String _mobilityAid = 'none';
  String _appointmentType = 'Medical';
  String _priority = 'routine';
  bool _requiresAttendant = false;
  bool _oxygenRequired = false;

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _pickupCityController.dispose();
    _pickupZipController.dispose();
    _dropoffAddressController.dispose();
    _dropoffCityController.dispose();
    _dropoffZipController.dispose();
    _authNumberController.dispose();
    _facilityNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    final tripService = context.read<TripService>();
    final userService = context.read<UserService>();
    final member = userService.getUserById(_selectedMemberId!);

    final scheduledDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    final trip = TripModel(
      id: tripService.createTripId(),
      memberId: _selectedMemberId!,
      driverId: _selectedDriverId,
      tripType: TripType.oneWay,
      status: _selectedDriverId != null ? TripStatus.assigned : TripStatus.scheduled,
      scheduledPickupTime: scheduledDateTime,
      pickupAddress: _pickupAddressController.text,
      pickupCity: _pickupCityController.text,
      pickupState: 'AZ',
      pickupZip: _pickupZipController.text,
      dropoffAddress: _dropoffAddressController.text,
      dropoffCity: _dropoffCityController.text,
      dropoffState: 'AZ',
      dropoffZip: _dropoffZipController.text,
      appointmentType: _appointmentType,
      facilityName: _facilityNameController.text.isEmpty ? null : _facilityNameController.text,
      mobilityAid: _mobilityAid,
      requiresAttendant: _requiresAttendant,
      attendantCount: _requiresAttendant ? 1 : 0,
      oxygenRequired: _oxygenRequired,
      authorizationNumber: _authNumberController.text,
      membershipId: member?.membershipId ?? 'N/A',
      priority: _priority,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tripService.addTrip(trip);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip created successfully')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final members = userService.members;
    final drivers = userService.drivers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Trip'),
        actions: [
          TextButton(
            onPressed: _createTrip,
            child: const Text('CREATE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Member Selection', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedMemberId,
              decoration: const InputDecoration(
                labelText: 'Select Member',
                prefixIcon: Icon(Icons.person),
              ),
              items: members.map((member) => DropdownMenuItem(
                value: member.id,
                child: Text('\${member.fullName} (\${member.membershipId})'),
              )).toList(),
              onChanged: (value) => setState(() => _selectedMemberId = value),
              validator: (value) => value == null ? 'Please select a member' : null,
            ),
            const SizedBox(height: 24),
            Text('Schedule', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text('\${_scheduledDate.month}/\${_scheduledDate.day}/\${_scheduledDate.year}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_scheduledTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Pickup Location', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pickupAddressController,
              decoration: const InputDecoration(labelText: 'Pickup Address', prefixIcon: Icon(Icons.home)),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _pickupCityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pickupZipController,
                    decoration: const InputDecoration(labelText: 'ZIP'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Dropoff Location', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dropoffAddressController,
              decoration: const InputDecoration(labelText: 'Dropoff Address', prefixIcon: Icon(Icons.location_on)),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dropoffCityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dropoffZipController,
                    decoration: const InputDecoration(labelText: 'ZIP'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Trip Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _appointmentType,
              decoration: const InputDecoration(labelText: 'Appointment Type'),
              items: ['Medical', 'Pharmacy', 'Dialysis', 'Therapy', 'Other'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) => setState(() => _appointmentType = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _facilityNameController,
              decoration: const InputDecoration(labelText: 'Facility Name (Optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mobilityAid,
              decoration: const InputDecoration(labelText: 'Mobility Aid'),
              items: ['none', 'walker', 'wheelchair', 'cane'].map((aid) => DropdownMenuItem(value: aid, child: Text(aid.toUpperCase()))).toList(),
              onChanged: (value) => setState(() => _mobilityAid = value!),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Requires Attendant'),
              value: _requiresAttendant,
              onChanged: (value) => setState(() => _requiresAttendant = value),
            ),
            SwitchListTile(
              title: const Text('Oxygen Required'),
              value: _oxygenRequired,
              onChanged: (value) => setState(() => _oxygenRequired = value),
            ),
            const SizedBox(height: 24),
            Text('Authorization', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _authNumberController,
              decoration: const InputDecoration(labelText: 'Authorization Number', prefixIcon: Icon(Icons.verified)),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: ['routine', 'urgent', 'emergent'].map((priority) => DropdownMenuItem(value: priority, child: Text(priority.toUpperCase()))).toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: 24),
            Text('Driver Assignment (Optional)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDriverId,
              decoration: const InputDecoration(labelText: 'Assign Driver', prefixIcon: Icon(Icons.local_shipping)),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                ...drivers.map((driver) => DropdownMenuItem(value: driver.id, child: Text(driver.fullName))),
              ],
              onChanged: (value) => setState(() => _selectedDriverId = value),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createTrip,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Create Trip'),
            ),
          ],
        ),
      ),
    );
  }
}
