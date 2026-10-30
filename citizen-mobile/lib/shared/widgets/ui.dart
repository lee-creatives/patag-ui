import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app/locale.dart';
import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/models.dart';
import '../../l10n/l10n.dart';

void go(BuildContext context, String route) =>
    Navigator.of(context).pushNamed(route);
void home(BuildContext context) {
  final navigator = Navigator.of(context);
  navigator.pushNamedAndRemoveUntil('/home', (route) => false);
  // Continue a report started from the map before signing in.
  if (store.pendingReportPin != null) navigator.pushNamed('/report/new');
}

void message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
Widget logo({double width = 135}) => Builder(
    builder: (context) => Image.asset('assets/images/patag-logo.png',
        width: width,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : null,
        colorBlendMode: BlendMode.srcIn,
        semanticLabel: 'PATAG'));
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
      vsync: this, duration: const Duration(milliseconds: 2400));
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
          child: Stack(children: [
            for (final offset in [
              const Offset(-1, 0),
              const Offset(1, 0),
              const Offset(0, -1),
              const Offset(0, 1)
            ])
              Transform.translate(
                  offset: offset,
                  child: Image.asset('assets/images/patag-mascot.png',
                      width: widget.width,
                      color: const Color(0xFFFFF4E6),
                      colorBlendMode: BlendMode.srcIn,
                      excludeFromSemantics: true)),
            Image.asset('assets/images/patag-mascot.png',
                width: widget.width, excludeFromSemantics: true),
          ])),
      builder: (context, child) {
        final moving = widget.dance && !MediaQuery.disableAnimationsOf(context);
        final wave = moving ? math.sin(controller.value * math.pi * 4) : 0.0;
        return Transform.translate(
            offset: Offset(0, -wave.abs() * 6),
            child: Transform.rotate(
                angle: wave * .09,
                alignment: Alignment.bottomCenter,
                child: child));
      });
}

Widget heading(BuildContext c, String text) =>
    Text(text, style: Theme.of(c).textTheme.headlineMedium);
Widget gap([double height = 16]) => SizedBox(height: height);
Widget action(String label, VoidCallback? press,
        {IconData icon = Icons.arrow_forward, bool dark = false}) =>
    DecoratedBox(
        decoration: BoxDecoration(
            gradient: press == null
                ? null
                : dark
                    ? PatagTokens.darkGradient
                    : PatagTokens.primaryGradient,
            borderRadius: BorderRadius.circular(16)),
        child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: dark ? Colors.white : const Color(0xFF20180F)),
            onPressed: press,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(child: Text(label, textAlign: TextAlign.center)),
              const SizedBox(width: 10),
              Icon(icon, size: 18)
            ])));
Widget field(String label, TextEditingController ctrl,
        {int lines = 1,
        TextInputType? keyboard,
        bool required = true,
        int? maxLength,
        ValueChanged<String>? onChanged}) =>
    Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Builder(
            builder: (context) => TextFormField(
                controller: ctrl,
                maxLines: lines,
                maxLength: maxLength,
                keyboardType: keyboard,
                onChanged: onChanged,
                decoration: InputDecoration(labelText: label),
                validator: (s) => required && (s == null || s.trim().isEmpty)
                    ? l10n(context).fieldRequired(label)
                    : null)));

class StatusChip extends StatelessWidget {
  final String value;
  const StatusChip(this.value, {super.key});
  @override
  Widget build(BuildContext context) {
    final success = ['Resolved', 'Verified'].contains(value);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: success
                ? const Color(0xFFE8F2ED)
                : value == 'High'
                    ? const Color(0xFFFEE8DD)
                    : const Color(0xFFEDF0F5),
            borderRadius: BorderRadius.circular(999)),
        child: Text(apiValueLabel(l10n(context), value),
            style: TextStyle(
                fontSize: 12,
                color: success ? const Color(0xFF21633F) : ink,
                fontWeight: FontWeight.bold)));
  }
}

class Evidence extends StatelessWidget {
  final Map<String, dynamic> photo;
  const Evidence(this.photo, {super.key});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: photo['demo'] == true
          ? Container(
              height: 170,
              width: double.infinity,
              color: const Color(0xFFE5E8EA),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_road, size: 46, color: ink),
                    Text(l10n(context).demoEvidence,
                        style: const TextStyle(color: ink))
                  ]))
          : Image.network(store.photoUrl(photo['url']),
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => SizedBox(
                  height: 130,
                  child: Center(child: Text(l10n(context).photoUnavailable)))));
}

