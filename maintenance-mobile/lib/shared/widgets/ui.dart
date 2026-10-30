import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app/locale.dart';
import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/models.dart';
import '../../l10n/l10n.dart';

Widget gap([double size = 16]) => SizedBox(height: size, width: size);

Widget heading(BuildContext c, String text) =>
    Text(text, style: Theme.of(c).textTheme.headlineMedium);

Widget logo({double width = 135, bool forceWhite = false}) => Builder(
      builder: (context) => Image.asset(
        'assets/images/patag-logo.png',
        width: width,
        color: forceWhite || Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : null,
        colorBlendMode: BlendMode.srcIn,
        semanticLabel: 'PATAG',
        errorBuilder: (_, __, ___) => Text(
          'PATAG',
          style: TextStyle(
            fontFamily: 'Lilita One',
            fontSize: 24,
            letterSpacing: 1.5,
            color: forceWhite ? Colors.white : ink,
          ),
        ),
      ),
    );

Widget mascot({double width = 160, bool dance = false}) =>
    DancingMascot(width: width, dance: dance);

class DancingMascot extends StatefulWidget {
  final double width;
  final bool dance;
  const DancingMascot({super.key, required this.width, this.dance = false});
  @override
  State<DancingMascot> createState() => _DancingMascotState();
}

class _DancingMascotState extends State<DancingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  void syncMotion() {
    if (widget.dance && !MediaQuery.disableAnimationsOf(context)) {
      if (!controller.isAnimating) controller.repeat();
    } else {
      controller.stop();
      controller.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncMotion();
  }

  @override
  void didUpdateWidget(covariant DancingMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncMotion();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        child: SizedBox(
          width: widget.width,
          child: Image.asset(
            'assets/images/patag-mascot.png',
            width: widget.width,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => SizedBox(
              width: widget.width,
              height: widget.width,
              child: const Icon(
                Icons.handyman_rounded,
                color: orange,
                size: 40,
              ),
            ),
          ),
        ),
        builder: (context, child) {
          final moving =
              widget.dance && !MediaQuery.disableAnimationsOf(context);
          final wave = moving ? math.sin(controller.value * math.pi * 4) : 0.0;
          return Transform.translate(
            offset: Offset(0, -wave.abs() * 6),
            child: Transform.rotate(
              angle: wave * .08,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
      );
}

Widget action(
  String label,
  VoidCallback? press, {
  IconData icon = Icons.arrow_forward,
  bool dark = false,
}) =>
    DecoratedBox(
      decoration: BoxDecoration(
        gradient: press == null
            ? null
            : dark
                ? PatagTokens.darkGradient
                : PatagTokens.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: dark ? Colors.white : const Color(0xFF20180F),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        onPressed: press,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18),
          ],
        ),
      ),
    );

