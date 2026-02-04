import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yazdrive/providers/app_init_provider.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/location_service.dart';
import 'package:yazdrive/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'driver';
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userService = context.read<UserService>();
    
    // Ensure users are loaded
    if (userService.users.isEmpty) {
      await userService.loadUsers();
    }
    
    final user = await userService.login(_emailController.text.trim(), _passwordController.text, _selectedRole);

    if (!mounted) return;

    if (user != null) {
      if (_selectedRole == 'driver') {
        final tripService = context.read<TripService>();
        final locationService = context.read<LocationService>();

        tripService.initializeSocketConnection(user.id);
        locationService.initSocket(user.id);
        await tripService.fetchTripsFromBackend(user.id);

        if (mounted) context.go('/driver/dashboard');
      } else if (_selectedRole == 'admin' || _selectedRole == 'dispatcher') {
        context.go('/admin/dashboard');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid credentials. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final appInit = context.watch<AppInitProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: !appInit.isInitialized 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo/Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.local_hospital_rounded, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    
                    // Welcome Text
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to access your dashboard',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),

                    // Email Field
                    _PremiumTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'name@company.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                         if (value == null || value.isEmpty) return 'Please enter your email';
                         if (!value.contains('@')) return 'Please enter a valid email';
                         return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),

                    // Password Field
                    _PremiumTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onPasswordToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      validator: (value) => (value == null || value.isEmpty) ? 'Please enter your password' : null,
                    ),

                    const SizedBox(height: 24),
                    
                    // Role Selection
                    Text(
                      'I AM A',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                       padding: const EdgeInsets.all(4),
                       decoration: BoxDecoration(
                         color: AppColors.lightSurface,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: AppColors.lightBorder),
                       ),
                       child: Row(
                         children: [
                           Expanded(
                             child: _RoleSelectionItem(
                               label: 'Driver',
                               isSelected: _selectedRole == 'driver',
                               onTap: () => setState(() => _selectedRole = 'driver'),
                             ),
                           ),
                           Expanded(
                             child: _RoleSelectionItem(
                               label: 'Dispatcher',
                               isSelected: _selectedRole == 'dispatcher',
                               onTap: () => setState(() => _selectedRole = 'dispatcher'),
                             ),
                           ),
                           Expanded(
                             child: _RoleSelectionItem(
                               label: 'Admin',
                               isSelected: _selectedRole == 'admin',
                               onTap: () => setState(() => _selectedRole = 'admin'),
                             ),
                           ),
                         ],
                       ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                           BoxShadow(
                             color: AppColors.primary.withOpacity(0.3),
                             blurRadius: 16,
                             offset: const Offset(0, 8),
                           ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                'Sign In',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Footer Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('New Driver? ', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                        TextButton(
                          onPressed: () => context.push('/driver/apply'),
                          child: Text(
                            'Apply Here', 
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    
                    // Demo Credentials Box (Subtle)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.terminal_rounded, size: 16, color: AppColors.textTertiary),
                              const SizedBox(width: 8),
                              Text('DEMO ACCESS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.5)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _DemoCredentialRow(label: 'Driver', email: 'driver@yazdrive.com'),
                          _DemoCredentialRow(label: 'Dispatch', email: 'dispatch@yazdrive.com'),
                          const Divider(height: 16),
                          Text('Password for all: password123', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onPasswordToggle;
  final TextInputType? keyboardType;
  final String? Function(String?) validator;

  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onPasswordToggle,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.textDisabled),
            prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textTertiary,
                      size: 22,
                    ),
                    onPressed: onPasswordToggle,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _RoleSelectionItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectionItem({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected 
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] 
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _DemoCredentialRow extends StatelessWidget {
  final String label;
  final String email;

  const _DemoCredentialRow({required this.label, required this.email});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:', 
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Text(
            email, 
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
