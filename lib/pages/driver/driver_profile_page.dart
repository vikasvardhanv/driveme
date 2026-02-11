import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/theme.dart';
import 'package:yazdrive/constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Driver profile page showing driver details synced with Dispatch backend
class DriverProfilePage extends StatelessWidget {
  const DriverProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final driver = userService.currentUser;

    if (driver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for global background
      appBar: AppBar(
        title: const Text('Driver Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            _ProfileHeader(driver: driver),
            const SizedBox(height: 24),
            
            // Contact information
            _SectionCard(
              title: 'Contact Information',
              icon: Icons.contact_mail,
              children: [
                _InfoRow(label: 'Email', value: driver.email),
                _InfoRow(label: 'Phone', value: driver.phoneNumber),
              ],
            ),
            const SizedBox(height: 16),
            
            // License information
            _SectionCard(
              title: 'License Information',
              icon: Icons.badge,
              children: [
                _InfoRow(
                  label: 'License Number',
                  value: driver.licenseNumber ?? 'Not provided',
                ),
                _InfoRow(
                  label: 'License Expiry',
                  value: driver.licenseExpiry != null
                      ? DateFormat('MMM d, yyyy').format(driver.licenseExpiry!)
                      : 'Not provided',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Certifications
            if (driver.certifications != null && driver.certifications!.isNotEmpty)
              _SectionCard(
                title: 'Certifications',
                icon: Icons.verified,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: driver.certifications!
                        .map((cert) => Chip(
                              label: Text(cert),
                              backgroundColor: AppColors.success.withOpacity(0.1),
                              labelStyle: TextStyle(color: AppColors.success),
                            ))
                        .toList(),
                  ),
                ],
              ),
            
            const SizedBox(height: 32),
            
            // Account info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // Opaque container for readability
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                   BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Account Created',
                    value: DateFormat('MMM d, yyyy').format(driver.createdAt),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Last Updated',
                    value: DateFormat('MMM d, yyyy').format(driver.updatedAt),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // App Support
            _SectionCard(
              title: 'App Support',
              icon: Icons.headset_mic,
              children: [
                _ContactRow(
                  label: AppConstants.driverHotlineLabel,
                  value: AppConstants.driverHotline,
                  icon: Icons.phone_in_talk,
                  isPrimary: true,
                ),
                _ContactRow(
                  label: AppConstants.generalSupportLabel,
                  value: AppConstants.generalPhoneNumber,
                  icon: Icons.phone,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic driver;

  const _ProfileHeader({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              driver.firstName[0] + driver.lastName[0],
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            driver.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  driver.isActive ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  driver.isActive ? 'Active Driver' : 'Inactive',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isPrimary;

  const _ContactRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isPrimary = false,
  });

  Future<void> _makeCall(BuildContext context) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: value.replaceAll(RegExp(r'[^\d]'), ''),
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _makeCall(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isPrimary ? Border.all(color: AppColors.primary.withOpacity(0.1)) : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPrimary ? AppColors.primary.withOpacity(0.1) : AppColors.lightSurfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isPrimary ? AppColors.primary : AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