class ReportCard extends StatelessWidget {
  final PotholeReport report;
  final bool public;
  const ReportCard(this.report, {this.public = false, super.key});
  @override
  Widget build(BuildContext context) => Card(
      child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => go(context,
              public ? '/map/reports/${report.id}' : '/reports/${report.id}'),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                if (report.photos.isNotEmpty) ...[
                  SizedBox(
                      width: 68,
                      height: 100,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                  width: 170,
                                  height: 170,
                                  child: Evidence(Map<String, dynamic>.from(
                                      report.photos.first)))))),
                  const SizedBox(width: 14)
                ],
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        StatusChip(report.status),
                        const Spacer(),
                        const Icon(Icons.arrow_forward, size: 16)
                      ]),
                      gap(10),
                      Text(report.road,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      gap(4),
                      Text(l10n(context).brgy(report.barangay),
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      gap(10),
                      Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(report.id,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                            StatusChip(report.severity)
                          ])
                    ]))
              ]))));
}

class EmptyState extends StatelessWidget {
  final String title, text;
  const EmptyState(this.title, this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(children: [
        mascot(width: 100, dance: true),
        gap(),
        heading(context, title),
        gap(10),
        Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant))
      ]));
}

class Screen extends StatelessWidget {
  final String title;
  final Widget body;
  final int? selected;
  final List<Widget>? actions;
  const Screen(
      {required this.title,
      required this.body,
      this.selected,
      this.actions,
      super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          flexibleSpace: ClipRect(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: const SizedBox.expand())),
          title: title == 'PATAG'
              ? logo(width: 108)
              : Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
          actions: [
            ...?actions,
            const ThemeToggle(),
            const SizedBox(width: 8)
          ]),
      body: SafeArea(
          child: Column(children: [
        if (store.networkError != null)
          MaterialBanner(
              content: Text(errorText(
                  context, store.networkErrorCause ?? store.networkError!)),
              actions: [
                TextButton(
                    onPressed: () => store.refresh().catchError((Object e) {
                          if (context.mounted) {
                            message(context, errorText(context, e));
                          }
                        }),
                    child: Text(l10n(context).retry))
              ]),
        Expanded(child: body)
      ])),
      bottomNavigationBar:
          selected == null ? null : PatagNavigation(selected: selected!));
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton.filledTonal(
      tooltip: dark ? l10n(context).switchToLight : l10n(context).switchToDark,
      style: IconButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest),
      onPressed: () => themeController.toggle(Theme.of(context).brightness),
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          size: 21),
    );
  }
}

class PatagNavigation extends StatelessWidget {
  final int selected;
  const PatagNavigation({required this.selected, super.key});
  @override
  Widget build(BuildContext context) {
    final l = l10n(context);
    return SafeArea(
        top: false,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    gradient: PatagTokens.darkGradient,
                    borderRadius: BorderRadius.circular(28)),
                child: Row(
                    children: List.generate(5, (i) {
                  final active = selected == i;
                  final isCenter = i == 2;
                  final color = isCenter
                      ? orange
                      : active
                          ? Colors.white
                          : Colors.transparent;
                  final foreground = isCenter
                      ? Colors.black
                      : active
                          ? ink
                          : const Color(0xFFDCE4EE);
                  return Expanded(
                      child: Semantics(
                          selected: active,
                          button: true,
                          label: [
                            l.navHome,
                            l.navMap,
                            l.reportAPothole,
                            l.navMyReports,
                            l.navProfile
                          ][i],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 2,
                            ),
                            child: Material(
                              color: color,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    final route = [
                                      '/home',
                                      '/map',
                                      '/report/new',
                                      '/reports',
                                      '/profile'
                                    ][i];
                                    if (i == 2) {
                                      go(context, route);
                                    } else if (!active) {
                                      Navigator.of(context)
                                          .pushReplacementNamed(route);
                                    }
                                  },
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                                [
                                                  Icons.home_outlined,
                                                  Icons.map_outlined,
                                                  Icons.add,
                                                  Icons.assignment_outlined,
                                                  Icons.person_outline
                                                ][i],
                                                color: foreground,
                                                size: 20),
                                            const SizedBox(height: 2),
                                            Text(
                                                [
                                                  l.navHome,
                                                  l.navMap,
                                                  l.navReport,
                                                  l.navMyReports,
                                                  l.navProfile
                                                ][i],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: foreground,
                                                    fontSize: 10,
                                                    fontWeight: active ||
                                                            isCenter
                                                        ? FontWeight.w700
                                                        : FontWeight.normal))
                                          ]))),
                            ),
                          )));
                })))));
  }
}

