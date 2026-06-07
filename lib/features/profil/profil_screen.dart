import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../users/user_list_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String? _fullName;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await authService.getUserName();
    if (mounted) {
      setState(() {
        _fullName = name;
      });
    }
  }

  void _openUserManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UserListScreen()),
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profil', style: AppTypography.h2),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _UserCard(fullName: _fullName, roleLabel: authService.role.label),
          const SizedBox(height: 24),
          // Kullanıcı yönetimi yalnızca Admin + Patron'a görünür.
          if (authService.perms.canManageUsers) ...[
            _AdminSection(onUserManagement: _openUserManagement),
            const SizedBox(height: 24),
          ],
          _InfoSection(),
          const SizedBox(height: 32),
          _LogoutButton(onTap: _logout, isLoading: _isLoggingOut),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String? fullName;
  final String roleLabel;
  const _UserCard({required this.fullName, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName ?? '...',
                  style: AppTypography.h2.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
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

class _AdminSection extends StatelessWidget {
  final VoidCallback onUserManagement;
  const _AdminSection({required this.onUserManagement});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onUserManagement,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.manage_accounts_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Kullanıcı Yönetimi',
                    style: AppTypography.body.copyWith(
                        color: AppColors.slate800,
                        fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: AppColors.slate400),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.info_outline_rounded,
            label: 'Sürüm',
            value: '1.0.0',
          ),
          Divider(height: 1, color: AppColors.slate200, indent: 52),
          _InfoRow(
            icon: Icons.business_rounded,
            label: 'Sistem',
            value: 'Logo ERP',
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
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.slate400),
          const SizedBox(width: 12),
          Text(label, style: AppTypography.body.copyWith(color: AppColors.slate600)),
          const Spacer(),
          Text(value, style: AppTypography.body.copyWith(color: AppColors.slate500)),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _LogoutButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.logout_rounded, size: 20),
        label: Text(isLoading ? 'Çıkış yapılıyor...' : 'Çıkış Yap',
            style: AppTypography.button),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.negative,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}
