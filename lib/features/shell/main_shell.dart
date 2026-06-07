import 'package:flutter/material.dart';
import '../../core/auth/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../auth/auth_service.dart';
import '../belgeler/belgeler_screen.dart';
import '../cari/cari_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../malzeme/malzeme_list_screen.dart';
import '../patron/patron_screen.dart';
import '../profil/profil_screen.dart';
import '../rapor/rapor_hub_screen.dart';

/// Alt sekme tanımı — yetkiye göre dinamik kurulur.
class _TabDef {
  final IconData icon;
  final String label;
  final Widget screen;
  const _TabDef(this.icon, this.label, this.screen);
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Sekmeler aktif kullanıcının yetkisine göre kurulur.
  // Satışçı şirket raporlarını görmediği için Raporlar sekmesi gizlenir.
  late final List<_TabDef> _tabs;

  @override
  void initState() {
    super.initState();
    final Permissions perms = authService.perms;
    _tabs = [
      const _TabDef(Icons.home_rounded, 'Ana', DashboardScreen()),
      const _TabDef(Icons.people_rounded, 'Cariler', CariListScreen()),
      const _TabDef(Icons.inventory_2_rounded, 'Stok', MalzemeListScreen()),
      const _TabDef(Icons.folder_rounded, 'Belgeler', BelgelerScreen()),
      // Patron paneli — yetkiye bağlı (Patron/Muhasebe/Admin varsayılan).
      if (perms.canViewPatronPanel)
        const _TabDef(Icons.insights_rounded, 'Patron', PatronScreen()),
      if (perms.canViewReports)
        const _TabDef(Icons.bar_chart_rounded, 'Raporlar', RaporHubScreen()),
      const _TabDef(Icons.person_rounded, 'Profil', ProfilScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [for (final t in _tabs) t.screen],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int i = 0; i < _tabs.length; i++)
                    _buildTab(i, _tabs[i].icon, _tabs[i].label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    final color = isActive ? AppColors.primary : AppColors.slate400;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