Widget field(
  String label,
  TextEditingController ctrl, {
  int lines = 1,
  TextInputType? keyboard,
  bool required = true,
  ValueChanged<String>? onChanged,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Builder(
        builder: (context) => TextFormField(
          controller: ctrl,
          maxLines: lines,
          keyboardType: keyboard,
          onChanged: onChanged,
          decoration: InputDecoration(labelText: label),
          validator: (s) => required && (s == null || s.trim().isEmpty)
              ? context.l10n.fieldRequired(label)
              : null,
        ),
      ),
    );

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'In Progress':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'Resolved':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        break;
      case 'Assigned':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        break;
      case 'Verified':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        break;
      case 'Submitted':
      case 'Under Review':
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF374151);
        break;
      default:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            statusLabel(context.l10n, status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge(this.severity, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (severity.toLowerCase()) {
      case 'high':
        bg = const Color(0xFFFEE2E2);
        fg = crewRed;
        break;
      case 'medium':
        bg = const Color(0xFFFEF3C7);
        fg = crewAmber;
        break;
      default:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        severityLabel(context.l10n, severity).toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final PotholeReport report;
  final VoidCallback? onTap;

  const TaskCard(this.report, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final l = context.l10n;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo evidence thumbnail (matches citizen-mobile report card)
              SizedBox(
                width: 72,
                height: 98,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: report.photos.isNotEmpty
                      ? PhotoWidget(
                          report.photos.first,
                          height: 98,
                          width: 72,
                        )
                      : Container(
                          color: dark ? const Color(0xFF22242A) : quiet,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_road,
                                  size: 28, color: slate),
                              const SizedBox(height: 4),
                              Text(
                                l.taskCardSite,
                                style:
                                    const TextStyle(fontSize: 10, color: slate),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Content details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(report.status),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 16, color: slate),
                      ],
                    ),
                    gap(8),
                    Text(
                      report.road.isNotEmpty
                          ? report.road
                          : l.taskCardFallbackTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    gap(3),
                    Text(
                      l.barangayShort(report.barangay),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          report.id,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SeverityBadge(report.severity),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhotoWidget extends StatelessWidget {
  final Photo photo;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const PhotoWidget(
    this.photo, {
    super.key,
    this.height = 160,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      image: true,
      label: photo.kind == 'after' ? l.photoAfter : l.photoBefore,
      child: _image(context),
    );
  }

  Widget _image(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(14);
    if (photo.url.startsWith('data:image')) {
      final base64Str = photo.url.split(',').last;
      return ClipRRect(
        borderRadius: br,
        child: Image.memory(
          base64Decode(base64Str),
          height: height,
          width: width ?? double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    // Uploaded evidence is served by the API; SVG demo illustrations keep the placeholder.
    if (photo.url.startsWith('/') && !photo.url.endsWith('.svg')) {
      return ClipRRect(
        borderRadius: br,
        child: Image.network(
          PatagMaintenanceStore.photoUrl(photo.url),
          height: height,
          width: width ?? double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, _, __) => _placeholder(context),
        ),
      );
    }
    return ClipRRect(borderRadius: br, child: _placeholder(context));
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF27292E)
          : const Color(0xFFE9ECEB),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(0, -.35),
            child: Transform.rotate(
              angle: -.08,
              child: Container(
                width: (width ?? 120) * .8,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.88),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, .38),
            child: Container(
              width: (width ?? 120) * .62,
              height: height * .28,
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: const Color(0xFF4B5563),
                  width: 7,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Tooltip(
              message: context.l10n.photoPlaceholder,
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 15,
                color: Color(0xFF5F6870),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState(this.title, this.subtitle, {super.key, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            mascot(width: 90),
            gap(20),
            heading(context, title),
            gap(8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (action != null) ...[gap(20), action!],
          ],
        ),
      ),
    );
  }
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton.filledTonal(
      tooltip: dark
          ? context.l10n.themeSwitchToLight
          : context.l10n.themeSwitchToDark,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      onPressed: () => themeController.toggle(Theme.of(context).brightness),
      icon: Icon(
        dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 21,
      ),
    );
  }
}

class Screen extends StatelessWidget {
  final String title;
  final Widget body;
  final int? selected;
  final List<Widget>? actions;
  final ValueChanged<int>? onTabSelected;
  final bool showBottomNav;

  const Screen({
    required this.title,
    required this.body,
    this.selected,
    this.actions,
    this.onTabSelected,
    this.showBottomNav = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: selected == null,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: const SizedBox.expand(),
          ),
        ),
        title: title == 'PATAG'
            ? logo(width: 108)
            : Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          ...?actions,
          const ThemeToggle(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (store.networkError != null)
              MaterialBanner(
                content: Text(errorText(context.l10n, store.networkError!)),
                actions: [
                  TextButton(
                    onPressed: () => store.refresh().catchError((Object e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorText(context.l10n, e)),
                          ),
                        );
                      }
                    }),
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: (selected != null && showBottomNav)
          ? PatagMaintenanceNavigation(
              currentIndex: selected!,
              onTap: onTabSelected ??
                  (index) {
                    switch (index) {
                      case 0:
                        Navigator.of(context)
                            .pushReplacementNamed('/dashboard');
                        break;
                      case 1:
                        Navigator.of(context)
                            .pushReplacementNamed('/assignments');
                        break;
                      case 2:
                        Navigator.of(context).pushReplacementNamed('/progress');
                        break;
                      case 3:
                        Navigator.of(context).pushReplacementNamed('/map');
                        break;
                      case 4:
                        Navigator.of(context).pushReplacementNamed('/profile');
                        break;
                    }
                  },
            )
          : null,
    );
  }
}

class PatagMaintenanceNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PatagMaintenanceNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF15171C),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: List.generate(5, (i) {
                final active = currentIndex == i;
                final isCenter = i == 2;
                final color = isCenter
                    ? null
                    : active
                        ? Colors.white
                        : Colors.transparent;
                final foreground = isCenter
                    ? Colors.black
                    : active
                        ? ink
                        : const Color(0xFFDCE4EE);

                final l = context.l10n;
                final labels = [
                  l.navHome,
                  l.navTasks,
                  l.navRepair,
                  l.navMap,
                  l.navProfile,
                ];
                final icons = [
                  Icons.home_outlined,
                  Icons.assignment_outlined,
                  Icons.handyman_rounded,
                  Icons.map_outlined,
                  Icons.person_outline,
                ];

                return Expanded(
                  child: Semantics(
                    selected: active,
                    button: true,
                    label: labels[i],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            onTap(i);
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              gradient:
                                  isCenter ? PatagTokens.primaryGradient : null,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icons[i], size: 19, color: foreground),
                                const SizedBox(height: 2),
                                Text(
                                  labels[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: active || isCenter
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: foreground,
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
              }),
            ),
          ),
        ),
      );
}

/// Shown on the sign-in screens: checks GET /health and explains clearly when
/// the PATAG server can't be reached, with a Retry button.
class ServerStatusBanner extends StatefulWidget {
  const ServerStatusBanner({super.key});
  @override
  State<ServerStatusBanner> createState() => _ServerStatusBannerState();
}

class _ServerStatusBannerState extends State<ServerStatusBanner> {
  bool slow = false;
  Timer? slowTimer;

  @override
  void initState() {
    super.initState();
    // After the first frame: checking notifies listeners, which must not happen mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) check();
    });
  }

  Future<void> check() async {
    setState(() => slow = false);
    slowTimer?.cancel();
    slowTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => slow = true);
    });
    await store.checkServer();
    slowTimer?.cancel();
  }

  @override
  void dispose() {
    slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final l = context.l10n;
          if (store.checkingServer && slow) {
            return _panel(
                context, Icons.hourglass_top_rounded, l.serverConnecting);
          }
          final problem = store.serverProblem;
          if (problem == null || store.checkingServer) {
            return const SizedBox.shrink();
          }
          final text = problem.message(l);
          return _panel(context, Icons.cloud_off_outlined,
              kDebugMode ? '$text\n${PatagMaintenanceStore.baseUrl}' : text,
              retry: true);
        },
      );

  Widget _panel(BuildContext context, IconData icon, String text,
      {bool retry = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: retry ? 1 : .45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Icon(icon, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                      height: 1.35))),
          if (retry)
            TextButton(onPressed: check, child: Text(context.l10n.retry)),
        ]),
      ),
    );
  }
}

