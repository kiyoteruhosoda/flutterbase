import 'package:flutter/services.dart';

/// The P-256 public key of a [DeviceKey]: x and y, 32 bytes each.
final class DevicePublicKey {
  const DevicePublicKey(this.x, this.y);

  final Uint8List x;
  final Uint8List y;
}

/// The app's own signing key, kept where it cannot be copied out
/// (docs/adr/0015-dpop-device-key.md).
abstract interface class DeviceKey {
  /// The public half, creating the key on first use.
  Future<DevicePublicKey> publicKey();

  /// ECDSA P-256 with SHA-256 over [message]; the signature is DER.
  Future<Uint8List> signDer(Uint8List message);

  /// Forgets the key (sign-out): the next sign-in makes a new one.
  Future<void> delete();
}

/// [DeviceKey] in the Android Keystore, through `MainActivity`'s channel.
///
/// Throws [PlatformException] (or [MissingPluginException] where there is no
/// Android side, e.g. tests) when the Keystore cannot be used.
final class KeystoreDeviceKey implements DeviceKey {
  const KeystoreDeviceKey([
    this._channel = const MethodChannel('nolumia/dpop_key'),
  ]);

  final MethodChannel _channel;

  @override
  Future<DevicePublicKey> publicKey() async {
    final answer = await _channel.invokeMapMethod<String, Object?>('publicKey');
    final x = answer?['x'];
    final y = answer?['y'];
    if (x is! Uint8List ||
        y is! Uint8List ||
        x.length != 32 ||
        y.length != 32) {
      throw PlatformException(
        code: 'device_key',
        message: 'The Keystore answered no P-256 public key.',
      );
    }
    return DevicePublicKey(x, y);
  }

  @override
  Future<Uint8List> signDer(Uint8List message) async {
    final signature = await _channel.invokeMethod<Uint8List>('sign', message);
    if (signature == null) {
      throw PlatformException(
        code: 'device_key',
        message: 'The Keystore answered no signature.',
      );
    }
    return signature;
  }

  @override
  Future<void> delete() => _channel.invokeMethod<void>('delete');
}
