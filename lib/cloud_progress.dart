import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sound_effects.dart';
import 'google_auth.dart';
import 'quest_motion.dart';

/// Explicit allowlist: authentication tokens and local backup metadata never sync.
class ProgressSnapshot {
  static const keys = <String>{
    'profileName',
    'profileEmail',
    'avatar',
    'language',
    'scores',
    'days',
    'daily',
    'mistakes',
    'quizRewards',
    'missionCompletions',
    'seenAchievements',
    'bookmarks',
    'mastery',
    'learningSeconds',
    'dailyGoal',
    'challengeMode',
    'autoAdvance',
    'soundEnabled',
    'soundVolume',
    'reminders',
    'reminderHour',
    'reminderMinute'
  };
  static bool allowed(String key) =>
      keys.contains(key) ||
      RegExp(r'^code(Draft|Input)\.(cpp|python|java|c)(?:\.(?:lesson|mission)\.[a-z0-9_-]+)?$')
          .hasMatch(key);
  static Map<String, dynamic> read(SharedPreferences prefs) => {
        for (final key in (prefs.getKeys().where(allowed).toList()..sort()))
          key: prefs.get(key)
      };
  static Map<String, dynamic> validate(dynamic input) {
    if (input is! Map) throw const FormatException('Invalid cloud backup');
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final k = entry.key.toString(), v = entry.value;
      if (!allowed(k)) continue;
      const lists = {
        'days',
        'daily',
        'mistakes',
        'bookmarks',
        'quizRewards',
        'missionCompletions',
        'seenAchievements'
      };
      const integers = {
        'avatar',
        'dailyGoal',
        'reminderHour',
        'reminderMinute'
      };
      const booleans = {
        'challengeMode',
        'autoAdvance',
        'soundEnabled',
        'reminders'
      };
      final valid = lists.contains(k)
          ? v is List && v.every((x) => x is String)
          : integers.contains(k)
              ? v is int
              : booleans.contains(k)
                  ? v is bool
                  : k == 'soundVolume'
                      ? v is num && v >= 0 && v <= 1
                      : v is String;
      if (!valid) throw const FormatException('Invalid backup field type');
      if (k == 'soundVolume') {
        result[k] = (v as num).toDouble();
        continue;
      }
      if (v is String || v is bool || v is int || v is double) {
        result[k] = v;
      } else if (v is List && v.every((x) => x is String)) {
        result[k] = v.cast<String>();
      } else {
        throw const FormatException('Unsupported backup value');
      }
    }
    return result;
  }

  static Future<void> apply(
      SharedPreferences prefs, Map<String, dynamic> state) async {
    final clean = validate(state);
    for (final k in prefs.getKeys().where(allowed).toList()) {
      await prefs.remove(k);
    }
    for (final e in clean.entries) {
      final v = e.value;
      if (v is String) {
        await prefs.setString(e.key, v);
      } else if (v is bool) {
        await prefs.setBool(e.key, v);
      } else if (v is int) {
        await prefs.setInt(e.key, v);
      } else if (v is double) {
        await prefs.setDouble(e.key, v);
      } else {
        await prefs.setStringList(e.key, List<String>.from(v));
      }
    }
  }

  static String encode(Map<String, dynamic> state) =>
      jsonEncode({for (final k in (state.keys.toList()..sort())) k: state[k]});
}

class CloudProgress extends ChangeNotifier {
  static CloudProgress? instance;
  final SharedPreferences prefs;
  final SupabaseClient client;
  CloudProgress(this.prefs, this.client);
  bool ready = false, busy = false, conflict = false, checked = false;
  String? authMessage;
  Future<void>? _preparing;
  void reportAuthError(String message) {
    authMessage = message;
    notifyListeners();
  }

  Future<void> ensurePrepared() {
    if (uid == null || (ready && prefs.getString('cloud.owner') == uid)) {
      return Future.value();
    }
    return _preparing ??= prepare().whenComplete(() => _preparing = null);
  }

