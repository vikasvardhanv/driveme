import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yazdrive/services/vehicle_service.dart';
import 'package:yazdrive/models/vehicle_model.dart';
import 'package:yazdrive/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yazdrive/widgets/driver_drawer.dart';

/// Vehicle confirmation page shown when driver taps "Start Taking Trips".
/// Driver must search and confirm their vehicle before proceeding.
class VehicleConfirmationPage extends StatefulWidget {
  const VehicleConfirmationPage({super.key});

  @override
  State<VehicleConfirmationPage> createState() => _VehicleConfirmationPageState();
}

class _VehicleConfirmationPageState extends State<VehicleConfirmationPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  VehicleModel? _matchingVehicle; // Auto-matched vehicle

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleService>().loadVehicles();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      // Auto-match logic if needed, or wait for user to select from autosuggestions
      // For now, let's keep it simple: as they type, we show suggestions.
    });
  }

  void _onVehicleSelected(VehicleModel vehicle, VehicleService service) {
    // Show confirmation view
    setState(() {
      _matchingVehicle = vehicle;
    });
  }

  void _confirmVehicle(VehicleService service) {
    if (_matchingVehicle != null) {
      service.selectVehicle(_matchingVehicle!);
      context.go('/driver/trips');
    }
  }

  void _goBackToSearch() {
    setState(() {
      _matchingVehicle = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicleService = context.watch<VehicleService>();

    // Show confirmation view if vehicle is selected
    if (_matchingVehicle != null) {
      return _buildConfirmationView(vehicleService);
    }

    // Show search view
    final filteredVehicles = _searchQuery.isEmpty
        ? <VehicleModel>[]
        : vehicleService.searchVehicles(_searchQuery);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const DriverDrawer(),
      appBar: AppBar(
        title: Text('VEHICLE SELECTION', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          TextButton(
             onPressed: () => context.go('/driver/dashboard'),
             child: Text('Overview', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          )
        ],
      ),
      body: Column(
        children: [
          // Header Image & Text
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car_rounded, size: 56, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(height: 16),
                    Text(
                      'Which vehicle are you driving?',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Container(height: 3, width: 60, color: AppColors.secondary),
                  ],
                ),
              ),
            ],
          ),

          // Selection Input
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            color: AppColors.lightBackground,
            width: double.infinity,
            child: Text(
              'SELECT YOUR VEHICLE',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.5, fontSize: 13),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Enter license plate or vehicle number',
                  hintStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(18),
                  prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 24),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),

          // Suggestions List or Empty State
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: AppColors.textDisabled),
                        const SizedBox(height: 16),
                        Text(
                          'Start typing to search vehicles',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search by license plate, VIN, or vehicle name',
                          style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : filteredVehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.no_crash_outlined, size: 64, color: AppColors.textDisabled),
                            const SizedBox(height: 16),
                            Text(
                              'No vehicles found',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = filteredVehicles[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.lightBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () => _onVehicleSelected(vehicle, vehicleService),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          vehicle.wheelchairAccessible
                                              ? Icons.accessible_forward_rounded
                                              : Icons.directions_car_rounded,
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
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
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
                                            const SizedBox(height: 2),
                                            Text(
                                              vehicle.color,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationView(VehicleService vehicleService) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text('CONFIRM VEHICLE', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBackToSearch,
        ),
        actions: [
          TextButton(
             onPressed: () => context.go('/driver/dashboard'),
             child: Text('Overview', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          )
        ],
      ),
      body: _VehicleConfirmationView(
        vehicle: _matchingVehicle!,
        getTypeLabel: (type) {
          switch (type) {
            case VehicleType.sedan: return 'Sedan';
            case VehicleType.suv: return 'SUV';
            case VehicleType.van: return 'Van';
            case VehicleType.wheelchairVan: return 'Wheelchair Van';
            case VehicleType.ambulette: return 'Ambulette';
          }
        },
        onWrongVehicle: _goBackToSearch,
        onConfirm: () => _confirmVehicle(vehicleService),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Vehicle Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              vehicle.wheelchairAccessible
                  ? Icons.accessible_forward_rounded
                  : Icons.directions_car_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 32),

          // Vehicle Details Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${vehicle.make} ${vehicle.model}',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${vehicle.year} • ${vehicle.color}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: AppColors.lightBorder,
                ),
                const SizedBox(height: 24),

                // License Plate
                _InfoRow(
                  icon: Icons.credit_card_rounded,
                  label: 'License Plate',
                  value: vehicle.licensePlate,
                ),
                const SizedBox(height: 16),

                // Vehicle Number
                _InfoRow(
                  icon: Icons.tag_rounded,
                  label: 'Vehicle ID',
                  value: vehicle.id.substring(0, 8).toUpperCase(),
                ),

                const SizedBox(height: 24),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: AppColors.lightBorder,
                ),
                const SizedBox(height: 24),

                // Service Types
                Text(
                  'SERVICE TYPES',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vehicle.wheelchairAccessible
                            ? Icons.accessible_forward_rounded
                            : Icons.person_rounded,
                        size: 22,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        vehicle.wheelchairAccessible
                            ? 'Wheelchair & Ambulatory'
                            : 'Ambulatory',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Confirm Button
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'CONFIRM THIS VEHICLE',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Wrong Vehicle Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: OutlinedButton(
              onPressed: onWrongVehicle,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.lightBorder, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'WRONG VEHICLE',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


