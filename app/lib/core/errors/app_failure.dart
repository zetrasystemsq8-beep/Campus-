import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// User-facing error. Services throw this; UI only shows [message].
class AppFailure implements Exception {
  const AppFailure(this.message, {this.isOffline = false});
  final String message;
  final bool isOffline;

  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;
    if (error is SocketException || error is TimeoutException) {
      return const AppFailure(
        'No internet connection. Check your data and try again.',
        isOffline: true,
      );
    }
    if (error is AuthException) {
      final m = error.message.toLowerCase();
      if (m.contains('invalid login')) return const AppFailure('Incorrect email or password.');
      if (m.contains('not confirmed')) {
        return const AppFailure('Please verify your email first. Check your inbox.');
      }
      if (m.contains('already registered')) {
        return const AppFailure('An account with this email already exists.');
      }
      if (m.contains('rate limit') || error.statusCode == '429') {
        return const AppFailure('Too many attempts. Please wait a few minutes.');
      }
      if (m.contains('weak') || m.contains('password should')) {
        return const AppFailure('Choose a stronger password (at least 8 characters).');
      }
      return AppFailure(error.message);
    }
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505':
          return const AppFailure('That already exists. Try another.');
        case '23514':
          return const AppFailure('Those selections do not match. Please review them.');
        case '54000':
          return const AppFailure('You have reached the daily limit for this. Try again tomorrow.');
        case '42501':
          return const AppFailure('You do not have permission to do that.');
      }
    }
    return const AppFailure('Something went wrong. Please try again.');
  }

  @override
  String toString() => message;
}

/// Runs [run] with a timeout and converts any error into an [AppFailure].
Future<T> guarded<T>(Future<T> Function() run) async {
  try {
    return await run().timeout(const Duration(seconds: 20));
  } catch (e) {
    throw AppFailure.from(e);
  }
}
