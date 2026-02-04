import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yazdrive/services/vehicle_service.dart';
import 'package:yazdrive/models/vehicle_model.dart';
import 'package:yazdrive/theme.dart';
import 'package:google_fonts/google_fonts.dart';

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
      // Always fetch fresh data as requested
      vehicleService.loadVehicles();

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
      context.go('/driver/dashboard'); // Corrected route to dashboard/schedule
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
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text('VEHICLE SELECTION', style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/driver/dashboard'),
        ),
        elevation: 0,
        backgroundColor: AppColors.lightSurface,
      ),
      body: Column(
        children: [
          // Search Header with Gradient
          if (_selectedVehicle == null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                border: Border(bottom: BorderSide(color: AppColors.lightBorder)),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search license plate or vehicle #',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.lightSurfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (query) => _searchVehicles(query, vehicleService),
              ),
            ),
          
          // Main Content
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_car_outlined, size: 48, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 24),
            Text(
              'No vehicles found',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different term',
              style: GoogleFonts.inter(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    vehicle.wheelchairAccessible 
                        ? Icons.accessible_forward_rounded 
                        : Icons.directions_car_filled_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.licensePlate,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Tag(label: getTypeLabel(vehicle.type), color: AppColors.textSecondary),
                          if (vehicle.wheelchairAccessible) ...[
                            const SizedBox(width: 8),
                            const _Tag(label: 'WAV', color: AppColors.primary, isAccent: true),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final bool isAccent;

  const _Tag({required this.label, required this.color, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAccent ? color.withOpacity(0.1) : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isAccent ? color.withOpacity(0.2) : Colors.transparent),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isAccent ? color : color,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 8),
            ),
            child: Icon(
              vehicle.wheelchairAccessible 
                  ? Icons.accessible_forward_rounded 
                  : Icons.directions_car_rounded,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Confirm Vehicle',
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          Text(
             'Is this the vehicle you are driving today?',
             style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary),
             textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Column(
              children: [
                _BigDetail(label: 'LICENSE PLATE', value: vehicle.licensePlate),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(),
                ),
                _GridDetail(
                  leftLabel: 'Make / Model',
                  leftValue: '${vehicle.make} ${vehicle.model}',
                  rightLabel: 'Year',
                  rightValue: '${vehicle.year}',
                ),
                const SizedBox(height: 24),
                _GridDetail(
                  leftLabel: 'Color',
                  leftValue: vehicle.color,
                  rightLabel: 'Type',
                  rightValue: getTypeLabel(vehicle.type),
                ),
                
                if (vehicle.wheelchairAccessible || vehicle.hasOxygen) ...[
                   const SizedBox(height: 24),
                   Row(
                     children: [
                       if (vehicle.wheelchairAccessible)
                         Expanded(child: _FeatureBadge(icon: Icons.accessible_forward, label: 'Wheelchair', color: AppColors.primary)),
                       if (vehicle.wheelchairAccessible && vehicle.hasOxygen)
                         const SizedBox(width: 12),
                       if (vehicle.hasOxygen)
                         Expanded(child: _FeatureBadge(icon: Icons.medical_services_outlined, label: 'Oxygen', color: AppColors.secondary)),
                     ],
                   )
                ]
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Swipe to Confirm (Simulated with Button for now, or Custom Widget)
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CONFIRM VEHICLE',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 24),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          TextButton(
            onPressed: onWrongVehicle,
            child: Text(
              'Select a different vehicle',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 16
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigDetail extends StatelessWidget {
  final String label;
  final String value;
  
  const _BigDetail({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _GridDetail extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _GridDetail({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(leftLabel, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
               const SizedBox(height: 4),
               Text(leftValue, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
        Container(width: 1, height: 40, color: AppColors.lightBorder),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(rightLabel, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
               const SizedBox(height: 4),
               Text(rightValue, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
