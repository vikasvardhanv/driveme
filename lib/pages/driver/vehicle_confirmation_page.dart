import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yazdrive/services/vehicle_service.dart';
import 'package:yazdrive/models/vehicle_model.dart';
import 'package:yazdrive/theme.dart';

/// Vehicle confirmation page shown when driver taps "Start Taking Trips".
/// Driver must search and confirm their vehicle before proceeding.
class VehicleConfirmationPage extends StatefulWidget {
  const VehicleConfirmationPage({super.key});

  @override
  State<VehicleConfirmationPage> createState() => _VehicleConfirmationPageState();
}

class _VehicleConfirmationPageState extends State<VehicleConfirmationPage> {
  final _searchController = TextEditingController();
  VehicleModel? _selectedVehicle;
  List<VehicleModel> _filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vehicleService = context.read<VehicleService>();
      if (vehicleService.vehicles.isEmpty) {
        vehicleService.loadVehicles();
      }
      _filteredVehicles = vehicleService.activeVehicles;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchVehicles(String query, VehicleService vehicleService) {
    setState(() {
      if (query.isEmpty) {
        _filteredVehicles = vehicleService.activeVehicles;
      } else {
        _filteredVehicles = vehicleService.activeVehicles.where((v) =>
          v.licensePlate.toLowerCase().contains(query.toLowerCase()) ||
          v.vin.toLowerCase().contains(query.toLowerCase()) ||
          v.make.toLowerCase().contains(query.toLowerCase()) ||
          v.model.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  void _selectVehicle(VehicleModel vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
    });
  }

  void _confirmVehicle(VehicleService vehicleService) {
    if (_selectedVehicle != null) {
      vehicleService.selectVehicle(_selectedVehicle!);
      context.go('/driver/schedule');
    }
  }

  String _getVehicleTypeLabel(VehicleType type) {
    switch (type) {
      case VehicleType.sedan:
        return 'Sedan';
      case VehicleType.van:
        return 'Van (Ambulatory)';
      case VehicleType.wheelchairVan:
        return 'Wheelchair Van';
      case VehicleType.ambulette:
        return 'Ambulette';
      case VehicleType.suv:
        return 'SUV';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleService = context.watch<VehicleService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Vehicle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver/dashboard'),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by license plate or vehicle number',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.lightSurface,
              ),
              onChanged: (query) => _searchVehicles(query, vehicleService),
            ),
          ),
          
          // Vehicle list or selected vehicle details
          Expanded(
            child: _selectedVehicle != null
                ? _VehicleConfirmationView(
                    vehicle: _selectedVehicle!,
                    getTypeLabel: _getVehicleTypeLabel,
                    onWrongVehicle: () {
                      setState(() {
                        _selectedVehicle = null;
                      });
                    },
                    onConfirm: () => _confirmVehicle(vehicleService),
                  )
                : _VehicleListView(
                    vehicles: _filteredVehicles,
                    isLoading: vehicleService.isLoading,
                    getTypeLabel: _getVehicleTypeLabel,
                    onSelect: _selectVehicle,
                  ),
          ),
        ],
      ),
    );
  }
}

class _VehicleListView extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final bool isLoading;
  final String Function(VehicleType) getTypeLabel;
  final Function(VehicleModel) onSelect;

  const _VehicleListView({
    required this.vehicles,
    required this.isLoading,
    required this.getTypeLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              'No vehicles found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return _VehicleCard(
          vehicle: vehicle,
          getTypeLabel: getTypeLabel,
          onTap: () => onSelect(vehicle),
        );
      },
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final String Function(VehicleType) getTypeLabel;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    required this.getTypeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  vehicle.wheelchairAccessible 
                      ? Icons.accessible 
                      : Icons.directions_car,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.licensePlate,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      getTypeLabel(vehicle.type),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleConfirmationView extends StatelessWidget {
  final VehicleModel vehicle;
  final String Function(VehicleType) getTypeLabel;
  final VoidCallback onWrongVehicle;
  final VoidCallback onConfirm;

  const _VehicleConfirmationView({
    required this.vehicle,
    required this.getTypeLabel,
    required this.onWrongVehicle,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Vehicle image placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              vehicle.wheelchairAccessible 
                  ? Icons.accessible 
                  : Icons.directions_car,
              color: AppColors.primary,
              size: 64,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Confirm Your Vehicle',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Vehicle details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _DetailRow(label: 'License Plate', value: vehicle.licensePlate),
                  const Divider(height: 24),
                  _DetailRow(label: 'Make', value: vehicle.make),
                  const Divider(height: 24),
                  _DetailRow(label: 'Model', value: vehicle.model),
                  const Divider(height: 24),
                  _DetailRow(label: 'Year', value: vehicle.year.toString()),
                  const Divider(height: 24),
                  _DetailRow(label: 'Color', value: vehicle.color),
                  const Divider(height: 24),
                  _DetailRow(label: 'Vehicle Type', value: getTypeLabel(vehicle.type)),
                  if (vehicle.wheelchairAccessible) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.accessible, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Wheelchair Accessible',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (vehicle.hasOxygen) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.air, color: AppColors.info, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Oxygen Equipped',
                          style: TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm This Vehicle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextButton(
            onPressed: onWrongVehicle,
            child: Text(
              'Wrong Vehicle? Go Back',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