/// Tagalog / English choice. Changes the app language immediately and
/// remembers it. [compact] is the small pill used on the sign-in screen.
class LanguageSwitcher extends StatelessWidget {
  final bool compact;
  const LanguageSwitcher({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: localeController,
        builder: (context, _) =>
            compact ? _compact(context) : _segmented(context),
      );

  Widget _segmented(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: LocaleController.tagalog.languageCode,
            label: Text(l.languageTagalog),
          ),
          ButtonSegment(
            value: LocaleController.english.languageCode,
            label: Text(l.languageEnglish),
          ),
        ],
        selected: {localeController.locale.languageCode},
        onSelectionChanged: (value) =>
            localeController.setLocale(Locale(value.first)),
      ),
    );
  }

  Widget _compact(BuildContext context) {
    final l = context.l10n;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget option(Locale locale, String label) {
      final selected =
          localeController.locale.languageCode == locale.languageCode;
      return Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => localeController.setLocale(locale),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? orange : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : dark
                        ? Colors.white70
                        : const Color(0xFF334155),
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: l.languageSettingTitle,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E222B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 6, right: 2),
              child: Icon(Icons.translate_rounded, size: 14, color: slate),
            ),
            option(LocaleController.tagalog, l.languageTagalog),
            option(LocaleController.english, l.languageEnglish),
          ],
        ),
      ),
    );
  }
}