  String status = 'Your progress is saved on this device.';
  int revision = 0, generation = 0;
  String baseline = '{}';
  Timer? timer;
  String? get uid => client.auth.currentUser?.id;
  bool get hasLegacy =>
      prefs.getString('cloud.legacy') != null &&
      prefs.getString('cloud.legacy') != '{}' &&
      prefs.getString('cloud.legacy.owner') == uid;
  String cacheKey(String id) => 'cloud.cache.$id';
  Future<void> cache() async {
    final owner = prefs.getString('cloud.owner');
    if (owner != null) {
      final priorRaw = prefs.getString(cacheKey(owner));
      final prior = priorRaw == null
          ? <String, dynamic>{}
          : jsonDecode(priorRaw) as Map<String, dynamic>;
      await prefs.setString(
          cacheKey(owner),
          jsonEncode({
            'state': ProgressSnapshot.read(prefs),
            'revision': owner == uid ? revision : (prior['revision'] ?? 0),
            'baseline': owner == uid ? baseline : (prior['baseline'] ?? '{}')
          }));
    }
  }

  Future<void> prepare() async {
    authMessage = null;
    ready = false;
    notifyListeners();
    final id = uid;
    if (id == null) return;
    final owner = prefs.getString('cloud.owner');
    if (!prefs.containsKey('cloud.legacy.owner')) {
      await prefs.setString('cloud.legacy.owner', id);
    }
    if (owner != id) {
      if (owner != null) {
        await cache();
      } else if (!prefs.containsKey('cloud.legacy')) {
        await prefs.setString(
            'cloud.legacy', jsonEncode(ProgressSnapshot.read(prefs)));
      }
      final raw = prefs.getString(cacheKey(id));
      final data = raw == null
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      await ProgressSnapshot.apply(
          prefs, ProgressSnapshot.validate(data['state'] ?? {}));
      revision = (data['revision'] as num?)?.toInt() ?? 0;
      baseline = data['baseline'] as String? ?? '{}';
      await prefs.setString('cloud.owner', id);
    } else {
      final raw = prefs.getString(cacheKey(id));
      if (raw != null) {
        final data = jsonDecode(raw);
        revision = (data['revision'] as num?)?.toInt() ?? 0;
        baseline = data['baseline'] as String? ?? '{}';
      }
    }
    checked = false;
    conflict = false;
    await sync(restoreUnchanged: true);
    if (checked && !conflict && client.auth.currentUser != null) {
      final defaults = GoogleAuth.profileDefaults(client.auth.currentUser!,
          name: prefs.getString('profileName'),
          email: prefs.getString('profileEmail'));
      for (final entry in defaults.entries) {
        await prefs.setString(entry.key, entry.value);
      }
      if (defaults.isNotEmpty) {
        await cache();
        await sync();
      }
    }
    SoundEffects.instance.initialize(prefs);
    generation++;
    ready = true;
    notifyListeners();
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 20), (_) => sync());
  }

  Future<void> sync({bool restoreUnchanged = false}) async {
    if (busy ||
        uid == null ||
        prefs.getString('cloud.owner') != uid ||
        conflict) {
      return;
    }
    final id = uid!;
    busy = true;
    notifyListeners();
    try {
      final local = ProgressSnapshot.read(prefs),
          encoded = ProgressSnapshot.encode(ProgressSnapshot.read(prefs));
      final row = await client
          .from('learncodz_backups')
          .select()
          .eq('user_id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));
      if (uid != id) return;
      checked = true;
      if (row != null) {
        final remoteRev = (row['revision'] as num).toInt();
        final remote = ProgressSnapshot.validate(row['state']);
        if (remoteRev != revision) {
          if (encoded != baseline) {
            conflict = true;
            status =
                'Another device changed your backup. Restore cloud progress before syncing.';
            return;
          }
          if (!restoreUnchanged && ProgressSnapshot.encode(remote) != encoded) {
            conflict = true;
            status =
                'Newer cloud progress is available. Tap Restore cloud backup.';
            return;
          }
          await ProgressSnapshot.apply(prefs, remote);
          revision = remoteRev;
          baseline = ProgressSnapshot.encode(remote);
        }
        if (ProgressSnapshot.encode(ProgressSnapshot.read(prefs)) != baseline) {
          final result = await client
              .from('learncodz_backups')
              .update({
                'state': local,
                'revision': revision + 1,
                'updated_at': DateTime.now().toUtc().toIso8601String()
              })
              .eq('user_id', id)
              .eq('revision', revision)
              .select('revision')
              .timeout(const Duration(seconds: 15));
          if (result.isEmpty) {
            conflict = true;
            status =
                'Cloud changed during upload. Restore cloud backup to continue.';
            return;
          }
          revision++;
          baseline = encoded;
        }
      } else {
        await client
            .from('learncodz_backups')
            .insert({'user_id': id, 'state': local, 'revision': 1}).timeout(
                const Duration(seconds: 15));
        revision = 1;
        baseline = encoded;
      }
      await cache();
      status = 'Cloud backup up to date. Changes sync every 20 seconds.';
    } catch (_) {
      status =
          'Cloud unavailable. Progress is saved locally; tap Sync now to retry.';
      await cache();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    if (busy || uid == null) return;
    busy = true;
    notifyListeners();
    try {
      final row = await client
          .from('learncodz_backups')
          .select()
          .eq('user_id', uid!)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));
      if (row == null) {
        status = 'No cloud backup exists yet.';
        return;
      }
      final remote = ProgressSnapshot.validate(row['state']);
      ready = false;
      notifyListeners();
      await WidgetsBinding.instance.endOfFrame;
      await ProgressSnapshot.apply(prefs, remote);
      revision = (row['revision'] as num).toInt();
      baseline = ProgressSnapshot.encode(remote);
      conflict = false;
      checked = true;
      generation++;
      SoundEffects.instance.initialize(prefs);
      await cache();
      status = 'Cloud progress restored.';
    } catch (_) {
      status = 'Could not restore. Your local progress was kept.';
    } finally {
      ready = true;
      busy = false;
      notifyListeners();
    }
  }

  Future<void> importLegacy() async {
    final raw = prefs.getString('cloud.legacy');
    if (!hasLegacy || raw == null || busy) {
      return;
    }
    ready = false;
    notifyListeners();
    await WidgetsBinding.instance.endOfFrame;
    await ProgressSnapshot.apply(
        prefs, ProgressSnapshot.validate(jsonDecode(raw)));
    generation++;
    ready = true;
    notifyListeners();
    await sync();
  }

  Future<void> signOut() async {
    if (busy) return;
    timer?.cancel();
    ready = false;
    notifyListeners();
    await WidgetsBinding.instance.endOfFrame;
    await sync();
    await cache();
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // The SDK removes the local session before attempting server revocation.
      status =
          'Signed out on this device. Server revocation could not be confirmed.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

class CloudGate extends StatefulWidget {
  final Widget Function() child;
  const CloudGate({super.key, required this.child});
  @override
  State<CloudGate> createState() => _CloudGateState();
}

class _CloudGateState extends State<CloudGate> {
  CloudProgress get cloud => CloudProgress.instance!;
  StreamSubscription<AuthState>? sub;
  @override
  void initState() {
    super.initState();
    sub = cloud.client.auth.onAuthStateChange.listen((state) {
      if (state.session != null) {
        unawaited(prepareSession());
      }
      if (mounted) setState(() {});
    }, onError: (_) {
      cloud.reportAuthError('Sign-in was not completed. Please try again.');
      if (mounted) setState(() {});
    });
    if (cloud.uid != null && !cloud.ready) {
      scheduleMicrotask(prepareSession);
    }
  }

  Future<void> prepareSession() async {
    try {
      await cloud.ensurePrepared();
    } catch (_) {
      cloud.authMessage = 'Could not load this account. Please retry.';
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: cloud,
      builder: (context, _) {
        if (cloud.uid == null) return const CloudLogin();
        if (!cloud.ready || cloud.prefs.getString('cloud.owner') != cloud.uid) {
          return Scaffold(
              body: Center(
                  child: cloud.authMessage == null
                      ? const CircularProgressIndicator()
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(cloud.authMessage!),
                          FilledButton(
                              onPressed: prepareSession,
                              child: const Text('Retry'))
                        ])));
        }
        return _AccountNavigator(
            key: ValueKey('${cloud.uid}:${cloud.generation}'),
            child: widget.child);
      });
}