class ReportProgress extends StatelessWidget {
  final PotholeReport report;
  const ReportProgress(this.report, {super.key});
  @override
  Widget build(BuildContext context) {
    final current = [
      'Submitted',
      'Under Review',
      'Verified',
      'Assigned',
      'In Progress',
      'Resolved'
    ].indexOf(report.status);
    final awaiting =
        report.json['completion']?['state'] == 'Awaiting Verification';
    final l = l10n(context);
    return Container(
        padding: const EdgeInsets.all(22),
        decoration:
            BoxDecoration(color: ink, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(l.progressTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 13))),
            StatusChip(report.status)
          ]),
          gap(16),
          Text(
              report.status == 'Resolved'
                  ? l.progressResolved
                  : awaiting
                      ? l.progressAwaiting
                      : l.progressFollow,
              style: const TextStyle(color: Color(0xFFDDE5EF), fontSize: 13)),
          gap(22),
          Row(
              children: List.generate(
                  4,
                  (i) => Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Icon(
                                  current >= [0, 2, 4, 5][i]
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: current >= [0, 2, 4, 5][i]
                                      ? orange
                                      : const Color(0xFFABB7C8)),
                              if (i < 3)
                                Expanded(
                                    child: Container(
                                        height: 2,
                                        color: current > [0, 2, 4, 5][i]
                                            ? orange
                                            : const Color(0xFF657286)))
                            ]),
                            gap(10),
                            Text(
                                [
                                  l.progressStepReported,
                                  l.progressStepVerified,
                                  l.progressStepRepair,
                                  l.progressStepResolved
                                ][i],
                                style: const TextStyle(
                                    color: Color(0xFFDDE5EF), fontSize: 11))
                          ]))))
        ]));
  }
}

class WizardSteps extends StatelessWidget {
  final int current;
  const WizardSteps(this.current, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
      child: Row(
          children: List.generate(
              4,
              (i) => Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 5,
                                decoration: BoxDecoration(
                                    color: i <= current ? orange : line,
                                    borderRadius: BorderRadius.circular(10))),
                            gap(10),
                            Text(
                                [
                                  l10n(context).stepPhoto,
                                  l10n(context).stepLocation,
                                  l10n(context).stepDetails,
                                  l10n(context).stepReview
                                ][i],
                                style: TextStyle(
                                    fontSize: 12,
                                    color: i == current
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                    fontWeight: i == current
                                        ? FontWeight.w600
                                        : FontWeight.normal))
                          ]))))));
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
          if (store.checkingServer && slow) {
            return _panel(context, Icons.hourglass_top_rounded,
                l10n(context).serverWaking);
          }
          if (store.serverProblem == null || store.checkingServer) {
            return const SizedBox.shrink();
          }
          final problem = l10n(context).serverUnreachable;
          return _panel(context, Icons.cloud_off_outlined,
              kDebugMode ? '$problem\n${PatagStore.baseUrl}' : problem,
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
            TextButton(onPressed: check, child: Text(l10n(context).retry)),
        ]),
      ),
    );
  }
}

/// Compact English / Tagalog switch for screens shown before signing in.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});
  @override
  Widget build(BuildContext context) {
    final l = l10n(context);
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) => PopupMenuButton<Locale>(
        tooltip: l.languageTitle,
        icon: const Icon(Icons.translate, size: 21),
        initialValue: localeController.locale,
        onSelected: localeController.setLocale,
        itemBuilder: (_) => [
          for (final (locale, label) in [
            (LocaleController.english, l.languageEnglish),
            (LocaleController.tagalog, l.languageTagalog),
          ])
            CheckedPopupMenuItem<Locale>(
              value: locale,
              checked: localeController.locale == locale,
              child: Text(label),
            ),
        ],
      ),
    );
  }
}
