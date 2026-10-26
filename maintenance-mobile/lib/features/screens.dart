import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app/theme.dart';
import '../core/api.dart';
import '../core/models.dart';
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
              const Text(
                'Road Maintenance Operations',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              gap(6),
              const Text(
                'Bawat lubak, may agarang aksyon.',
                style: TextStyle(
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
          SnackBar(content: Text(PatagMaintenanceStore.clean(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              'Mabilis na kumpuni, ligtas na biyahe.',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                letterSpacing: -0.8,
              ),
            ),
            gap(10),
            Text(
              'Access assigned work orders, document road repairs on site, and upload evidence directly to the LGU portal.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            gap(32),
            action('Sign in to Workspace', () {
              Navigator.of(context).pushNamed('/login');
            }),
            gap(12),
            OutlinedButton(
              onPressed: () => _demoLogin(context),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: orange, size: 20),
                  SizedBox(width: 6),
                  Text('Continue as Road Crew Alpha'),
                ],
              ),
            ),
            gap(28),
            Text(
              'Academic demonstration · IT 305\nCity of Malolos Road Maintenance Operations.',
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
  final _emailController = TextEditingController(text: 'crew@malolos.gov.ph');
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

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
      setState(() => _error = PatagMaintenanceStore.clean(e));
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
      setState(() => _error = PatagMaintenanceStore.clean(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Screen(
      title: 'Sign in',
      body: Form(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            logo(),
            gap(28),
            heading(context, 'Crew Workspace Sign In'),
            gap(6),
            Text(
              'City of Malolos Road Maintenance Operations · Local Demo API',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            gap(24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Staff Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            gap(16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_error != null) ...[
              gap(14),
              Text(
                _error!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            gap(22),
            action(
              _loading ? 'Connecting…' : 'Sign in to Workspace',
              _loading ? null : _submit,
            ),
            gap(22),
            Text(
              'Explore the demo without typing a password.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            gap(10),
            OutlinedButton(
              onPressed: _loading ? null : _demoLogin,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: orange, size: 20),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Continue as Road Crew Alpha',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            gap(28),
            Text(
              'Academic demonstration · IT 305\nCity of Malolos Road Maintenance Operations.',
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
  Widget build(BuildContext context) {
    final screens = [
      DashboardTab(onNavigateToTab: (i) => setState(() => _currentIndex = i)),
      const AssignmentsTab(),
      const InProgressTab(),
      const TaskMapScreen(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            logo(width: 96),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                crewTeam?.name ?? 'Road Crew Alpha',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: orange,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: Icon(
              store.showUnread &&
                      store.notifications.any((n) => n.read != true)
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
        onRefresh: () => store.refresh(),
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
                        'Hello, ${crewUser?.name.split(' ').first ?? 'Crew'}.',
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
                  tooltip: 'Your profile',
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
                            const Text(
                              'Handa na ang mga work order.',
                              style: TextStyle(
                                color: Color(0xFF20180F),
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            gap(4),
                            Text(
                              '${store.myAssignments.length} assigned work orders ready for action.',
                              style: const TextStyle(
                                color: Color(0xFF38271D),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      mascot(width: 70),
                    ],
                  ),
                  gap(12),
                  Row(
                    children: [
                      _metricBox(
                        context,
                        'Assigned',
                        '${store.newAssignments.length}',
                        crewAmber,
                      ),
                      const SizedBox(width: 8),
                      _metricBox(
                        context,
                        'In Progress',
                        '${inProgress.length}',
                        orange,
                      ),
                      const SizedBox(width: 8),
                      _metricBox(
                        context,
                        'Resolved',
                        '${completed.length}',
                        crewGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            gap(18),
            // Active Work Orders Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                heading(context, 'Active Work Orders'),
                TextButton(
                  onPressed: () {
                    if (onNavigateToTab != null) {
                      onNavigateToTab!(1);
                    } else {
                      Navigator.of(context)
                          .pushReplacementNamed('/assignments');
                    }
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
            gap(12),
            if (inProgress.isEmpty && store.newAssignments.isEmpty)
              const EmptyState(
                'All clear for now',
                'No pending road repairs assigned to your team.',
              )
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
                  onTap: () =>
                      Navigator.of(context).pushNamed('/assignments/${r.id}'),
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
                        const Text(
                          'Safety Protocol On Site',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        gap(4),
                        Text(
                          'Deploy safety cones 15m ahead, wear high-vis vests, and log before & after photos.',
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
    Color accent,
  ) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E2026) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
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
      if (_filter == 'In Progress' && r.status != 'In Progress') return false;
      if (_filter == 'Resolved' && r.status != 'Resolved') return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return r.road.toLowerCase().contains(q) ||
            r.barangay.toLowerCase().contains(q) ||
            r.id.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Screen(
      title: 'My Assignments',
      selected: 1,
      onTabSelected: widget.onNavigateToTab,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search road, barangay, or ID…',
                prefixIcon: Icon(Icons.search_rounded),
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
                    label: Text(f),
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
              onRefresh: () => store.refresh(),
              child: list.isEmpty
                  ? const EmptyState(
                      'No matching work orders',
                      'Try another filter or check for newly assigned tasks.',
                    )
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

    return Screen(
      title: 'Repairs In Progress',
      selected: 2,
      onTabSelected: onNavigateToTab,
      body: RefreshIndicator(
        onRefresh: () => store.refresh(),
        child: inProgress.isEmpty
            ? const EmptyState(
                'No repairs in progress',
                'Select an assigned task from Work Orders and tap "Start inspection / repair" to begin work.',
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
      await store.event(report.id, 'start_repair', payload: {
        'note': 'Crew Alpha initiated on-site road surface repair.',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repair started! Task is now In Progress.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${PatagMaintenanceStore.clean(e)}'),
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
      await store.event(report.id, 'upload_evidence', payload: {
        'photo': photoData,
        'note': 'Before-repair inspection photo recorded by crew.',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Before-repair photo uploaded.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${PatagMaintenanceStore.clean(e)}'),
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

    if (report == null) {
      return const Screen(
        title: 'Task Details',
        body: EmptyState('Task not found', 'This task could not be loaded.'),
      );
    }

    return Screen(
      title: report.id,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(report.status),
              SeverityBadge(report.severity),
            ],
          ),
          gap(14),
          Text(
            report.road.isNotEmpty ? report.road : 'Road Work Order',
            style: theme.textTheme.headlineMedium,
          ),
          gap(6),
          Text(
            'Brgy. ${report.barangay}, ${report.city}, ${report.province}',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          gap(18),
          if (report.photos.isNotEmpty) ...[
            const Text(
              'Citizen Evidence Photos',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            gap(10),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: report.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => PhotoWidget(
                  report.photos[i],
                  width: 240,
                  height: 180,
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
                const Text(
                  'Assignment Details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                gap(8),
                if (report.assignment?.note != null &&
                    report.assignment!.note.isNotEmpty)
                  Text(
                    'LGU Note: ${report.assignment!.note}',
                    style: const TextStyle(fontSize: 13),
                  ),
                if (report.assignment?.targetDate != null) ...[
                  gap(6),
                  Text(
                    'Target Completion: ${report.assignment!.targetDate}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                gap(8),
                Text(
                  'Coordinates: ${report.coordinates.lat.toStringAsFixed(4)}, ${report.coordinates.lng.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12, color: slate),
                ),
              ],
            ),
          ),
          gap(20),
          if (report.status == 'Assigned') ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Add Before-Repair Photo'),
              onPressed: _loading ? null : () => _uploadBeforePhoto(report),
            ),
            gap(12),
            action(
              _loading ? 'Updating…' : 'Start Inspection / Repair',
              _loading ? null : () => _startRepair(report),
              icon: Icons.play_arrow_rounded,
            ),
          ] else if (report.status == 'In Progress') ...[
            action(
              'Document & Submit Completion',
              () {
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
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF047857)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Repair verified and resolved by LGU.',
                      style: TextStyle(
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

class RepairDocumentationScreen extends StatefulWidget {
  final String reportId;
  const RepairDocumentationScreen(this.reportId, {super.key});

  @override
  State<RepairDocumentationScreen> createState() =>
      _RepairDocumentationScreenState();
}

class _RepairDocumentationScreenState
    extends State<RepairDocumentationScreen> {
  final _notesController = TextEditingController(
    text:
        'Base compacted, crack seal applied, and hot asphalt patched to grade.',
  );
  final List<Photo> _afterPhotos = [];
  bool _loading = false;

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
      setState(() {
        _afterPhotos.add(Photo.fromJson(photoData));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Photo upload failed: ${PatagMaintenanceStore.clean(e)}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitCompletion() async {
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
                Text('Submission failed: ${PatagMaintenanceStore.clean(e)}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screen(
      title: 'Document Repair',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Upload After-Repair Evidence',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          gap(6),
          const Text(
            'Provide clear photos of the patched and compacted road surface.',
            style: TextStyle(fontSize: 13, color: slate),
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
            label: const Text('Take / Select After Photo'),
            onPressed: _loading ? null : _takeAfterPhoto,
          ),
          gap(24),
          const Text(
            'Work Performed / Progress Notes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          gap(10),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Describe materials used, compaction, curing time…',
            ),
          ),
          gap(28),
          action(
            _loading ? 'Submitting…' : 'Submit for Verification',
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                mascot(width: 130),
                gap(20),
                const StatusBadge('Awaiting Verification'),
                gap(16),
                const Text(
                  'Work submitted.\nOne step closer to patag.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                gap(10),
                Text(
                  '$reportId · The LGU engineering office will review your evidence before closing the task.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: slate),
                ),
                gap(28),
                action(
                  'Return to Overview',
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

  @override
  Widget build(BuildContext context) {
    final list = store.notifications;
    return Screen(
      title: 'Notifications',
      body: list.isEmpty
          ? const EmptyState(
              'All caught up',
              'No new notifications for your crew.',
            )
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
                  subtitle: Text(item.reportId),
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

    return Screen(
      title: 'Profile & Settings',
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
                  user?.name ?? 'Maintenance Personnel',
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
            title: const Text('Theme Mode'),
            trailing: Text(
              dark ? 'Dark' : 'Light',
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
            title: const Text('Unread Indicators'),
            value: store.showUnread,
            onChanged: (val) {
              store.setUnreadPreference(val);
            },
          ),
          gap(12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: dark ? const Color(0xFF22242A) : quiet,
            leading: const Icon(Icons.info_outline_rounded, color: orange),
            title: const Text('About PATAG Maintenance'),
            subtitle: const Text('IT 305 · Bulacan State University'),
          ),
          gap(28),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out of Workspace'),
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