class _AccountNavigator extends StatefulWidget {
  final Widget Function() child;
  const _AccountNavigator({super.key, required this.child});
  @override
  State<_AccountNavigator> createState() => _AccountNavigatorState();
}

class _AccountNavigatorState extends State<_AccountNavigator> {
  final navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => NavigatorPopHandler<Object?>(
        onPopWithResult: (result) => navigator.currentState!.pop(result),
        child: Navigator(
            key: navigator,
            onGenerateRoute: (_) =>
                MaterialPageRoute(builder: (_) => widget.child())),
      );
}

class CloudLogin extends StatefulWidget {
  final Future<bool> Function()? googleSignIn;
  const CloudLogin({super.key, this.googleSignIn});
  @override
  State<CloudLogin> createState() => _CloudLoginState();
}

class _CloudLoginState extends State<CloudLogin> {
  final email = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool signup = false, busy = false, hidden = true;
  String? message;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    final cloud = CloudProgress.instance!;
    cloud.ready = false;
    cloud.authMessage = null;
    try {
      if (signup) {
        final response = await cloud.client.auth
            .signUp(email: email.text.trim(), password: password.text);
        if (response.session == null) {
          if (mounted) {
            setState(() => message =
                'Check your email to confirm your account, then return here and sign in.');
          }
          return;
        }
      } else {
        await cloud.client.auth.signInWithPassword(
            email: email.text.trim(), password: password.text);
      }
      await cloud.ensurePrepared();
    } on AuthException catch (e) {
      if (mounted) setState(() => message = e.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => message = 'Could not connect. Check internet and try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> googleSignIn() async {
    setState(() {
      busy = true;
      message = null;
    });
    CloudProgress.instance?.authMessage = null;
    try {
      final launched = await (widget.googleSignIn?.call() ??
          GoogleAuth.start(CloudProgress.instance!.client));
      if (mounted) {
        setState(() => message = launched
            ? 'Finish signing in in your browser. If you cancelled, you can try again.'
            : 'Could not open your browser. Please try again.');
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => message = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => message =
            'Could not start Google sign-in. Check internet and try again.');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: QuestEntrance(
          child: SafeArea(
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Form(
                          key: form,
                          child: ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(28),
                              children: [
                                const Icon(Icons.school_rounded,
                                    size: 68, color: Color(0xFF419500)),
                                const SizedBox(height: 20),
                                Text('LearnCodz',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge,
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                Text(
                                    signup
                                        ? 'Create your learning account'
                                        : 'Welcome back, coder',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                const Text(
                                    'Keep your lessons, progress and code drafts backed up across devices.',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 24),
                                QuestPress(
                                    child: OutlinedButton.icon(
                                        icon: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: AnimatedSwitcher(
                                                duration: Duration(
                                                    milliseconds:
                                                        MediaQuery.disableAnimationsOf(context)
                                                            ? 0
                                                            : 180),
                                                child: busy
                                                    ? SizedBox(
                                                        key: const ValueKey(
                                                            'loading'),
                                                        width: 20,
                                                        height: 20,
                                                        child: MediaQuery.disableAnimationsOf(context)
                                                            ? const Icon(Icons.hourglass_top,
                                                                size: 20)
                                                            : const CircularProgressIndicator(
                                                                strokeWidth: 2))
                                                    : Image.asset(
                                                        'assets/branding/google_g.png',
                                                        key:
                                                            const ValueKey('google'),
                                                        width: 32,
                                                        height: 32,
                                                        excludeFromSemantics: true))),
                                        onPressed: busy ? null : googleSignIn,
                                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: const Color(0xFF1F1F1F), backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFF747775))),
                                        label: const Text('Continue with Google'))),
                                const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text('or use your email',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54))),
                                TextFormField(
                                    controller: email,
                                    enabled: !busy,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.mail_outline),
                                        border: OutlineInputBorder()),
                                    validator: (v) =>
                                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                .hasMatch(v?.trim() ?? '')
                                            ? null
                                            : 'Enter a valid email.'),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: password,
                                    enabled: !busy,
                                    obscureText: hidden,
                                    autofillHints: [
                                      signup
                                          ? AutofillHints.newPassword
                                          : AutofillHints.password
                                    ],
                                    decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        border: const OutlineInputBorder(),
                                        suffixIcon: IconButton(
                                            onPressed: () => setState(
                                                () => hidden = !hidden),
                                            icon: Icon(hidden
                                                ? Icons.visibility_outlined
                                                : Icons
                                                    .visibility_off_outlined))),
                                    validator: (v) => (v ?? '').length <
                                            (signup ? 8 : 1)
                                        ? 'Enter ${signup ? 'at least 8 characters' : 'your password'}.'
                                        : null),
                                const SizedBox(height: 22),
                                QuestPress(
                                    child: FilledButton(
                                        onPressed: busy ? null : submit,
                                        child: Text(busy
                                            ? 'Connecting...'
                                            : signup
                                                ? 'Create account'
                                                : 'Sign in'))),
                                TextButton(
                                    onPressed: busy
                                        ? null
                                        : () => setState(() {
                                              signup = !signup;
                                              message = null;
                                            }),
                                    child: Text(signup
                                        ? 'Already registered? Sign in'
                                        : 'New here? Create an account')),
                                if (CloudProgress.instance?.authMessage != null)
                                  Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(CloudProgress
                                          .instance!.authMessage!)),
                                if (message != null)
                                  Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: QuestEntrance(
                                          key: ValueKey(message),
                                          child: Text(message!,
                                              textAlign: TextAlign.center))),
                                const Text(
                                    'Internet is needed to sign in. Once signed in, learning works offline and backup retries when connected.',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                    textAlign: TextAlign.center),
                              ])))))));
}

