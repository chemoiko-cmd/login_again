import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  final GoogleSignIn _signIn = GoogleSignIn(scopes: _scopes);

  Future<String?> getAccessToken() async {
    GoogleSignInAccount? account;
    try {
      // Ensure account chooser is shown instead of silently reusing last account.
      await _signIn.signOut();
      try {
        await _signIn.disconnect();
      } catch (e) {
        // Best-effort: disconnect can fail on some devices; still try signIn.
        print('GoogleSignIn disconnect failed (ignored): $e');
      }
      account = await _signIn.signIn();
    } on PlatformException catch (e) {
      print('GoogleSignIn PlatformException: ${e.code} ${e.message}');
      return null;
    } catch (_) {
      return null;
    }

    if (account == null) {
      print('GoogleSignIn: account is null (user cancelled / dismissed UI)');
      return null;
    }

    try {
      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        print('Google access token: $accessToken');
        return accessToken;
      }
      print('GoogleSignIn: accessToken was null/empty');
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
  }
}
