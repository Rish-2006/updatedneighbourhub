import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/auth_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _photoUrlController;
  late TextEditingController _emergencyNoteController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _photoUrlController = TextEditingController(text: user?.photoUrl ?? '');
    _emergencyNoteController = TextEditingController(text: user?.emergencyNote ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _photoUrlController.dispose();
    _emergencyNoteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authUser = ref.read(authStateProvider).value;
      if (authUser == null) {
        throw Exception('User not authenticated');
      }

      final updatedUser = UserModel(
        uid: authUser.uid,
        email: authUser.email,
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoUrl: _photoUrlController.text.trim().isNotEmpty
            ? _photoUrlController.text.trim()
            : null,
        emergencyNote: _emergencyNoteController.text.trim().isNotEmpty
            ? _emergencyNoteController.text.trim()
            : null,
        createdAt: authUser.createdAt,
      );

      final userRepository = ref.read(userRepositoryProvider);
      await userRepository.updateUserProfile(updatedUser);
      ref.read(authRepositoryProvider).updateCurrentUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile setup complete! Welcome to NeighbourHub.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Safety Profile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please set up your profile details. Trusted contacts will see your name and contact number during panic alerts.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              // Full Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g. Jane Doe',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'e.g. +1 555-0199',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Phone number is required for safety alerts';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Profile Photo URL
              TextFormField(
                controller: _photoUrlController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Profile Photo URL (Optional)',
                  hintText: 'https://example.com/avatar.jpg',
                  prefixIcon: Icon(Icons.image_outlined, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 20),
              // Emergency Note
              TextFormField(
                controller: _emergencyNoteController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Emergency Medical / Note (Optional)',
                  hintText: 'e.g. Blood Type O+, Asthma, Emergency contact note...',
                  prefixIcon: Icon(Icons.medical_information_outlined, color: AppColors.coral),
                ),
              ),
              const SizedBox(height: 36),
              CustomButton(
                text: 'Save & Continue',
                isLoading: _isLoading,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
