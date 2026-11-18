import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_config.dart';

class GoogleAuth {
  // Profile display data only. Authorization always uses the Supabase user ID.
  static Map<String, String> profileDefaults(User user,
      {String? name, String? email}) {
    final google = user.appMetadata['provider'] == 'google' ||
        (user.appMetadata['providers'] is List &&
            (user.appMetadata['providers'] as List).contains('google')) ||
        (user.identities?.any((identity) => identity.provider == 'google') ??
            false);
    if (!google) return {};
    final metadata = user.userMetadata ?? {};
    final fullName = metadata['full_name'] is String
        ? (metadata['full_name'] as String).trim()
        : metadata['name'] is String
            ? (metadata['name'] as String).trim()
            : '';
    return {
      if ((name ?? '').trim().isEmpty && fullName.isNotEmpty)
        'profileName':
            fullName.length > 50 ? fullName.substring(0, 50) : fullName,
      if ((email ?? '').trim().isEmpty && (user.email ?? '').trim().isNotEmpty)
        'profileEmail': user.email!.trim().toLowerCase(),
    };
  }

  /// Launching a browser is not a successful login: CloudGate waits for Auth.
  static Future<bool> start(SupabaseClient client,
      {http.Client? settingsClient, Future<bool> Function()? launch}) async {
    final transport = settingsClient ?? http.Client();
    try {
      final response = await transport.get(
        Uri.parse('${BackendConfig.url}/auth/v1/settings'),
        headers: {'apikey': BackendConfig.publishableKey},
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw const AuthException(
            'Could not check Google sign-in. Please try again.');
      }
      final settings = jsonDecode(response.body) as Map<String, dynamic>;
      if ((settings['external'] as Map?)?['google'] != true) {
        throw const AuthException(
            'Google sign-in is not enabled yet. Enable Google in Supabase Authentication to finish setup.');
      }
      return await (launch?.call() ??
          client.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: kIsWeb ? Uri.base.origin : BackendConfig.mobileCallback,
            queryParams: const {'prompt': 'select_account'},
          ));
    } finally {
      if (settingsClient == null) transport.close();
    }
  }
}
