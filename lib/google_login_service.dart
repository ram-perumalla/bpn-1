import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'model/constants.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  factory AuthService() => instance;
  AuthService._();

  final FlutterAppAuth _appAuth = FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<bool> initAuth() async {
    final storedRefreshToken = await _secureStorage.read(key: REFRESH_TOKEN_KEY);
    TokenResponse? result;

    if (storedRefreshToken == null) {
      return false;
    }

    try {
      result = await _appAuth.token(
        TokenRequest(
          clientID(),
          redirectUrl(),
          issuer: GOOGLE_ISSUER,
          refreshToken: storedRefreshToken,
        ),
      );

      final bool setResult = await _handleAuthResult(result);
      return setResult;
    } catch (e, s) {
      print('error on Refresh Token: $e - stack: $s');
      return false;
    }
  }

  Future<String?> login() async {
    AuthorizationTokenRequest? authorizationTokenRequest;

    try {
      authorizationTokenRequest = AuthorizationTokenRequest(
        clientID(),
        redirectUrl(),
        issuer: GOOGLE_ISSUER,
        scopes: ['email', 'profile'],
      );

      final AuthorizationTokenResponse? result =
          await _appAuth.authorizeAndExchangeCode(authorizationTokenRequest);

      await _handleAuthResult(result);
      return result?.idToken;
    } on PlatformException {
      print("User has cancelled or no internet!");
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> logout() async {
    await _secureStorage.delete(key: REFRESH_TOKEN_KEY);
    return true;
  }

  Future<bool> _handleAuthResult(result) async {
    final bool isValidResult =
        result != null && result.accessToken != null && result.idToken != null;
    if (isValidResult) {
      if (result.refreshToken != null) {
        await _secureStorage.write(
          key: REFRESH_TOKEN_KEY,
          value: result.refreshToken!,
        );
      }

      final String googleAccessToken = result.accessToken!;

      const String backendToken = 'TOKEN';
      if (backendToken != null) {
        await _secureStorage.write(
          key: BACKEND_TOKEN_KEY,
          value: backendToken,
        );
      }
      return true;
    } else {
      return false;
    }
  }
}
