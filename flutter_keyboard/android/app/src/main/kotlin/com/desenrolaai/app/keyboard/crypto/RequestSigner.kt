package com.desenrolaai.app.keyboard.crypto

import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.MessageDigest
import java.security.Signature
import java.security.spec.PKCS8EncodedKeySpec
import java.util.UUID

/**
 * Signs API requests using Ed25519 asymmetric cryptography.
 * The private key is fragmented in KeyFragments and reconstructed at runtime.
 * The server only has the public key - if breached, attacker cannot forge requests.
 */
object RequestSigner {

    private const val VALIDITY_WINDOW_SECONDS = 30

    /**
     * Sign a request payload.
     * Returns a SignedRequest with signature, timestamp, and nonce headers.
     */
    fun sign(requestBody: String): SignedRequest {
        val timestamp = (System.currentTimeMillis() / 1000).toString()
        val nonce = UUID.randomUUID().toString().replace("-", "")

        // Create the message to sign: timestamp|nonce|sha256(body)
        val bodyHash = sha256Hex(requestBody)
        val message = "$timestamp|$nonce|$bodyHash"

        // Reconstruct private key from fragments (only in RAM, never stored)
        val privateSeed = KeyFragments.reconstruct()

        // Build Ed25519 private key from seed
        // PKCS8 header for Ed25519: 302e020100300506032b657004220420 + 32 bytes seed
        val pkcs8Header = byteArrayOf(
            0x30, 0x2e, 0x02, 0x01, 0x00, 0x30, 0x05, 0x06,
            0x03, 0x2b, 0x65, 0x70, 0x04, 0x22, 0x04, 0x20
        )
        val pkcs8Key = pkcs8Header + privateSeed

        val keySpec = PKCS8EncodedKeySpec(pkcs8Key)
        val keyFactory = KeyFactory.getInstance("Ed25519")
        val privateKey = keyFactory.generatePrivate(keySpec)

        // Sign the message
        val sig = Signature.getInstance("Ed25519")
        sig.initSign(privateKey)
        sig.update(message.toByteArray(Charsets.UTF_8))
        val signatureBytes = sig.sign()

        // Clear private key material from memory
        privateSeed.fill(0)
        pkcs8Key.fill(0)

        return SignedRequest(
            signature = android.util.Base64.encodeToString(signatureBytes, android.util.Base64.NO_WRAP),
            timestamp = timestamp,
            nonce = nonce
        )
    }

    private fun sha256Hex(input: String): String {
        val md = MessageDigest.getInstance("SHA-256")
        val hash = md.digest(input.toByteArray(Charsets.UTF_8))
        return hash.joinToString("") { "%02x".format(it) }
    }

    data class SignedRequest(
        val signature: String,
        val timestamp: String,
        val nonce: String
    )
}
