import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../database/database_helper.dart';

/// Security service for PIN and biometric authentication.
///
/// Implements PBKDF2 for PIN hashing with salt.
/// Provides attempt limiting and biometric toggle.
class SecurityService {
  SecurityService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
    DatabaseHelper? databaseHelper,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication(),
        _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;
  final DatabaseHelper _databaseHelper;

  // Storage keys
  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const String _attemptCountKey = 'pin_attempt_count';
  static const String _lockoutUntilKey = 'pin_lockout_until';
  static const String _biometricEnabledKey = 'biometric_enabled';

  // Security parameters
  static const int _pbkdf2Iterations = 100000;
  static const int _saltLength = 32;
  static const int _hashLength = 32;
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);

  /// Checks if a PIN has been set up.
  Future<bool> isPinSetUp() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Sets up a new PIN.
  Future<void> setUpPin(String pin) async {
    if (pin.length < 4 || pin.length > 8) {
      throw const SecurityException('PIN must be 4-8 digits');
    }

    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw const SecurityException('PIN must contain only digits');
    }

    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    await _secureStorage.write(key: _pinSaltKey, value: base64Encode(salt));
    await _secureStorage.write(key: _pinHashKey, value: base64Encode(hash));
    await _resetAttemptCounter();
  }

  /// Changes the PIN after verifying the current one.
  Future<void> changePin(String currentPin, String newPin) async {
    final isValid = await verifyPin(currentPin);
    if (!isValid) {
      throw const SecurityException('Current PIN is incorrect');
    }

    await setUpPin(newPin);
  }

  /// Removes the PIN protection.
  Future<void> removePin(String currentPin) async {
    final isValid = await verifyPin(currentPin);
    if (!isValid) {
      throw const SecurityException('PIN is incorrect');
    }

    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
    await _resetAttemptCounter();
    await setBiometricEnabled(false);
  }

  /// Verifies a PIN attempt.
  Future<bool> verifyPin(String pin) async {
    // Check if locked out
    final lockoutUntil = await _getLockoutUntil();
    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
      final remaining = lockoutUntil.difference(DateTime.now());
      throw SecurityException(
        'Too many attempts. Try again in ${remaining.inMinutes + 1} minutes.',
      );
    }

    final storedHash = await _secureStorage.read(key: _pinHashKey);
    final storedSalt = await _secureStorage.read(key: _pinSaltKey);

    if (storedHash == null || storedSalt == null) {
      throw const SecurityException('PIN not set up');
    }

    final salt = base64Decode(storedSalt);
    final expectedHash = base64Decode(storedHash);
    final actualHash = _hashPin(pin, salt);

    final isValid = _constantTimeCompare(expectedHash, actualHash);

    if (isValid) {
      await _resetAttemptCounter();
    } else {
      await _incrementAttemptCounter();
    }

    return isValid;
  }

  /// Gets remaining attempts before lockout.
  Future<int> getRemainingAttempts() async {
    final count = await _getAttemptCount();
    return _maxAttempts - count;
  }

  /// Checks if the account is currently locked out.
  Future<bool> isLockedOut() async {
    final lockoutUntil = await _getLockoutUntil();
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil);
  }

  /// Gets the lockout end time if locked.
  Future<DateTime?> getLockoutEndTime() async {
    return _getLockoutUntil();
  }

  // ============ Biometric Authentication ============

  /// Checks if biometric authentication is available.
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Gets available biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Checks if biometric is enabled for this app.
  Future<bool> isBiometricEnabled() async {
    final value = await _databaseHelper.getSetting(_biometricEnabledKey);
    return value == 'true';
  }

  /// Enables or disables biometric authentication.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _databaseHelper.setSetting(
      _biometricEnabledKey,
      enabled.toString(),
    );
  }

  /// Authenticates using biometrics.
  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access Laundry Logger',
  }) async {
    if (!await isBiometricEnabled()) {
      return false;
    }

    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ============ Recovery ============

  /// Gets recovery instructions (no network reset).
  String getRecoveryInstructions() {
    return '''
PIN Recovery Options:

1. **Restore from Backup**: If you have an encrypted backup, you can 
   reinstall the app and restore your data. The backup does not include 
   PIN settings, so you can set a new PIN after restore.

2. **Wait for Lockout**: After 5 failed attempts, wait 5 minutes for 
   the lockout to expire and try again.

3. **Clear App Data**: As a last resort, you can clear the app data 
   from device settings. This will reset the PIN but also delete all 
   your laundry data unless you have a backup.

Note: For security, there is no network-based PIN reset. Keep your 
backup files in a secure location.
''';
  }

  // ============ Private Methods ============

  /// Generates a cryptographically secure random salt.
  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(_saltLength, (_) => random.nextInt(256)),
    );
  }

  /// Hashes a PIN using PBKDF2 with SHA-256.
  Uint8List _hashPin(String pin, Uint8List salt) {
    final pinBytes = utf8.encode(pin);

    // PBKDF2 implementation using crypto package
    var block1 = Hmac(sha256, pinBytes).convert([...salt, 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(block1);

    for (var i = 1; i < _pbkdf2Iterations; i++) {
      block1 = Hmac(sha256, pinBytes).convert(block1).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block1[j];
      }
    }

    return result.sublist(0, _hashLength);
  }

  /// Constant-time comparison to prevent timing attacks.
  bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  Future<int> _getAttemptCount() async {
    final count = await _secureStorage.read(key: _attemptCountKey);
    return int.tryParse(count ?? '0') ?? 0;
  }

  Future<void> _incrementAttemptCounter() async {
    final count = await _getAttemptCount();
    final newCount = count + 1;
    await _secureStorage.write(
      key: _attemptCountKey,
      value: newCount.toString(),
    );

    if (newCount >= _maxAttempts) {
      final lockoutUntil = DateTime.now().add(_lockoutDuration);
      await _secureStorage.write(
        key: _lockoutUntilKey,
        value: lockoutUntil.toIso8601String(),
      );
    }
  }

  Future<void> _resetAttemptCounter() async {
    await _secureStorage.write(key: _attemptCountKey, value: '0');
    await _secureStorage.delete(key: _lockoutUntilKey);
  }

  Future<DateTime?> _getLockoutUntil() async {
    final value = await _secureStorage.read(key: _lockoutUntilKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}

/// Exception thrown for security-related errors.
class SecurityException implements Exception {
  const SecurityException(this.message);

  final String message;

  @override
  String toString() => 'SecurityException: $message';
}
