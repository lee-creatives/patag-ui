import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app/theme.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../l10n/l10n.dart';
import '../shared/widgets/ui.dart';
import 'task_map.dart';

class MaintenanceSplash extends StatefulWidget {
  const MaintenanceSplash({super.key});

  @override
  State<MaintenanceSplash> createState() => _MaintenanceSplashState();
}

class _MaintenanceSplashState extends State<MaintenanceSplash> {
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 400), () async {
      if (!mounted || _disposed) return;
      if (store.token != null) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ink,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorFiltered(
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                child: mascot(width: 160),
              ),
              gap(24),
              ColorFiltered(
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                child: logo(width: 190),
              ),
              gap(14),
              Text(
                context.l10n.splashTagline,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              gap(6),
              Text(
                context.l10n.brandEveryPothole,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MaintenanceWelcome extends StatelessWidget {
  const MaintenanceWelcome({super.key});

  Future<void> _demoLogin(BuildContext context) async {
    try {
      await store.demoLogin();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorText(context.l10n, e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          children: [
            logo(),
            gap(36),
            mascot(width: 200),
            gap(24),
            Text(
              l.brandFastRepair,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                letterSpacing: -0.8,
              ),
            ),
            gap(10),
            Text(
              l.welcomeBody,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            gap(32),
            action(l.welcomeSignIn, () {
              Navigator.of(context).pushNamed('/login');
            }),
            gap(12),
            OutlinedButton(
              onPressed: () => _demoLogin(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: orange, size: 20),
                  const SizedBox(width: 6),
                  Flexible(child: Text(l.welcomeContinueAs('Road Crew Alpha'))),
                ],
              ),
            ),
            gap(28),
            Text(
              l.welcomeFooter,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaintenanceLogin extends StatefulWidget {
  const MaintenanceLogin({super.key});

  @override
  State<MaintenanceLogin> createState() => _MaintenanceLoginState();
}

class _MaintenanceLoginState extends State<MaintenanceLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _showDemoDetails = false;

  /// Kept as the error itself so its text follows the chosen language.
  Object? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await store.authenticate(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _demoLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await store.demoLogin();
      if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final l = context.l10n;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0B0D11) : const Color(0xFFF1F3F7),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Top Inset Orange Card (replicated from Citizen Mobile App)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF8233),
                        Color(0xFFF65C19),
                        Color(0xFFDB4306),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF65C19).withOpacity(0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      logo(width: 104, forceWhite: true),
                      const SizedBox(height: 18),
                      Text(
                        l.loginHeroTitle,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.6,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.loginHeroSubtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.88),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Panel
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge & Theme Switcher
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: dark
                                    ? const Color(0x26FF5D1A)
                                    : const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: dark
                                      ? const Color(0x4DFF5D1A)
                                      : const Color(0xFFFFEDD5),
                                ),
                              ),
                              child: Text(
                                l.loginBadge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: dark
                                      ? const Color(0xFFFFAA91)
                                      : const Color(0xFFC2410C),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const LanguageSwitcher(compact: true),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () =>
                                themeController.toggle(theme.brightness),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dark
                                    ? const Color(0xFF1E222B)
                                    : const Color(0xFFF1F5F9),
                              ),
                              child: Icon(
                                dark
                                    ? Icons.nightlight_round
                                    : Icons.light_mode_outlined,
                                size: 18,
                                color: dark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.loginWelcome,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: dark ? Colors.white : ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.loginIntro,
                        style: TextStyle(
                          fontSize: 13,
                          color: dark ? const Color(0xFF94A3B8) : slate,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l.loginHeading,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white : ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l.loginEmail,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark ? const Color(0xFFF1F5F9) : ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        style: TextStyle(
                          fontSize: 14,
                          color: dark ? Colors.white : ink,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: dark
                              ? const Color(0xFF1B1F28)
                              : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: dark
                                  ? const Color(0xFF2D3341)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: dark
                                  ? const Color(0xFF2D3341)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: orange,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l.loginPassword,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark ? const Color(0xFFF1F5F9) : ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        style: TextStyle(
                          fontSize: 14,
                          color: dark ? Colors.white : ink,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: dark
                              ? const Color(0xFF1B1F28)
                              : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: dark
                                  ? const Color(0xFF2D3341)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: dark
                                  ? const Color(0xFF2D3341)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: orange,
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? l.loginShowPassword
                                : l.loginHidePassword,
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: dark ? const Color(0xFF94A3B8) : slate,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const ServerStatusBanner(),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF3B1912)
                                : const Color(0xFFFFF0EB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: dark
                                  ? const Color(0xFF61261A)
                                  : const Color(0xFFEBC3B5),
                            ),
                          ),
                          child: Text(
                            errorText(l, _error!),
                            style: TextStyle(
                              color: dark
                                  ? const Color(0xFFFFAA91)
                                  : const Color(0xFF8C3212),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                dark ? Colors.white : const Color(0xFF0F172A),
                            foregroundColor:
                                dark ? const Color(0xFF0F172A) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _loading ? null : _submit,
                          child: Text(
                            _loading ? l.loginSigningIn : l.loginHeading,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text(
                            l.loginAccountAssigned,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: dark ? const Color(0xFF94A3B8) : slate,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l.loginForgotPasswordHelp),
                                ),
                              );
                            },
                            child: Text(
                              l.loginForgotPassword,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: dark ? const Color(0xFFFFAA91) : orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Explore fictional demo data container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF1B1F28)
                              : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: dark
                                ? const Color(0xFF2D3341)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => setState(
                                () => _showDemoDetails = !_showDemoDetails,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l.loginDemoTitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: dark ? Colors.white : ink,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _showDemoDetails
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color:
                                        dark ? const Color(0xFF94A3B8) : slate,
                                  ),
                                ],
                              ),
                            ),
                            if (_showDemoDetails) ...[
                              const SizedBox(height: 8),
                              Text(
                                l.loginDemoBody,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dark ? const Color(0xFF94A3B8) : slate,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: dark
                                        ? const Color(0xFF222733)
                                        : Colors.white,
                                    side: BorderSide(
                                      color: dark
                                          ? const Color(0xFF384050)
                                          : const Color(0xFFCBD5E1),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _loading ? null : _demoLogin,
                                  child: Text(
                                    _loading
                                        ? l.loginDemoOpening
                                        : l.loginDemoButton,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: dark ? Colors.white : ink,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _currentIndex = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardTab(onNavigateToTab: (i) => setState(() => _currentIndex = i)),
      AssignmentsTab(onNavigateToTab: (i) => setState(() => _currentIndex = i)),
      InProgressTab(onNavigateToTab: (i) => setState(() => _currentIndex = i)),
      TaskMapScreen(onNavigateToTab: (i) => setState(() => _currentIndex = i)),
      ProfileTab(onNavigateToTab: (i) => setState(() => _currentIndex = i)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: PatagMaintenanceNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;
  const DashboardTab({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final crewUser = store.user;
    final crewTeam = store.team;
    final inProgress = store.activeWork;
    final completed = store.completedHistory;
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            logo(width: 96),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  crewTeam?.name ?? 'Road Crew Alpha',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: orange,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.notificationsTooltip,
            icon: Icon(
              store.showUnread && store.notifications.any((n) => n.read != true)
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_outlined,
            ),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
          const ThemeToggle(),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => store.refresh().catchError((Object _) {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            // Greeting Header with Team name
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.dashboardGreeting(
                          crewUser?.name.split(' ').first ??
                              l.greetingFallbackName,
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),
                      gap(2),
                      Text(
                        crewTeam?.name ?? 'Road Crew Alpha',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: l.profileTooltip,
                  onPressed: () => Navigator.of(context).pushNamed('/profile'),
                  icon: Text(
                    crewUser?.name.isNotEmpty == true
                        ? crewUser!.name[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            gap(16),
            // Hero Banner with metrics inside
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: PatagTokens.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: orange.withOpacity(0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.brandWorkOrdersReady,
                              style: const TextStyle(
                                color: Color(0xFF20180F),
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            gap(4),
                            Text(
                              l.dashboardReadyCount(
                                store.newAssignments.length +
                                    store.activeWork.length,
                              ),
                              style: const TextStyle(
                                color: Color(0xFF38271D),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      mascot(width: 78, dance: true),
                    ],
                  ),
                  gap(16),
                  action(
                    l.dashboardReviewNext,
                    [...store.newAssignments, ...store.activeWork].isEmpty
                        ? null
                        : () => Navigator.of(context).pushNamed(
                              '/assignments/${[
                                ...store.activeWork,
                                ...store.newAssignments
                              ].first.id}',
                            ),
                    icon: Icons.arrow_forward_rounded,
                    dark: true,
                  ),
                ],
              ),
            ),
            gap(14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF15171C),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  _metricBox(context, statusLabel(l, 'Assigned'),
                      '${store.newAssignments.length}', crewAmber),
                  _metricBox(context, statusLabel(l, 'In Progress'),
                      '${inProgress.length}', orange),
                  _metricBox(context, statusLabel(l, 'Resolved'),
                      '${completed.length}', crewGreen,
                      last: true),
                ],
              ),
            ),
            gap(22),
            // Active Work Orders Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: heading(context, l.dashboardActiveWorkOrders),
                ),
                TextButton(
                  onPressed: () {
                    if (onNavigateToTab != null) {
                      onNavigateToTab!(1);
                    } else {
                      Navigator.of(context)
                          .pushReplacementNamed('/assignments');
                    }
                  },
                  child: Text(l.viewAll),
                ),
              ],
            ),
            gap(12),
            if (inProgress.isEmpty && store.newAssignments.isEmpty)
              EmptyState(l.dashboardEmptyTitle, l.dashboardEmptyBody)
            else ...[
              ...inProgress.map(
                (r) => TaskCard(
                  r,
                  onTap: () =>
                      Navigator.of(context).pushNamed('/assignments/${r.id}'),
                ),
              ),
              ...store.newAssignments.take(3).map(
                    (r) => TaskCard(
                      r,
                      onTap: () => Navigator.of(context)
                          .pushNamed('/assignments/${r.id}'),
                    ),
                  ),
            ],
            gap(18),
            // Safety Tip Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E2026) : quiet,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: orange.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.safetyTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        gap(4),
                        Text(
                          l.safetyBody,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(
    BuildContext context,
    String label,
    String value,
    Color accent, {
    bool last = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        decoration: BoxDecoration(
          border: Border(
            right: last
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF343740)),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD5DEE9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssignmentsTab extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  const AssignmentsTab({super.key, this.onNavigateToTab});

  @override
  State<AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<AssignmentsTab> {
  String _filter = 'All';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final list = store.myAssignments.where((r) {
      if (_filter == 'Assigned' && r.status != 'Assigned') return false;
      if (_filter == 'In Progress' &&
          (r.status != 'In Progress' ||
              r.completion?.state == 'Awaiting Verification')) {
        return false;
      }
      if (_filter == 'Resolved' && r.status != 'Resolved') return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return r.road.toLowerCase().contains(q) ||
            r.barangay.toLowerCase().contains(q) ||
            r.id.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final l = context.l10n;
    return Screen(
      title: l.assignmentsTitle,
      selected: 1,
      onTabSelected: widget.onNavigateToTab,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: l.assignmentsSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: ['All', 'Assigned', 'In Progress', 'Resolved'].map((f) {
                final isSelected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f == 'All' ? l.filterAll : statusLabel(l, f)),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _filter = f),
                    selectedColor: orange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => store.refresh().catchError((Object _) {}),
              child: list.isEmpty
                  ? EmptyState(l.assignmentsEmptyTitle, l.assignmentsEmptyBody)
                  : ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: list.length,
                      itemBuilder: (context, i) => TaskCard(
                        list[i],
                        onTap: () => Navigator.of(context)
                            .pushNamed('/assignments/${list[i].id}'),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class InProgressTab extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;
  const InProgressTab({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final inProgress = store.activeWork;
    final l = context.l10n;

    return Screen(
      title: l.inProgressTitle,
      selected: 2,
      onTabSelected: onNavigateToTab,
      body: RefreshIndicator(
        onRefresh: () => store.refresh().catchError((Object _) {}),
        child: inProgress.isEmpty
            ? EmptyState(
                l.inProgressEmptyTitle,
                l.inProgressEmptyBody(l.startRepair),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: inProgress.length,
                itemBuilder: (context, i) => TaskCard(
                  inProgress[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/assignments/${inProgress[i].id}'),
                ),
              ),
      ),
    );
  }
}

class TaskDetailsScreen extends StatefulWidget {
  final String reportId;
  const TaskDetailsScreen(this.reportId, {super.key});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  bool _loading = false;

  Future<void> _startRepair(PotholeReport report) async {
    setState(() => _loading = true);
    try {
      await store.event(report.id, 'start', payload: {
        'note': 'Crew started on-site road surface repair.',
      });
      if (mounted) {
        final l = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.repairStarted(statusLabel(l, 'In Progress'))),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(context.l10n.errorWithMessage(errorText(context.l10n, e))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadBeforePhoto(PotholeReport report) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _loading = true);
    try {
      final photoData = await store.upload(file, kind: 'before');
      await store.event(report.id, 'before-photos', payload: {
        'photos': [photoData],
        'note': 'Before-repair inspection photo recorded by crew.',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.beforePhotoUploaded)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(context.l10n.uploadFailed(errorText(context.l10n, e))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadAfterPhoto(PotholeReport report) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _loading = true);
    try {
      final photoData = await store.upload(file, kind: 'after');
      // Recorded as a progress update; reused when the crew submits completion.
      await store.event(report.id, 'progress', payload: {
        'phase': 'Repair',
        'photos': [photoData],
        'note': 'After-repair photo recorded by crew.',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.afterPhotoUploaded)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(context.l10n.uploadFailed(errorText(context.l10n, e))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = store.getReportById(widget.reportId);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final l = context.l10n;

    if (report == null) {
      return Screen(
        title: l.taskDetailsTitle,
        body: EmptyState(l.taskNotFoundTitle, l.taskNotFoundBody),
      );
    }

    final beforePhotos = report.photos.where((p) => p.kind != 'after').toList();
    final afterPhotos = afterRepairPhotos(report);
    final completionState = report.completion?.state;
    final awaitingVerification = completionState == 'Awaiting Verification';
    final returnNote = completionState == 'Additional Work Requested'
        ? lastHistoryNote(report, 'return')
        : null;

    return Screen(
      title: report.id,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Orange Task Progress Bar on Top
          TaskProgressBar(report.status, completionState: completionState),
          gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(report.status),
              SeverityBadge(report.severity),
            ],
          ),
          gap(14),
          Text(
            report.road.isNotEmpty ? report.road : l.taskFallbackTitle,
            style: theme.textTheme.headlineMedium,
          ),
          gap(6),
          Text(
            l.taskLocation(report.barangay, report.city, report.province),
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          gap(18),
          if (beforePhotos.isNotEmpty) ...[
            Text(
              l.beforePhotosHeading,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            gap(10),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: beforePhotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => PhotoWidget(
                  beforePhotos[i],
                  width: 230,
                  height: 170,
                ),
              ),
            ),
            gap(16),
          ],
          if (afterPhotos.isNotEmpty) ...[
            Text(
              l.afterPhotosHeading,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            gap(10),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: afterPhotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => PhotoWidget(
                  afterPhotos[i],
                  width: 230,
                  height: 170,
                ),
              ),
            ),
            gap(16),
          ],
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF22242A) : quiet,
              borderRadius: BorderRadius.circular(PatagTokens.radius),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.assignmentDetails,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                gap(8),
                if (report.assignment?.note != null &&
                    report.assignment!.note.isNotEmpty)
                  Text(
                    l.lguNote(report.assignment!.note),
                    style: const TextStyle(fontSize: 13),
                  ),
                if (report.assignment?.targetDate != null) ...[
                  gap(6),
                  Text(
                    l.targetCompletion(
                        formatDate(l, report.assignment!.targetDate!)),
                    style: const TextStyle(
                      fontSize: 13,
                      color: orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                gap(8),
                Text(
                  l.coordinatesLine(
                    report.coordinates.lat.toStringAsFixed(4),
                    report.coordinates.lng.toStringAsFixed(4),
                  ),
                  style: const TextStyle(fontSize: 12, color: slate),
                ),
              ],
            ),
          ),
          gap(20),
          // Actions and Photo Evidence specific to each workflow state
          if (report.status == 'Assigned') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1B1E26) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(PatagTokens.radius),
                border: Border.all(
                  color:
                      dark ? const Color(0xFF2E3545) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_camera_outlined,
                          size: 18, color: orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.beforeInspectionTitle,
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  gap(6),
                  Text(
                    l.beforeInspectionBody,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? const Color(0xFF94A3B8) : slate,
                      height: 1.4,
                    ),
                  ),
                  gap(14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined, size: 17),
                      label: Text(l.addBeforePhoto),
                      onPressed:
                          _loading ? null : () => _uploadBeforePhoto(report),
                    ),
                  ),
                ],
              ),
            ),
            gap(16),
            action(
              _loading ? l.updating : l.startRepair,
              _loading ? null : () => _startRepair(report),
              icon: Icons.play_arrow_rounded,
            ),
          ] else if (report.status == 'In Progress' &&
              awaitingVerification) ...[
            InfoPanel(
              icon: Icons.hourglass_top_rounded,
              text: l.awaitingVerificationInfo,
            ),
          ] else if (report.status == 'In Progress') ...[
            if (returnNote != null) ...[
              InfoPanel(
                icon: Icons.assignment_return_outlined,
                text: returnNote.isEmpty
                    ? l.moreWorkRequested
                    : l.moreWorkRequestedNote(returnNote),
              ),
              gap(16),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1B1E26) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(PatagTokens.radius),
                border: Border.all(
                  color:
                      dark ? const Color(0xFF2E3545) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_a_photo_outlined,
                          size: 18, color: orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.afterEvidenceTitle,
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  gap(6),
                  Text(
                    l.afterEvidenceBody,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? const Color(0xFF94A3B8) : slate,
                      height: 1.4,
                    ),
                  ),
                  gap(14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_a_photo_outlined, size: 17),
                      label: Text(l.addAfterPhoto),
                      onPressed:
                          _loading ? null : () => _uploadAfterPhoto(report),
                    ),
                  ),
                ],
              ),
            ),
            gap(16),
            action(
              l.documentAndSubmit,
              _loading
                  ? null
                  : () {
                      Navigator.of(context)
                          .pushNamed('/repairs/${report.id}/document');
                    },
              icon: Icons.file_upload_outlined,
            ),
          ] else if (report.status == 'Resolved') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF047857)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.resolvedInfo,
                      style: const TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TaskProgressBar extends StatelessWidget {
  final String status;
  final String? completionState;
  const TaskProgressBar(this.status, {this.completionState, super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l = context.l10n;
    final int step;
    final double progress;
    final String stepName;

    switch (status) {
      case 'Assigned':
        step = 1;
        progress = 0.33;
        stepName = l.progressAssignedToCrew;
        break;
      case 'In Progress':
        step = 2;
        progress = completionState == 'Awaiting Verification' ? 0.85 : 0.66;
        stepName = completionState == 'Awaiting Verification'
            ? l.progressAwaitingVerification
            : completionState == 'Additional Work Requested'
                ? l.progressMoreWork
                : l.progressRepairInProgress;
        break;
      case 'Resolved':
      case 'Completed':
        step = 3;
        progress = 1.0;
        stepName = l.progressCompleted;
        break;
      default:
        step = 1;
        progress = 0.20;
        stepName = statusLabel(l, status);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1B1E26) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? const Color(0x33FF5D1A) : const Color(0xFFFFEDD5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 16, color: orange),
                  const SizedBox(width: 6),
                  Text(
                    l.progressTitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: dark
                          ? const Color(0xFFFFAA91)
                          : const Color(0xFFC2410C),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l.progressSummary((progress * 100).toInt(), stepName),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  dark ? const Color(0xFF2C3240) : const Color(0xFFFFE0CA),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF5D1A)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, value)
                  in const ['Assigned', 'In Progress', 'Resolved'].indexed)
                Expanded(
                  child: Text(
                    l.progressStep(i + 1, statusLabel(l, value)),
                    textAlign: const [
                      TextAlign.start,
                      TextAlign.center,
                      TextAlign.end,
                    ][i],
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: step > i ? FontWeight.w700 : FontWeight.w500,
                      color: step > i ? (dark ? Colors.white : ink) : slate,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class RepairDocumentationScreen extends StatefulWidget {
  final String reportId;
  const RepairDocumentationScreen(this.reportId, {super.key});

  @override
  State<RepairDocumentationScreen> createState() =>
      _RepairDocumentationScreenState();
}

class _RepairDocumentationScreenState extends State<RepairDocumentationScreen> {
  final _notesController = TextEditingController();
  final List<Photo> _afterPhotos = [];
  bool _loading = false;

  /// The suggested note follows the language until the crew edits it.
  String? _suggestedNote;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final suggestion = context.l10n.defaultWorkNote;
    if (_suggestedNote == null || _notesController.text == _suggestedNote) {
      _notesController.text = suggestion;
    }
    _suggestedNote = suggestion;
  }

  @override
  void initState() {
    super.initState();
    final report = store.getReportById(widget.reportId);
    if (report != null) _afterPhotos.addAll(newAfterPhotos(report));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _takeAfterPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _loading = true);
    try {
      final photoData = await store.upload(file, kind: 'after');
      if (!mounted) return;
      setState(() {
        _afterPhotos.add(Photo.fromJson(photoData));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                context.l10n.photoUploadFailed(errorText(context.l10n, e))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitCompletion() async {
    if (_notesController.text.trim().isEmpty || _afterPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.completionRequirements)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await store.event(widget.reportId, 'complete', payload: {
        'note': _notesController.text.trim(),
        'photos': _afterPhotos.map((p) => p.toJson()).toList(),
      });
      if (mounted) {
        Navigator.of(context)
            .pushReplacementNamed('/repairs/${widget.reportId}/success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(context.l10n.submissionFailed(errorText(context.l10n, e))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Screen(
      title: l.documentRepairTitle,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l.uploadAfterEvidence,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          gap(6),
          Text(
            l.uploadAfterEvidenceBody,
            style: const TextStyle(fontSize: 13, color: slate),
          ),
          gap(16),
          if (_afterPhotos.isNotEmpty) ...[
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _afterPhotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => PhotoWidget(
                  _afterPhotos[i],
                  width: 200,
                  height: 160,
                ),
              ),
            ),
            gap(16),
          ],
          OutlinedButton.icon(
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(l.takeAfterPhoto),
            onPressed: _loading ? null : _takeAfterPhoto,
          ),
          gap(24),
          Text(
            l.workNotesHeading,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          gap(10),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(hintText: l.workNotesHint),
          ),
          gap(28),
          action(
            _loading ? l.submitting : l.submitForVerification,
            _loading ? null : _submitCompletion,
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
}

class SubmissionSuccessScreen extends StatelessWidget {
  final String reportId;
  const SubmissionSuccessScreen(this.reportId, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                mascot(width: 130, dance: true),
                gap(20),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatusBadge('Awaiting Verification'),
                ),
                gap(16),
                Text(
                  l.successTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                gap(10),
                Text(
                  l.successBody(reportId),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: slate),
                ),
                gap(28),
                action(
                  l.returnToOverview,
                  () {
                    Navigator.of(context).pushReplacementNamed('/dashboard');
                  },
                  icon: Icons.home_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _markRead(BuildContext context, String id) async {
    try {
      await store.markRead(id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorText(context.l10n, e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _build(context, store.notifications),
    );
  }

  Widget _build(BuildContext context, List<Notice> list) {
    final l = context.l10n;
    return Screen(
      title: l.notificationsTitle,
      actions: [
        if (list.any((n) => !n.read))
          TextButton(
            onPressed: () => _markRead(context, 'all'),
            child: Text(l.markAllRead),
          ),
      ],
      body: list.isEmpty
          ? EmptyState(l.notificationsEmptyTitle, l.notificationsEmptyBody)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = list[i];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: item.read ? quiet : peach.withOpacity(0.3),
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: orange,
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    item.at.isEmpty
                        ? item.reportId
                        : l.notificationSubtitle(
                            item.reportId,
                            formatDate(l, item.at, withTime: true),
                          ),
                  ),
                  onTap: () async {
                    await _markRead(context, item.id);
                    if (context.mounted &&
                        store.getReportById(item.reportId) != null) {
                      Navigator.of(context)
                          .pushNamed('/assignments/${item.reportId}');
                    }
                  },
                );
              },
            ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;
  const ProfileTab({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final user = store.user;
    final team = store.team;
    final l = context.l10n;

    return Screen(
      title: l.profileTitle,
      selected: 4,
      onTabSelected: onNavigateToTab,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: ink,
                  child: Text(
                    user?.name
                            .split(' ')
                            .map((s) => s.isNotEmpty ? s[0] : '')
                            .take(2)
                            .join('') ??
                        'RC',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                gap(12),
                Text(
                  user?.name ?? l.profileFallbackName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                gap(4),
                Text(
                  team?.name ?? 'Road Maintenance Alpha',
                  style: const TextStyle(color: slate, fontSize: 14),
                ),
              ],
            ),
          ),
          gap(28),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: dark ? const Color(0xFF22242A) : quiet,
            leading:
                Icon(dark ? Icons.light_mode : Icons.dark_mode, color: orange),
            title: Text(l.themeMode),
            trailing: Text(
              dark ? l.themeDark : l.themeLight,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () => themeController.toggle(theme.brightness),
          ),
          gap(12),
          SwitchListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: dark ? const Color(0xFF22242A) : quiet,
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: orange,
            ),
            title: Text(l.unreadIndicators),
            value: store.showUnread,
            onChanged: (val) {
              store.setUnreadPreference(val);
            },
          ),
          gap(12),
          Container(
            key: const ValueKey('language-setting'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF22242A) : quiet,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.translate_rounded, color: orange),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.languageSettingTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            l.languageSettingSubtitle,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                gap(12),
                const LanguageSwitcher(),
              ],
            ),
          ),
          gap(12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: dark ? const Color(0xFF22242A) : quiet,
            leading: const Icon(Icons.info_outline_rounded, color: orange),
            title: Text(l.aboutTitle),
            subtitle: Text(l.aboutSubtitle),
          ),
          gap(28),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l.signOut),
            onPressed: () async {
              await store.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

/// After-photos recorded since the last submission, as real uploads only. Used
/// to pre-fill the completion form, so returned work needs fresh evidence and
/// demo illustrations are never resubmitted.
List<Photo> newAfterPhotos(PotholeReport report) {
  final since = report.completion?.at ?? '';
  final seen = <String>{};
  return report.updates
      .where((u) => since.isEmpty || u.at.compareTo(since) > 0)
      .expand((u) => u.photos)
      .where((p) =>
          p.kind == 'after' &&
          !p.demo &&
          p.url.startsWith('/uploads/') &&
          seen.add(p.url))
      .toList();
}

/// After-repair photos: completion evidence plus photos recorded in progress updates.
List<Photo> afterRepairPhotos(PotholeReport report) {
  final seen = <String>{};
  return [
    ...?report.completion?.photos,
    ...report.updates.expand((u) => u.photos).where((p) => p.kind == 'after'),
  ].where((p) => seen.add(p.url)).toList();
}

/// Note of the most recent history entry with this action, if any.
String? lastHistoryNote(PotholeReport report, String action) {
  for (final h in report.history.reversed) {
    if (h is Map && h['action'] == action) return (h['note'] as String?) ?? '';
  }
  return null;
}

class InfoPanel extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoPanel({required this.icon, required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1B1E26) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? const Color(0x33FF5D1A) : const Color(0xFFFFEDD5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
