import 'package:flutter/material.dart';
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/theme.dart';

/// Modal dialog showing mandatory trip instructions that must be confirmed
/// before proceeding with pickup. All checkboxes must be checked.
class TripInstructionsModal extends StatefulWidget {
  final TripModel trip;
  final VoidCallback onConfirm;

  const TripInstructionsModal({
    super.key,
    required this.trip,
    required this.onConfirm,
  });

  static Future<bool> show(BuildContext context, TripModel trip) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripInstructionsModal(
        trip: trip,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  State<TripInstructionsModal> createState() => _TripInstructionsModalState();
}

class _TripInstructionsModalState extends State<TripInstructionsModal> {
  late List<_InstructionItem> _instructions;
  
  @override
  void initState() {
    super.initState();
    _instructions = _buildInstructions();
  }

  List<_InstructionItem> _buildInstructions() {
    final instructions = <_InstructionItem>[];
    
    // Standard instruction
    instructions.add(_InstructionItem(
      icon: Icons.person,
      text: 'Verify member identity before pickup',
      isChecked: false,
    ));
    
    // Mobility aid instruction
    if (widget.trip.mobilityAid != 'none') {
      instructions.add(_InstructionItem(
        icon: Icons.accessible,
        text: 'Member requires ${widget.trip.mobilityAid} assistance',
        isChecked: false,
      ));
    }
    
    // Door-to-door assistance
    if (widget.trip.specialRequirements?.toLowerCase().contains('door') == true) {
      instructions.add(_InstructionItem(
        icon: Icons.door_front_door,
        text: 'Provide door-to-door assistance',
        isChecked: false,
      ));
    }
    
    // Attendant instruction
    if (widget.trip.requiresAttendant) {
      instructions.add(_InstructionItem(
        icon: Icons.people,
        text: 'Member has ${widget.trip.attendantCount} attendant(s) - verify all are present',
        isChecked: false,
      ));
    }
    
    // Oxygen instruction
    if (widget.trip.oxygenRequired) {
      instructions.add(_InstructionItem(
        icon: Icons.air,
        text: 'Member requires oxygen - ensure equipment is secure',
        isChecked: false,
      ));
    }
    
    // Special requirements
    if (widget.trip.specialRequirements != null && 
        widget.trip.specialRequirements!.isNotEmpty &&
        !widget.trip.specialRequirements!.toLowerCase().contains('door')) {
      instructions.add(_InstructionItem(
        icon: Icons.warning_amber,
        text: widget.trip.specialRequirements!,
        isChecked: false,
      ));
    }
    
    // Safety acknowledgment
    instructions.add(_InstructionItem(
      icon: Icons.security,
      text: 'Ensure member is safely secured in vehicle',
      isChecked: false,
    ));
    
    return instructions;
  }

  bool get _allChecked => _instructions.every((i) => i.isChecked);

  void _toggleInstruction(int index) {
    setState(() {
      _instructions[index].isChecked = !_instructions[index].isChecked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment, color: AppColors.warning, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Instructions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Please confirm all items before proceeding',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Instructions list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _instructions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final instruction = entry.value;
                  return _InstructionCheckbox(
                    instruction: instruction,
                    onToggle: () => _toggleInstruction(index),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Confirm button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _allChecked ? widget.onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _allChecked ? 'Confirm & Begin Pickup' : 'Check all items to continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _allChecked ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _InstructionItem {
  final IconData icon;
  final String text;
  bool isChecked;

  _InstructionItem({
    required this.icon,
    required this.text,
    required this.isChecked,
  });
}

class _InstructionCheckbox extends StatelessWidget {
  final _InstructionItem instruction;
  final VoidCallback onToggle;

  const _InstructionCheckbox({
    required this.instruction,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: instruction.isChecked 
                ? AppColors.success.withOpacity(0.1)
                : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: instruction.isChecked 
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.lightBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: instruction.isChecked ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: instruction.isChecked ? AppColors.success : AppColors.textSecondary,
                    width: 2,
                  ),
                ),
                child: instruction.isChecked
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: 16),
              Icon(
                instruction.icon,
                color: instruction.isChecked ? AppColors.success : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  instruction.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: instruction.isChecked ? AppColors.success : null,
                    fontWeight: instruction.isChecked ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