class CloudAccountCard extends StatelessWidget {
  const CloudAccountCard({super.key});
  Future<bool> confirm(BuildContext context, String title, String text) =>
      showDialog<bool>(
          context: context,
          builder: (c) =>
              AlertDialog(title: Text(title), content: Text(text), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Continue'))
              ])).then((v) => v ?? false);
  @override
  Widget build(BuildContext context) {
    final cloud = CloudProgress.instance;
    if (cloud == null) return const SizedBox.shrink();
    return AnimatedBuilder(
        animation: cloud,
        builder: (context, _) => Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Account & cloud backup',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(cloud.client.auth.currentUser?.email ?? ''),
                      Text(cloud.status),
                      if (cloud.busy) const LinearProgressIndicator(),
                      Wrap(spacing: 8, children: [
                        TextButton.icon(
                            onPressed: cloud.busy || cloud.conflict
                                ? null
                                : () => cloud.sync(),
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text('Sync now')),
                        TextButton(
                            onPressed: cloud.busy
                                ? null
                                : () async {
                                    if (await confirm(
                                        context,
                                        'Restore cloud backup?',
                                        'This replaces progress and code drafts on this device with the cloud backup.')) {
                                      await cloud.restore();
                                    }
                                  },
                            child: const Text('Restore cloud backup')),
                        if (cloud.hasLegacy)
                          TextButton(
                              onPressed: cloud.busy
                                  ? null
                                  : () async {
                                      if (await confirm(
                                          context,
                                          'Import previous offline progress?',
                                          'This replaces this account’s current local progress with the progress saved before cloud accounts were added.')) {
                                        await cloud.importLegacy();
                                      }
                                    },
                              child: const Text(
                                  'Import previous offline progress')),
                      ]),
                      const SizedBox(height: 16),
                      QuestPress(
                          child: FilledButton.icon(
                              onPressed: cloud.busy
                                  ? null
                                  : () async {
                                      if (await confirm(context, 'Sign out?',
                                          'Unsynced progress stays on this device for this account.')) {
                                        await cloud.signOut();
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF173D38),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18))),
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Logout',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800)))),
                      const SizedBox(height: 12),
                      const Text(
                          'Profile email is a contact field. Your sign-in email is shown above.',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                    ]))));
  }
}
