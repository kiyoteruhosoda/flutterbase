package com.nolumia.flutterbase

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.math.BigInteger
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Signature
import java.security.interfaces.ECPublicKey
import java.security.spec.ECGenParameterSpec

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DPOP_KEY_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "publicKey" -> result.success(DeviceKey.publicKey())
                        "sign" -> result.success(DeviceKey.sign(call.arguments as ByteArray))
                        "delete" -> {
                            DeviceKey.delete()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("device_key", e.javaClass.simpleName, null)
                }
            }
    }

    /**
     * The app's own DPoP key in the Android Keystore (docs/adr/0015-dpop-device-key.md).
     *
     * P-256, signing only, never leaves the Keystore (StrongBox when the phone has one).
     * Each app has its own key: the Keystore is per app, so another app cannot use it.
     * No user authentication per use — the app signs every API call.
     */
    private object DeviceKey {
        private const val ALIAS = "dpop"
        private const val KEYSTORE = "AndroidKeyStore"

        private fun keyStore(): KeyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }

        private fun ensureKey(): KeyStore {
            val store = keyStore()
            if (!store.containsAlias(ALIAS)) {
                try {
                    generate(strongBox = true)
                } catch (e: StrongBoxUnavailableException) {
                    generate(strongBox = false)
                }
            }
            return store
        }

        private fun generate(strongBox: Boolean) {
            val spec = KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_SIGN)
                .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setIsStrongBoxBacked(strongBox)
                .build()
            KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, KEYSTORE).run {
                initialize(spec)
                generateKeyPair()
            }
        }

        /** The public key's coordinates, 32 bytes each (big-endian). */
        fun publicKey(): Map<String, ByteArray> {
            val key = ensureKey().getCertificate(ALIAS).publicKey as ECPublicKey
            return mapOf("x" to fixed32(key.w.affineX), "y" to fixed32(key.w.affineY))
        }

        /** SHA256withECDSA over [message]; the signature is DER (Dart converts it to JOSE). */
        fun sign(message: ByteArray): ByteArray {
            val key = ensureKey().getKey(ALIAS, null) as PrivateKey
            return Signature.getInstance("SHA256withECDSA").run {
                initSign(key)
                update(message)
                sign()
            }
        }

        fun delete() {
            val store = keyStore()
            if (store.containsAlias(ALIAS)) store.deleteEntry(ALIAS)
        }

        private fun fixed32(value: BigInteger): ByteArray {
            val bytes = value.toByteArray()
            return when {
                bytes.size == 32 -> bytes
                bytes.size > 32 -> bytes.copyOfRange(bytes.size - 32, bytes.size)
                else -> ByteArray(32 - bytes.size) + bytes
            }
        }
    }

    private companion object {
        const val DPOP_KEY_CHANNEL = "nolumia/dpop_key"
    }
}
