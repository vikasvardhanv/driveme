import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yazdrive/providers/app_init_provider.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'driver';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userService = context.read<UserService>();
    
    // Ensure users are loaded
    if (userService.users.isEmpty) {
      debugPrint('Users not loaded yet, loading now...');
      await userService.loadUsers();
    }
    
    debugPrint('Attempting login with email: ${_emailController.text.trim()}, role: $_selectedRole');
    debugPrint('Available users: ${userService.users.map((u) => '${u.email} (${u.role})').join(', ')}');
    
    final user = await userService.login(_emailController.text.trim(), _selectedRole);

    if (!mounted) return;

    if (user != null) {
      debugPrint('Login successful for user: ${user.firstName} ${user.lastName}');
      if (_selectedRole == 'driver') {
        context.go('/driver/dashboard');
      } else if (_selectedRole == 'admin' || _selectedRole == 'dispatcher') {
        context.go('/admin/dashboard');
      }
    } else {
      debugPrint('Login failed - no matching user found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials. Please try again.')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final appInit = context.watch<AppInitProvider>();
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: !appInit.isInitialized 
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Loading YazDrive...', style: Theme.of(context).textTheme.bodyMedium),
                ],
              )
            : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.local_hospital, size: 80, color: AppColors.primary),
                    const SizedBox(height: 24),
                    Text(
                      'YazDrive',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Non-Emergency Medical Transportation',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightBorder),
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.lightSurface,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Role', style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 12),
                          _RoleChip(
                            label: '🚗 Driver',
                            value: 'driver',
                            groupValue: _selectedRole,
                            onChanged: (value) => setState(() => _selectedRole = value),
                          ),
                          const SizedBox(height: 8),
                          _RoleChip(
                            label: '📋 Dispatcher',
                            value: 'dispatcher',
                            groupValue: _selectedRole,
                            onChanged: (value) => setState(() => _selectedRole = value),
                          ),
                          const SizedBox(height: 8),
                          _RoleChip(
                            label: '⚙️ Admin',
                            value: 'admin',
                            groupValue: _selectedRole,
                            onChanged: (value) => setState(() => _selectedRole = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: AppColors.info),
                              const SizedBox(width: 8),
                              Text('Demo Credentials', style: Theme.of(context).textTheme.titleSmall),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Driver: driver1@yazdrive.com', style: Theme.of(context).textTheme.bodySmall),
                          Text('Dispatcher: dispatcher1@yazdrive.com', style: Theme.of(context).textTheme.bodySmall),
                          Text('Admin: admin@yazdrive.com', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _RoleChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.lightBorder, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
