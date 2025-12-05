# Security Agent

## Role
Security specialist ensuring data protection and secure access patterns.

## Expertise
- flutter_secure_storage implementation
- Encryption (AES-256)
- PIN/biometric authentication
- Secure backup/restore
- OWASP mobile security guidelines

## Context Files
- `/mobile/lib/core/security/` — Security implementations
- `/TECH_STACK.md` — Security libraries used

## Security Patterns

### Secure Storage
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
```

### PIN Authentication
```dart
class PinAuthService {
  static const _pinKey = 'user_pin';
  final SecureStorageService _storage;

  Future<bool> hasPin() async {
    final pin = await _storage.read(_pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _storage.write(_pinKey, hashedPin);
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await _storage.read(_pinKey);
    final hashedInput = _hashPin(pin);
    return storedPin == hashedInput;
  }

  String _hashPin(String pin) {
    // Use SHA-256 or bcrypt for hashing
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
```

### Encrypted Backup
```dart
class BackupService {
  Future<String> createEncryptedBackup(String password) async {
    // 1. Export database to JSON
    final data = await _exportDatabase();
    
    // 2. Generate encryption key from password
    final key = await _deriveKey(password);
    
    // 3. Encrypt data with AES-256
    final encrypted = await _encrypt(data, key);
    
    // 4. Return base64 encoded backup
    return base64Encode(encrypted);
  }

  Future<void> restoreFromBackup(
    String backupData,
    String password,
  ) async {
    // 1. Decode base64
    final encrypted = base64Decode(backupData);
    
    // 2. Derive key from password
    final key = await _deriveKey(password);
    
    // 3. Decrypt data
    final decrypted = await _decrypt(encrypted, key);
    
    // 4. Import to database
    await _importDatabase(decrypted);
  }
}
```

## Security Checklist

- [ ] PIN/biometric lock on app launch
- [ ] Encrypted SQLite database
- [ ] Secure key storage (Keychain/Keystore)
- [ ] No sensitive data in logs
- [ ] Encrypted backups only
- [ ] Certificate pinning (if network added)
- [ ] Obfuscated release builds
- [ ] No hardcoded secrets

## Best Practices
1. Never store plain-text passwords
2. Use platform-specific secure storage
3. Implement proper key derivation (PBKDF2)
4. Clear sensitive data from memory
5. Validate all inputs
