import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _organizationCtrl = TextEditingController();
  UserType _userType = UserType.student;

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _ageCtrl.dispose();
    _organizationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final isAvailable = await authService.isUsernameAvailable(
        _usernameCtrl.text,
      );
      if (!isAvailable) {
        setState(() {
          _error = 'Username is already taken';
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      final authProv = context.read<AuthProvider>();
      final fbUser = authProv.firebaseUser!;

      final user = UserModel(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        fullName: _fullNameCtrl.text.trim(),
        username: _usernameCtrl.text.trim().toLowerCase(),
        age: int.parse(_ageCtrl.text.trim()),
        userType: _userType,
        organization:
            _organizationCtrl.text.trim().isEmpty
                ? null
                : _organizationCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      await authProv.completeProfile(user);
      if (mounted && authProv.error != null) {
        setState(() => _error = authProv.error);
      }
    } catch (e) {
      setState(
        () =>
            _error =
                e.toString().contains('permission-denied')
                    ? 'Network or Permission Error. Try again.'
                    : e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Just a few more details to get you started!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.red500.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.red500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageCtrl,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Must be a number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _organizationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'University or Company (Optional)',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'I am a:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        title: 'Student',
                        imagePath: 'assets/images/student.png',
                        isSelected: _userType == UserType.student,
                        onTap:
                            () => setState(() => _userType = UserType.student),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _RoleCard(
                        title: 'Employee',
                        imagePath: 'assets/images/employee.png',
                        isSelected: _userType == UserType.employee,
                        onTap:
                            () => setState(() => _userType = UserType.employee),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                GradientButton(
                  label: _isLoading ? 'Saving...' : 'Complete Setup',
                  icon: Icons.check_circle_outline,
                  onTap: _isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.purple600.withAlpha(20)
                  : (isDark ? AppColors.dark800 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.purple600
                    : (isDark ? AppColors.dark600 : AppColors.gray200),
            width: 2,
          ),
          boxShadow:
              isDark || isSelected
                  ? null
                  : [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color:
                    isSelected
                        ? AppColors.purple600
                        : (isDark ? Colors.white : AppColors.gray800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
