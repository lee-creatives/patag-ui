import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

import '../app/theme.dart';
import '../core/api.dart';
import '../app/locale.dart';
import '../core/models.dart';
import '../l10n/l10n.dart';
import '../shared/widgets/ui.dart';
import 'report_map.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final p = await SharedPreferences.getInstance();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          p.getBool('onboarded') == true ? '/welcome' : '/onboarding',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ink,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  child: mascot(width: 180, dance: true),
                ),
                gap(24),
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  child: logo(width: 190),
                ),
                gap(),
                Text(
                  context.l.brandTagline,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int index = 0;
  Future<void> done() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarded', true);
    if (mounted) Navigator.of(context).pushReplacementNamed('/welcome');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    logo(),
                    TextButton(onPressed: done, child: Text(context.l.skip)),
                  ],
                ),
                Expanded(
                  child: ListView(
                    children: [
                      gap(30),
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: index == 1 ? 48 : 28,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: [peach, paper, quiet][index],
                          borderRadius:
                              BorderRadius.circular(index == 1 ? 80 : 28),
                        ),
                        child: Column(
                          children: [
                            if (index == 1) ...[
                              const Icon(
                                Icons.location_on_outlined,
                                size: 42,
                                color: ink,
                              ),
                              gap(12),
                            ],
                            Center(
                                child: mascot(
                                    width: index == 2 ? 160 : 210,
                                    dance: true)),
                            if (index == 2) ...[
                              gap(20),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(Icons.check_circle_outline),
                                  Icon(Icons.local_shipping_outlined),
                                  Icon(Icons.verified_outlined),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      gap(28),
                      heading(
                        context,
                        [
                          context.l.brandOnboardingTitle,
                          context.l.onboardingTitlePin,
                          context.l.onboardingTitleFollow,
                        ][index],
                      ),
                      gap(),
                      Text(
                        [
                          context.l.onboardingBodyPhoto,
                          context.l.onboardingBodyPin,
                          context.l.onboardingBodyFollow,
                        ][index],
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 16),
                      ),
                      gap(30),
                      Row(
                        children: List.generate(
                          3,
                          (i) => Container(
                            width: i == index ? 28 : 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color:
                                  i == index ? orange : const Color(0xFFD4D8DC),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (index > 0)
                      TextButton(
                        onPressed: () => setState(() => index--),
                        child: Text(context.l.back),
                      ),
                    Expanded(
                      child: action(
                          index == 2 ? context.l.getStarted : context.l.next,
                          () {
                        if (index == 2) {
                          done();
                        } else {
                          setState(() => index++);
                        }
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class Welcome extends StatelessWidget {
  const Welcome({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              logo(),
              gap(40),
              mascot(width: 220),
              gap(24),
              Text(
                context.l.brandWelcomeHeadline,
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(color: const Color(0xFF20180F), fontSize: 30),
              ),
              gap(),
              Text(
                context.l.welcomeBody,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16),
              ),
              gap(32),
              action(context.l.signIn, () => go(context, '/login')),
              gap(12),
              OutlinedButton(
                onPressed: () => go(context, '/register'),
                child: Text(context.l.createAnAccount),
              ),
              TextButton(
                onPressed: () => go(context, '/map'),
                child: Text(context.l.explorePublicMap),
              ),
              gap(),
              Text(
                context.l.academicNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
}

class AuthScreen extends StatefulWidget {
  final String kind;
  const AuthScreen(this.kind, {super.key});
  @override
  State<AuthScreen> createState() => _AuthState();
}

class _AuthState extends State<AuthScreen> {
  final key = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      addressLine = TextEditingController(),
      barangay = TextEditingController(),
      city = TextEditingController(),
      province = TextEditingController();
  bool hidden = true, busy = false, privacy = false;
  int signupStep = 0;
  String error = '', success = '';
  bool get register => widget.kind == 'register';
  bool get recovery => widget.kind == 'forgot-password';
  @override
  void dispose() {
    for (final c in [
      name,
      email,
      password,
      addressLine,
      barangay,
      city,
      province
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit({bool demo = false}) async {
    if (!demo && !key.currentState!.validate()) return;
    if (register && signupStep < 2) {
      setState(() {
        signupStep++;
        error = '';
      });
      return;
    }
    if (register && !privacy) {
      setState(() => error = context.l.privacyRequired);
      return;
    }
    setState(() {
      busy = true;
      error = '';
    });
    try {
      if (recovery) {
        final data = await store.call(
          '/auth/recovery',
          body: {'email': email.text.trim()},
        );
        success = data['message'];
      } else {
        await store.authenticate(
          demo
              ? '/auth/demo'
              : register
                  ? '/auth/register'
                  : '/auth/login',
          demo
              ? {'role': 'citizen'}
              : {
                  'name': name.text.trim(),
                  'email': email.text.trim(),
                  'password': password.text,
                  'role': 'citizen',
                  if (register)
                    'address': {
                      'line': addressLine.text.trim(),
                      'barangay': barangay.text.trim(),
                      'city': city.text.trim(),
                      'province': province.text.trim(),
                    },
                },
        );
        if (mounted) home(context);
      }
    } catch (e) {
      if (mounted) error = errorText(context, e);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Screen(
      title: recovery
          ? l.recoverAccount
          : register
              ? l.createAccount
              : l.signIn,
      actions: const [LanguageToggle()],
      body: Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            logo(),
            const ServerStatusBanner(),
            gap(16),
            heading(
              context,
              recovery
                  ? l.recoveryHeading
                  : register
                      ? l.registerHeading
                      : l.brandSignInHeading,
            ),
            gap(),
            Text(
              l.devAuthNote,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            gap(24),
            if (register) ...[
              Text(l.signupStep(
                  signupStep + 1,
                  3,
                  [
                    l.signupStepAbout,
                    l.signupStepAddress,
                    l.signupStepSecure
                  ][signupStep])),
              gap(),
              LinearProgressIndicator(value: (signupStep + 1) / 3),
              gap(20)
            ],
            if (register && signupStep == 0) field(l.fullName, name),
            if (!register || signupStep == 0)
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l.emailAddress),
                validator: (s) =>
                    s != null && RegExp(r'^\S+@\S+\.\S+$').hasMatch(s)
                        ? null
                        : l.invalidEmail,
              ),
            gap(),
            if (register && signupStep == 1) ...[
              Text(l.addressPrivateNote),
              gap(16),
              TextFormField(
                  controller: addressLine,
                  autofillHints: const [AutofillHints.streetAddressLine1],
                  decoration: InputDecoration(labelText: l.streetOptional)),
              gap(),
              TextFormField(
                  controller: barangay,
                  decoration: InputDecoration(labelText: l.barangay),
                  validator: (s) =>
                      s != null && s.trim().isNotEmpty && s.trim().length <= 120
                          ? null
                          : l.enterBarangay),
              gap(),
              TextFormField(
                  controller: city,
                  autofillHints: const [AutofillHints.addressCity],
                  decoration: InputDecoration(labelText: l.cityMunicipality),
                  validator: (s) =>
                      s != null && s.trim().isNotEmpty && s.trim().length <= 120
                          ? null
                          : l.enterCity),
              gap(),
              TextFormField(
                  controller: province,
                  autofillHints: const [AutofillHints.addressState],
                  decoration: InputDecoration(labelText: l.province),
                  validator: (s) =>
                      s != null && s.trim().isNotEmpty && s.trim().length <= 120
                          ? null
                          : l.enterProvince),
              gap(),
            ],
            if (!recovery && (!register || signupStep == 2)) ...[
              TextFormField(
                controller: password,
                obscureText: hidden,
                autofillHints: [
                  register ? AutofillHints.newPassword : AutofillHints.password,
                ],
                decoration: InputDecoration(
                  labelText: l.password,
                  suffixIcon: IconButton(
                    tooltip: hidden ? l.showPassword : l.hidePassword,
                    onPressed: () => setState(() => hidden = !hidden),
                    icon: Icon(
                      hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (s) => s != null &&
                        (register
                            ? s.runes.length >= 8 &&
                                s.runes.length <= 128 &&
                                RegExp(r'[a-z]').hasMatch(s) &&
                                RegExp(r'[A-Z]').hasMatch(s) &&
                                RegExp(r'[0-9]').hasMatch(s) &&
                                RegExp(r'[^A-Za-z0-9]').hasMatch(s)
                            : s.isNotEmpty)
                    ? null
                    : register
                        ? l.passwordRule
                        : l.enterPassword,
              ),
              gap(),
              if (register) Text(l.passwordRequirements),
              if (register)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: privacy,
                  onChanged: (v) => setState(() => privacy = v ?? false),
                  title: Text(l.privacyAcknowledge),
                ),
            ],
            if (error.isNotEmpty)
              Text(error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (success.isNotEmpty) Text(success),
            gap(20),
            action(
              busy
                  ? l.connecting
                  : recovery
                      ? l.requestRecovery
                      : register
                          ? (signupStep < 2 ? l.continueLabel : l.createAccount)
                          : l.signIn,
              busy ? null : () => submit(),
            ),
            if (register && signupStep > 0)
              TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                            signupStep--;
                            error = '';
                          }),
                  child: Text(l.back)),
            if (register && signupStep == 0)
              TextButton(
                  onPressed: () => go(context, '/login'),
                  child: Text(l.alreadyHaveAccount)),
            if (!register && !recovery) ...[
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                children: [
                  TextButton(
                      onPressed: () => go(context, '/register'),
                      child: Text(l.createAnAccount)),
                  TextButton(
                      onPressed: () => go(context, '/forgot-password'),
                      child: Text(l.forgotPassword)),
                ],
              ),
              gap(20),
              Text(
                l.exploreDemoNote,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => submit(demo: true),
                child: Text(l.continueAsDemo),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CitizenHome extends StatelessWidget {
  const CitizenHome({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final name =
        (store.user?['name'] ?? l.brandDefaultName).toString().split(' ').first;
    final rs = store.reports;
    return Screen(
      title: 'PATAG',
      selected: 0,
      actions: [
        IconButton(
          tooltip: l.notifications,
          onPressed: () => go(context, '/notifications'),
          icon: Icon(
            store.showUnread &&
                    store.notifications.any((n) => n['read'] != true)
                ? Icons.notifications_active_outlined
                : Icons.notifications_outlined,
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: store.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.helloName(name),
                        style: const TextStyle(
                          fontSize: 26,
                          letterSpacing: -.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      gap(4),
                      Text(
                        l.homeSubtitle,
                        style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: l.yourProfile,
                  onPressed: () => go(context, '/profile'),
                  icon: Text(name.isEmpty ? 'P' : name[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            gap(22),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: PatagTokens.primaryGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l.brandHomeQuestion,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                  color: const Color(0xFF20180F),
                                  fontSize: 32))),
                  gap(12),
                  Row(children: [
                    Expanded(
                        flex: 3,
                        child: Text(l.homeCallToAction,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF38271D),
                                height: 1.5))),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: mascot(width: 100, dance: true)),
                  ]),
                  gap(22),
                  action(
                    l.reportAPothole,
                    () => go(context, '/report/new'),
                    icon: Icons.add_a_photo_outlined,
                    dark: true,
                  ),
                ],
              ),
            ),
            gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l.aroundYou,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => go(context, '/map'),
                  child: Text(l.explore),
                ),
              ],
            ),
            gap(12),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: RoadMap(reports: store.publicReports, height: 200),
            ),
            gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(
                  l.yourImpact,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                )),
                TextButton(
                  onPressed: () => go(context, '/reports'),
                  child: Text(l.viewReports),
                ),
              ],
            ),
            gap(10),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: PatagTokens.darkGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.totalReports,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                        gap(8),
                        Text(
                          '${rs.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            height: 1.1,
                          ),
                        ),
                        gap(8),
                        Text(
                          l.everyTagCounts,
                          style: const TextStyle(
                            color: Color(0xFFD5DEE9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _metric(
                          l.metricUnderReview,
                          rs
                              .where(
                                (r) => [
                                  'Submitted',
                                  'Under Review',
                                ].contains(r.status),
                              )
                              .length,
                        ),
                        gap(14),
                        _metric(
                          l.metricInProgress,
                          rs.where((r) => r.status == 'In Progress').length,
                        ),
                        gap(14),
                        _metric(
                          l.metricResolved,
                          rs.where((r) => r.status == 'Resolved').length,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    l.latestReport,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => go(context, '/reports'),
                  child: Text(l.viewAll),
                ),
              ],
            ),
            gap(10),
            if (rs.isEmpty) EmptyState(l.firstTagTitle, l.firstTagBody),
            ...rs.take(1).map((r) => ReportCard(r)),
            gap(22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.clearerPictureTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      gap(6),
                      Text(
                        l.clearerPictureBody,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => go(context, '/help'),
                        child: Text(l.readGuide),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            gap(12),
            Text(
              l.demoReportsNote,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, int value) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFE0E6ED), fontSize: 12),
            ),
          ),
          Text('$value',
              style: const TextStyle(color: Colors.white, fontSize: 18)),
        ],
      );
}

class MyReports extends StatefulWidget {
  const MyReports({super.key});
  @override
  State<MyReports> createState() => _MyReportsState();
}

class _MyReportsState extends State<MyReports> {
  String query = '', status = 'All';
  bool newest = true;
  @override
  Widget build(BuildContext context) {
    final rs = store.reports
        .where(
          (r) =>
              (r.road + r.id).toLowerCase().contains(query.toLowerCase()) &&
              (status == 'All' || r.status == status),
        )
        .toList()
      ..sort(
        (a, b) => newest
            ? b.json['createdAt'].compareTo(a.json['createdAt'])
            : a.json['createdAt'].compareTo(b.json['createdAt']),
      );
    final l = context.l;
    return Screen(
      title: l.navMyReports,
      selected: 3,
      body: RefreshIndicator(
        onRefresh: store.refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            heading(context, l.myReportsHeading),
            gap(20),
            TextField(
              decoration: InputDecoration(
                labelText: l.searchReports,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (s) => setState(() => query = s),
            ),
            gap(12),
            Wrap(
              spacing: 16,
              children: [
                ...['All', ...reportStatuses].map((s) => ChoiceChip(
                      label:
                          Text(s == 'All' ? l.filterAll : apiValueLabel(l, s)),
                      selected: status == s,
                      onSelected: (_) => setState(() => status = s),
                    )),
                TextButton.icon(
                  onPressed: () => setState(() => newest = !newest),
                  icon: const Icon(Icons.sort),
                  label: Text(newest ? l.newestFirst : l.oldestFirst),
                ),
              ],
            ),
            gap(16),
            if (rs.isEmpty) EmptyState(l.noReportsFound, l.noReportsFoundBody),
            ...rs.map((r) => ReportCard(r)),
          ],
        ),
      ),
    );
  }
}

class ReportDetails extends StatelessWidget {
  final String id;
  final bool public;
  const ReportDetails(this.id, {this.public = false, super.key});
  @override
  Widget build(BuildContext context) {
    final reports = public ? store.publicReports : store.reports;
    final matches = reports.where((report) => report.id == id);
    final l = context.l;
    if (matches.isEmpty) {
      return Screen(
        title: l.reportDetails,
        body: EmptyState(l.reportNotFound, l.reportNotFoundBody),
      );
    }
    final report = matches.first;
    final completion = report.json['completion'];
    return Screen(
      title: l.reportDetails,
      body: RefreshIndicator(
        onRefresh: store.refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(report.id,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            gap(8),
            heading(context, report.road),
            gap(16),
            ReportProgress(report),
            gap(16),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(report.severity),
            ),
            gap(20),
            ...report.photos.map(
              (photo) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Evidence(Map<String, dynamic>.from(photo)),
              ),
            ),
            Text(report.description),
            gap(10),
            Text(
              l.detailsAddress(
                  report.barangay,
                  '${report.json['location']['city']}',
                  '${report.json['location']['province']}'),
            ),
            gap(8),
            Text(
              '${report.coordinates.lat.toStringAsFixed(6)}, ${report.coordinates.lng.toStringAsFixed(6)}',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            gap(16),
            RoadMap(
              pin: LatLng(report.coordinates.lat, report.coordinates.lng),
              height: 220,
            ),
            gap(24),
            heading(context, l.roadToResolution),
            gap(20),
            ...report.history.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry['action'] == 'complete'
                                ? l.statusAwaitingVerification
                                : apiValueLabel(l, '${entry['to']}'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          gap(4),
                          Text(
                            entry['note'] ?? '',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                          Text(
                            formatDate(context, entry['at']),
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (completion != null) ...[
              heading(context, l.repairDocumentation),
              gap(16),
              ...(completion['photos'] as List).map(
                (photo) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Evidence(Map<String, dynamic>.from(photo)),
                ),
              ),
              Text(completion['note'] ?? ''),
              gap(20),
            ],
            if (!public && report.status == 'Resolved')
              report.json['feedback'] == null
                  ? action(
                      l.shareRepairFeedback,
                      () => go(context, '/reports/$id/feedback'),
                      icon: Icons.star_outline,
                    )
                  : Text(l.feedbackRecorded),
          ],
        ),
      ),
    );
  }
}

class ReportSuccess extends StatelessWidget {
  final String id;
  const ReportSuccess(this.id, {super.key});
  @override
  Widget build(BuildContext context) => Screen(
        title: context.l.reportSubmitted,
        body: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            gap(24),
            mascot(width: 200, dance: true),
            gap(20),
            heading(context, context.l.brandSuccessHeading),
            gap(12),
            Text(context.l.reportSubmittedBody),
            gap(20),
            Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
            gap(12),
            const Align(
              alignment: Alignment.centerLeft,
              child: StatusChip('Submitted'),
            ),
            gap(28),
            action(context.l.viewReport, () => go(context, '/reports/$id')),
            gap(12),
            OutlinedButton(
              onPressed: () => home(context),
              child: Text(context.l.returnHome),
            ),
          ],
        ),
      );
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Screen(
        title: context.l.notifications,
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await store.call('/notifications/read', body: {'id': 'all'});
                await store.refresh();
              } catch (e) {
                if (context.mounted) message(context, errorText(context, e));
              }
            },
            child: Text(context.l.readAll),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: store.refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (store.notifications.isEmpty)
                EmptyState(context.l.allQuiet, context.l.allQuietBody),
              ...store.notifications.map(
                (n) => Card(
                  color: n['read'] == true
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    leading: Icon(
                      n['read'] == true
                          ? Icons.notifications_none
                          : Icons.notifications_active_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(n['title']),
                    subtitle: Text(
                      context.l.notificationSubtitle(
                          '${n['reportId']}', formatDate(context, n['at'])),
                    ),
                    onTap: () async {
                      try {
                        await store.call(
                          '/notifications/read',
                          body: {'id': n['id']},
                        );
                        await store.refresh();
                        if (context.mounted) {
                          go(context, '/reports/${n['reportId']}');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          message(context, errorText(context, e));
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class FeedbackScreen extends StatefulWidget {
  final String id;
  const FeedbackScreen(this.id, {super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackState();
}

class _FeedbackState extends State<FeedbackScreen> {
  int rating = 0;
  bool busy = false, done = false;
  final text = TextEditingController();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rs = store.reports.where((r) => r.id == widget.id);
    final l = context.l;
    if (rs.isEmpty || rs.first.status != 'Resolved') {
      return Screen(
        title: l.repairFeedback,
        body: EmptyState(l.repairNotVerified, l.repairNotVerifiedBody),
      );
    }
    return Screen(
      title: l.repairFeedback,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          mascot(width: 120, dance: true),
          gap(20),
          heading(
            context,
            done ? l.brandFeedbackThanks : l.howWasRepair,
          ),
          gap(12),
          if (done)
            Text(l.feedbackSaved)
          else if (rs.first.json['feedback'] != null)
            Text(l.feedbackAlready)
          else ...[
            Text(widget.id),
            gap(20),
            Wrap(
              children: List.generate(
                5,
                (i) => IconButton(
                  tooltip: l.starsTooltip(i + 1),
                  onPressed: () => setState(() => rating = i + 1),
                  icon: Icon(
                    i < rating ? Icons.star : Icons.star_outline,
                    color: const Color(0xFF8C5317),
                    size: 34,
                  ),
                ),
              ),
            ),
            gap(),
            field(l.yourRepairFeedback, text, lines: 4),
            action(
              busy ? l.submitting : l.submitFeedback,
              busy
                  ? null
                  : () async {
                      if (rating == 0 || text.text.trim().isEmpty) {
                        message(context, l.feedbackIncomplete);
                        return;
                      }
                      setState(() => busy = true);
                      try {
                        await store.call(
                          '/reports/${widget.id}/feedback',
                          body: {'rating': rating, 'text': text.text.trim()},
                        );
                        unawaited(store.refresh().catchError((Object _) {}));
                        if (mounted) setState(() => done = true);
                      } catch (e) {
                        if (context.mounted) {
                          message(context, errorText(context, e));
                        }
                      }
                      if (mounted) setState(() => busy = false);
                    },
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Screen(
        title: context.l.yourProfile,
        selected: 4,
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: peach,
              child: Icon(Icons.person_outline, color: ink, size: 42),
            ),
            gap(24),
            heading(
                context, store.user?['name'] ?? context.l.defaultCitizenName),
            gap(8),
            Text(store.user?['email'] ?? '',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if (store.user?['address'] is Map &&
                (store.user?['address']['barangay'] ?? '')
                    .toString()
                    .isNotEmpty) ...[
              gap(12),
              Text(context.l.profileAddress([
                store.user?['address']['line'],
                store.user?['address']['barangay'],
                store.user?['address']['city'],
                store.user?['address']['province'],
              ]
                  .where((part) => part != null && part.toString().isNotEmpty)
                  .join(', '))),
            ],
            gap(24),
            Text(context.l.communityReportsCount(store.reports.length)),
            gap(16),
            ...<String, String>{
              context.l.editProfile: '/profile/edit',
              context.l.settings: '/settings',
              context.l.reportingGuide: '/help',
              context.l.aboutPatag: '/about',
            }.entries.map(
                  (e) => Card(
                    child: ListTile(
                      title: Text(e.key),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => go(context, e.value),
                    ),
                  ),
                ),
            gap(16),
            OutlinedButton.icon(
              onPressed: () async {
                await store.logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/welcome', (_) => false);
                }
              },
              icon: const Icon(Icons.logout),
              label: Text(context.l.signOut),
            ),
          ],
        ),
      );
}

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final key = GlobalKey<FormState>();
  late final name = TextEditingController(text: store.user?['name']),
      email = TextEditingController(text: store.user?['email']);
  late final TextEditingController addressLine, barangay, city, province;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final address = store.user?['address'];
    String value(String key) =>
        address is Map ? (address[key] ?? '').toString() : '';
    addressLine = TextEditingController(text: value('line'));
    barangay = TextEditingController(text: value('barangay'));
    city = TextEditingController(text: value('city'));
    province = TextEditingController(text: value('province'));
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    for (final controller in [addressLine, barangay, city, province]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Screen(
      title: l.editProfile,
      body: Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            field(l.fullName, name),
            TextFormField(
                controller: email,
                readOnly: true,
                decoration: InputDecoration(
                    labelText: l.emailAddress, helperText: l.emailChangeNote)),
            gap(),
            if (store.user?['address'] is Map) ...[
              Text(l.privateAddressNote),
              gap(),
              TextFormField(
                  controller: addressLine,
                  decoration: InputDecoration(labelText: l.streetOptional)),
              gap(),
              TextFormField(
                  controller: barangay,
                  decoration: InputDecoration(labelText: l.barangay),
                  validator: (s) =>
                      s != null && s.trim().isNotEmpty && s.trim().length <= 120
                          ? null
                          : l.enterBarangay),
              gap(),
              TextFormField(
                  controller: city,
                  decoration: InputDecoration(labelText: l.cityMunicipality),
                  validator: (s) =>
                      s != null && s.trim().isNotEmpty && s.trim().length <= 120
                          ? null
                          : l.enterCity),
              gap(),
              TextFormField(
                  controller: province,
                  decoration: InputDecoration(labelText: l.province),
                  validator: (s) =>
                      s != null && s.trim().isNotEmpty && s.trim().length <= 120
                          ? null
                          : l.enterProvince),
              gap(),
            ],
            action(
              l.saveProfile,
              busy
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) return;
                      setState(() => busy = true);
                      try {
                        await store.call(
                          '/me',
                          method: 'PATCH',
                          body: {
                            'name': name.text.trim(),
                            'email': email.text.trim(),
                            if (store.user?['address'] is Map)
                              'address': {
                                'line': addressLine.text.trim(),
                                'barangay': barangay.text.trim(),
                                'city': city.text.trim(),
                                'province': province.text.trim(),
                              },
                          },
                        );
                        await store.refresh();
                        if (context.mounted) {
                          message(context, l.profileSaved);
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          message(context, errorText(context, e));
                        }
                      }
                      if (mounted) setState(() => busy = false);
                    },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  bool enabled = true;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => enabled = p.getBool('notifications') ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Screen(
      title: l.settings,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
              title: Text(l.languageTitle),
              subtitle: Text(l.languageBody),
              trailing: DropdownButton<String>(
                  key: const ValueKey('language-setting'),
                  value: localeController.locale.languageCode,
                  items: [
                    DropdownMenuItem(
                        value: LocaleController.english.languageCode,
                        child: Text(l.languageEnglish)),
                    DropdownMenuItem(
                        value: LocaleController.tagalog.languageCode,
                        child: Text(l.languageTagalog)),
                  ],
                  onChanged: (code) {
                    if (code != null) {
                      localeController.setLocale(Locale(code));
                    }
                  })),
          ListTile(
              title: Text(l.appearance),
              subtitle: Text(l.appearanceBody),
              trailing: DropdownButton<ThemeMode>(
                  value: themeController.mode,
                  items: ThemeMode.values
                      .map((mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(switch (mode) {
                            ThemeMode.system => l.themeSystem,
                            ThemeMode.light => l.themeLight,
                            ThemeMode.dark => l.themeDark,
                          })))
                      .toList(),
                  onChanged: (mode) {
                    if (mode != null) themeController.setMode(mode);
                  })),
          SwitchListTile(
            title: Text(l.showUnread),
            subtitle: Text(l.showUnreadBody),
            value: enabled,
            onChanged: (v) async {
              final p = await SharedPreferences.getInstance();
              await p.setBool('notifications', v);
              store.setUnreadPreference(v);
              if (mounted) setState(() => enabled = v);
            },
          ),
          gap(16),
          ListTile(
            title: Text(l.permissionsTitle),
            subtitle: Text(l.permissionsBody),
          ),
          ListTile(
            title: Text(l.privacy),
            subtitle: Text('${l.privacyBody} ${l.mapboxNotice}'),
          ),
          ListTile(
            title: Text(l.reportingGuide),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => go(context, '/help'),
          ),
          ListTile(
            title: Text(l.aboutPatag),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => go(context, '/about'),
          ),
          gap(),
          OutlinedButton(
            onPressed: () async {
              await store.logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/welcome', (_) => false);
              }
            },
            child: Text(l.signOut),
          ),
        ],
      ),
    );
  }
}

class InfoScreen extends StatelessWidget {
  final bool about;
  const InfoScreen({this.about = false, super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Screen(
      title: about ? l.aboutPatag : l.reportingGuide,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          mascot(width: 140, dance: true),
          gap(24),
          heading(
            context,
            about ? l.brandAboutHeading : l.guideHeading,
          ),
          gap(20),
          if (about) ...[
            Text(l.aboutMeaning),
            gap(),
            Text(l.aboutMission),
            gap(),
            Text(l.aboutAcademic),
          ] else
            ...<String, String>{
              l.guidePhotoTitle: l.guidePhotoBody,
              l.guideLocationTitle: '${l.guideLocationBody} ${l.mapboxNotice}',
              l.guideDescribeTitle: l.guideDescribeBody,
              l.guideDuplicatesTitle: l.guideDuplicatesBody,
              l.guideProgressTitle: l.guideProgressBody,
              l.guideOutcomesTitle: l.guideOutcomesBody,
              l.guideFeedbackTitle: l.guideFeedbackBody,
              l.guideConnectionTitle: l.guideConnectionBody,
            }.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        gap(8),
                        Text(e.value,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
