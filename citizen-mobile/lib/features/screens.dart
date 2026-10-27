import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

import '../app/theme.dart';
import '../core/api.dart';
import '../core/models.dart';
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
                const Text(
                  'Pa-tag lubak, lubak patag.',
                  style: TextStyle(color: Colors.white),
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
                    TextButton(onPressed: done, child: const Text('Skip')),
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
                          'See a pothole? I-tag mo.',
                          'Pin it. Help us find it.',
                          'Follow every road forward.',
                        ][index],
                      ),
                      gap(),
                      Text(
                        [
                          'Take a clear photo and tell your LGU about the damaged road.',
                          'Use GPS or tap the map. Accurate locations help the right crew reach the site.',
                          'Track review, assignment and repair updates. Share feedback after LGU verification.',
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
                        child: const Text('Back'),
                      ),
                    Expanded(
                      child: action(index == 2 ? 'Get started' : 'Next', () {
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
                'Mas maayos na daan, nagsisimula sa’yo.',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(color: const Color(0xFF20180F), fontSize: 30),
              ),
              gap(),
              Text(
                'Report road damage. Follow the progress. Help your community move safely.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16),
              ),
              gap(32),
              action('Sign in', () => go(context, '/login')),
              gap(12),
              OutlinedButton(
                onPressed: () => go(context, '/register'),
                child: const Text('Create an account'),
              ),
              TextButton(
                onPressed: () => go(context, '/map'),
                child: const Text('Explore the public map'),
              ),
              gap(),
              Text(
                'Academic demonstration · IT 305\nNo official LGU records or partnerships.',
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
    for (final c in [name, email, password, addressLine, barangay, city, province]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit({bool demo = false}) async {
    if (!demo && !key.currentState!.validate()) return;
    if(register && signupStep < 2){setState(() {signupStep++;error='';});return;}
    if (register && !privacy) {
      setState(() => error = 'Please acknowledge the privacy information.');
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
                  if(register) 'address': {
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
      error = PatagStore.clean(e);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Screen(
        title: recovery
            ? 'Recover account'
            : register
                ? 'Create account'
                : 'Sign in',
        body: Form(
          key: key,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              logo(),
              gap(28),
              heading(
                context,
                recovery
                    ? 'Let’s get you back.'
                    : register
                        ? 'Join the road forward.'
                        : 'Tuloy po. Welcome back.',
              ),
              gap(),
              Text(
                'Development authentication · local demo API',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12),
              ),
              gap(24),
              if(register) ...[Text('Step ${signupStep+1} of 3 · ${['About you', 'Your address', 'Secure your account'][signupStep]}'), gap(), LinearProgressIndicator(value:(signupStep+1)/3), gap(20)],
              if (register && signupStep==0) field('Full name', name),
              if(!register || signupStep==0)
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email address'),
                validator: (s) =>
                    s != null && RegExp(r'^\S+@\S+\.\S+$').hasMatch(s)
                        ? null
                        : 'Enter a valid email address.',
              ),
              gap(),
              if(register && signupStep==1) ...[
                const Text('Your address stays on your private account. You will pin the pothole separately when reporting.'),
                gap(16),
                TextFormField(controller: addressLine, autofillHints: const [AutofillHints.streetAddressLine1], decoration: const InputDecoration(labelText: 'Street / house number (optional)')),
                gap(),
                TextFormField(controller: barangay, decoration: const InputDecoration(labelText: 'Barangay'), validator:(s)=>s!=null&&s.trim().isNotEmpty&&s.trim().length<=120?null:'Enter your barangay.'),
                gap(),
                TextFormField(controller: city, autofillHints: const [AutofillHints.addressCity], decoration: const InputDecoration(labelText: 'City / municipality'), validator:(s)=>s!=null&&s.trim().isNotEmpty&&s.trim().length<=120?null:'Enter your city or municipality.'),
                gap(),
                TextFormField(controller: province, autofillHints: const [AutofillHints.addressState], decoration: const InputDecoration(labelText: 'Province'), validator:(s)=>s!=null&&s.trim().isNotEmpty&&s.trim().length<=120?null:'Enter your province.'),
                gap(),
              ],
              if (!recovery && (!register || signupStep==2)) ...[
                TextFormField(
                  controller: password,
                  obscureText: hidden,
                  autofillHints: [
                    register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: hidden ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => hidden = !hidden),
                      icon: Icon(
                        hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (s) => s != null && (register ? s.runes.length >= 15 && s.runes.length <= 128 : s.isNotEmpty)
                      ? null
                      : register ? 'Use 15 to 128 characters.' : 'Enter your password.',
                ),
                gap(),
                if(register) const Text('Use 15–128 characters. A few unrelated words work well. Email ownership is not verified in this local preview.'),
                if (register)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: privacy,
                    onChanged: (v) => setState(() => privacy = v ?? false),
                    title: const Text(
                      'I understand this academic demo stores test account data locally. I will not use personal information.',
                    ),
                  ),
              ],
              if (error.isNotEmpty)
                Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (success.isNotEmpty) Text(success),
              gap(20),
              action(
                busy
                    ? 'Connecting…'
                    : recovery
                        ? 'Request recovery'
                        : register
                            ? (signupStep<2 ? 'Continue' : 'Create account')
                            : 'Sign in',
                busy ? null : () => submit(),
              ),
              if(register && signupStep>0) TextButton(onPressed:busy ? null : () => setState(() {signupStep--;error='';}),child:const Text('Back')),
              if(register && signupStep==0) TextButton(onPressed:() => go(context, '/login'),child:const Text('Already have an account? Sign in')),
              if (!register && !recovery) ...[
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  children: [
                    TextButton(onPressed: () => go(context, '/register'), child: const Text('Create an account')),
                    TextButton(onPressed: () => go(context, '/forgot-password'), child: const Text('Forgot password?')),
                  ],
                ),
                gap(20),
                Text(
                  'Explore the demo without a password.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                OutlinedButton(
                  onPressed: busy ? null : () => submit(demo: true),
                  child: const Text('Continue as demo citizen'),
                ),
              ],
            ],
          ),
        ),
      );
}

class CitizenHome extends StatelessWidget {
  const CitizenHome({super.key});
  @override
  Widget build(BuildContext context) {
    final name =
        (store.user?['name'] ?? 'Ka-PATAG').toString().split(' ').first;
    final rs = store.reports;
    return Screen(
      title: 'PATAG',
      selected: 0,
      actions: [
        IconButton(
          tooltip: 'Notifications',
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
                        'Hello, $name.',
                        style: const TextStyle(
                          fontSize: 26,
                          letterSpacing: -.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      gap(4),
                      Text(
                        'A little tag. A better road.',
                        style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Your profile',
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
                      child: Text('May lubak\nsa daan?',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                  color: const Color(0xFF20180F),
                                  fontSize: 32))),
                  gap(12),
                  Row(children: [
                    const Expanded(
                        flex: 3,
                        child: Text(
                            'I-tag mo na. Help your community move safely.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF38271D),
                                height: 1.5))),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: mascot(width: 100, dance: true)),
                  ]),
                  gap(22),
                  action(
                    'Report a pothole',
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
                const Expanded(
                  child: Text(
                    'Around you',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => go(context, '/map'),
                  child: const Text('Explore'),
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
                const Expanded(
                    child: Text(
                  'Your impact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                )),
                TextButton(
                  onPressed: () => go(context, '/reports'),
                  child: const Text('View reports'),
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
                        const Text(
                          'Total reports',
                          style: TextStyle(color: Colors.white, fontSize: 13),
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
                        const Text(
                          'Every tag counts.',
                          style: TextStyle(
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
                          'Under review',
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
                          'In progress',
                          rs.where((r) => r.status == 'In Progress').length,
                        ),
                        gap(14),
                        _metric(
                          'Resolved',
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
                const Text(
                  'Latest report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => go(context, '/reports'),
                  child: const Text('View all'),
                ),
              ],
            ),
            gap(10),
            if (rs.isEmpty)
              const EmptyState(
                'Your first tag starts here.',
                'Send a clear photo and a location.',
              ),
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
                      const Text(
                        'A clearer picture helps.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      gap(6),
                      Text(
                        'Stay safe, add a landmark and check your map pin.',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => go(context, '/help'),
                        child: const Text('Read the reporting guide'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            gap(12),
            Text(
              'Fictional demonstration reports · IT 305',
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
    return Screen(
      title: 'My reports',
      selected: 3,
      body: RefreshIndicator(
        onRefresh: store.refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            heading(context, 'Your tags. Their progress.'),
            gap(20),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search road or reference',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (s) => setState(() => query = s),
            ),
            gap(12),
            Wrap(
              spacing: 16,
              children: [
                ...['All', ...reportStatuses].map((s) => ChoiceChip(
                      label: Text(s),
                      selected: status == s,
                      onSelected: (_) => setState(() => status = s),
                    )),
                TextButton.icon(
                  onPressed: () => setState(() => newest = !newest),
                  icon: const Icon(Icons.sort),
                  label: Text(newest ? 'Newest first' : 'Oldest first'),
                ),
              ],
            ),
            gap(16),
            if (rs.isEmpty)
              const EmptyState(
                'No reports found',
                'Try another search or start a new report.',
              ),
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
    if (matches.isEmpty) {
      return const Screen(
        title: 'Report details',
        body: EmptyState(
          'Report not found',
          'Refresh your reports, or check the public map.',
        ),
      );
    }
    final report = matches.first;
    final completion = report.json['completion'];
    return Screen(
      title: 'Report details',
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
              'Brgy. ${report.barangay}, ${report.json['location']['city']}, ${report.json['location']['province']}',
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
            heading(context, 'The road to resolution'),
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
                                ? 'Awaiting LGU verification'
                                : entry['to'],
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
                            entry['at'].toString().substring(0, 10),
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
              heading(context, 'Repair documentation'),
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
                      'Share repair feedback',
                      () => go(context, '/reports/$id/feedback'),
                      icon: Icons.star_outline,
                    )
                  : const Text('Salamat! Your feedback is recorded.'),
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
        title: 'Report submitted',
        body: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            gap(24),
            mascot(width: 200, dance: true),
            gap(20),
            heading(context, 'Na-tag na ang lubak!'),
            gap(12),
            const Text(
              'Your report has been submitted for review. The LGU will check the evidence and location.',
            ),
            gap(20),
            Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
            gap(12),
            const Align(
              alignment: Alignment.centerLeft,
              child: StatusChip('Submitted'),
            ),
            gap(28),
            action('View report', () => go(context, '/reports/$id')),
            gap(12),
            OutlinedButton(
              onPressed: () => home(context),
              child: const Text('Return home'),
            ),
          ],
        ),
      );
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Screen(
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await store.call('/notifications/read', body: {'id': 'all'});
                await store.refresh();
              } catch (e) {
                if (context.mounted) message(context, PatagStore.clean(e));
              }
            },
            child: const Text('Read all'),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: store.refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (store.notifications.isEmpty)
                const EmptyState(
                  'All quiet for now',
                  'Report progress updates will appear here.',
                ),
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
                      '${n['reportId']} · ${n['at'].toString().substring(0, 10)}',
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
                          message(context, PatagStore.clean(e));
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
    if (rs.isEmpty || rs.first.status != 'Resolved') {
      return const Screen(
        title: 'Repair feedback',
        body: EmptyState(
          'Repair not yet verified',
          'Feedback opens after the LGU verifies the completed repair.',
        ),
      );
    }
    return Screen(
      title: 'Repair feedback',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          mascot(width: 120, dance: true),
          gap(20),
          heading(
            context,
            done ? 'Salamat sa feedback!' : 'How was the repair?',
          ),
          gap(12),
          if (done)
            const Text('Your feedback has been recorded.')
          else if (rs.first.json['feedback'] != null)
            const Text('You already shared feedback for this repair.')
          else ...[
            Text(widget.id),
            gap(20),
            Wrap(
              children: List.generate(
                5,
                (i) => IconButton(
                  tooltip: '${i + 1} stars',
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
            field('Your repair feedback', text, lines: 4),
            action(
              busy ? 'Submitting…' : 'Submit feedback',
              busy
                  ? null
                  : () async {
                      if (rating == 0 || text.text.trim().isEmpty) {
                        message(context, 'Choose a rating and add feedback.');
                        return;
                      }
                      setState(() => busy = true);
                      try {
                        await store.call(
                          '/reports/${widget.id}/feedback',
                          body: {'rating': rating, 'text': text.text.trim()},
                        );
                        await store.refresh();
                        if (mounted) setState(() => done = true);
                      } catch (e) {
                        if (context.mounted) {
                          message(context, PatagStore.clean(e));
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
        title: 'Your profile',
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
            heading(context, store.user?['name'] ?? 'Citizen'),
            gap(8),
            Text(store.user?['email'] ?? '',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if (store.user?['address'] is Map &&
                (store.user?['address']['barangay'] ?? '').toString().isNotEmpty) ...[
              gap(12),
              Text('Address · ${[
                store.user?['address']['line'],
                store.user?['address']['barangay'],
                store.user?['address']['city'],
                store.user?['address']['province'],
              ].where((part) => part != null && part.toString().isNotEmpty).join(', ')}'),
            ],
            gap(24),
            Text('${store.reports.length} community reports'),
            gap(16),
            ...<String, String>{
              'Edit profile': '/profile/edit',
              'Settings': '/settings',
              'Reporting guide': '/help',
              'About PATAG': '/about',
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
              label: const Text('Sign out'),
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
    String value(String key) => address is Map ? (address[key] ?? '').toString() : '';
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
  Widget build(BuildContext context) => Screen(
        title: 'Edit profile',
        body: Form(
          key: key,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              field('Full name', name),
              TextFormField(controller:email,readOnly:true,decoration:const InputDecoration(labelText:'Email address',helperText:'Email changes require verified account recovery.')),
              gap(),
              if (store.user?['address'] is Map) ...[
                const Text('Private address · separate from each road report'),
                gap(),
                TextFormField(controller:addressLine,decoration:const InputDecoration(labelText:'Street / house number (optional)')),
                gap(),
                TextFormField(controller:barangay,decoration:const InputDecoration(labelText:'Barangay'),validator:(s)=>s!=null&&s.trim().isNotEmpty&&s.trim().length<=120?null:'Enter your barangay.'),
                gap(),
                TextFormField(controller:city,decoration:const InputDecoration(labelText:'City / municipality'),validator:(s)=>s!=null&&s.trim().isNotEmpty&&s.trim().length<=120?null:'Enter your city or municipality.'),
                gap(),
                TextFormField(controller:province,decoration:const InputDecoration(labelText:'Province'),validator:(s)=>s!=null&&s.trim().isNotEmpty&&s.trim().length<=120?null:'Enter your province.'),
                gap(),
              ],
              action(
                'Save profile',
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
                              if (store.user?['address'] is Map) 'address': {
                                'line': addressLine.text.trim(),
                                'barangay': barangay.text.trim(),
                                'city': city.text.trim(),
                                'province': province.text.trim(),
                              },
                            },
                          );
                          await store.refresh();
                          if (context.mounted) {
                            message(context, 'Profile saved.');
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            message(context, PatagStore.clean(e));
                          }
                        }
                        if (mounted) setState(() => busy = false);
                      },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
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
  Widget build(BuildContext context) => Screen(
        title: 'Settings',
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
                title: const Text('Appearance'),
                subtitle:
                    const Text('Use light, dark, or your device setting.'),
                trailing: DropdownButton<ThemeMode>(
                    value: themeController.mode,
                    items: ThemeMode.values
                        .map((mode) => DropdownMenuItem(
                            value: mode, child: Text(mode.name)))
                        .toList(),
                    onChanged: (mode) {
                      if (mode != null) themeController.setMode(mode);
                    })),
            SwitchListTile(
              title: const Text('Show unread notification indicators'),
              subtitle: const Text(
                'Saved on this device. Update history remains available.',
              ),
              value: enabled,
              onChanged: (v) async {
                final p = await SharedPreferences.getInstance();
                await p.setBool('notifications', v);
                store.setUnreadPreference(v);
                if (mounted) setState(() => enabled = v);
              },
            ),
            gap(16),
            const ListTile(
              title: Text('Camera & location permissions'),
              subtitle: Text(
                'Permissions are requested when needed. If denied, choose a gallery photo or manually tap the map. You can manage access in Android Settings → Apps → PATAG.',
              ),
            ),
            const ListTile(
              title: Text('Privacy'),
              subtitle: Text(
                'Public reports omit your identity. This academic demo stores test records on a local API. Use fictional account information.',
              ),
            ),
            ListTile(
              title: const Text('Reporting guide'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => go(context, '/help'),
            ),
            ListTile(
              title: const Text('About PATAG'),
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
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
}

class InfoScreen extends StatelessWidget {
  final bool about;
  const InfoScreen({this.about = false, super.key});
  @override
  Widget build(BuildContext context) => Screen(
        title: about ? 'About PATAG' : 'Reporting guide',
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            mascot(width: 140, dance: true),
            gap(24),
            heading(
              context,
              about
                  ? 'I-tag ang lubak. Tungo sa patag.'
                  : 'A good report goes further.',
            ),
            gap(20),
            if (about) ...[
              const Text(
                'PATAG means a level or smooth surface. Read as “pa-tag”, it also means calling attention to a problem.',
              ),
              gap(),
              const Text(
                'Our mission is to empower communities to report road problems, connect citizens with local authorities, and turn reports into action.',
              ),
              gap(),
              const Text(
                'An academic final project for IT 305 – Advanced Web Development, Bulacan State University. This demonstration does not represent official LGU records or partnerships.',
              ),
            ] else
              ...<String, String>{
                '1. Photograph safely':
                    'Take clear photos of the damaged surface. Do not stand in traffic. Upload JPEG, PNG or WebP images under 8 MB.',
                '2. Set the location':
                    'Use GPS when permission is granted. If GPS is off, denied or inaccurate, tap the map to pin manually or enter coordinates. Add road, barangay, city and province.',
                '3. Describe the damage':
                    'Explain the pothole and hazards. Your severity estimate is reviewed by the LGU.',
                '4. Check for duplicates':
                    'Nearby reports on the same road may refer to the same damage. Inspect suggestions before submitting. The system never silently merges your report.',
                '5. Follow the progress':
                    'Submitted → Under Review → Verified → Assigned → In Progress → Resolved. Only an LGU-verified repair is Resolved.',
                'Other outcomes':
                    'Rejected reports include a reason. Duplicate means the LGU confirmed an existing case. Reports may be forwarded to the responsible agency.',
                '6. Share feedback':
                    'Once the repair is resolved, open your report and submit a rating and feedback.',
                'Connection & drafts':
                    'Your reporting draft is saved on this device. Submission needs internet access to the configured API. There is no automatic offline synchronization.',
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
