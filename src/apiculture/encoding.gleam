//// Encoding abstraction.
////
//// This module is a thin wrapper around yabase for encoding and decoding
//// bytes. It normalizes decoding failures to apiculture's `Error` type and
//// records whether an encoding uses padding.

import apiculture/error.{type Error}
import yabase/core/encoding as ybase
import yabase/core/error as yerror

/// A byte-to-text encoding and its padding behavior.
pub type Encoding {
  Encoding(inner: ybase.Encoding, uses_padding: Bool)
}

/// Encode bytes to string using the given encoding.
pub fn encode(encoding: Encoding, bytes: BitArray) -> String {
  case ybase.encode(encoding.inner, bytes) {
    Ok(s) -> s
    Error(_) -> panic as "yabase encode failed unexpectedly"
  }
}

/// Decode string to bytes using the given encoding.
pub fn decode(encoding: Encoding, input: String) -> Result(BitArray, Error) {
  case ybase.decode_as(encoding.inner, input) {
    Ok(bytes) -> Ok(bytes)
    Error(yerror.InvalidCharacter(..)) -> Error(error.MalformedInput)
    Error(yerror.InvalidLength(..)) -> Error(error.MalformedInput)
    Error(yerror.UnsupportedPrefix(..)) -> Error(error.MalformedInput)
    Error(yerror.UnsupportedMultibaseEncoding(..)) ->
      Error(error.MalformedInput)
    Error(yerror.InvalidChecksum) -> Error(error.MalformedInput)
    Error(yerror.InvalidHrp(..)) -> Error(error.MalformedInput)
    Error(yerror.Overflow) -> Error(error.MalformedInput)
    Error(yerror.NonCanonical) -> Error(error.MalformedInput)
    Error(yerror.NegativeValue(..)) -> Error(error.MalformedInput)
    Error(yerror.UnsupportedForInt(..)) -> Error(error.MalformedInput)
  }
}

/// Returns whether the encoding uses padding.
pub fn uses_padding(encoding: Encoding) -> Bool {
  encoding.uses_padding
}

/// Returns the name of the encoding.
pub fn name(encoding: Encoding) -> String {
  ybase.multibase_name(encoding.inner)
}

// ============================================================================
// Encoding constructors (thin wrappers around yabase)
// ============================================================================

/// Lowercase hexadecimal encoding.
pub fn hex_lower() -> Encoding {
  Encoding(inner: ybase.base16(), uses_padding: False)
}

/// Uppercase hexadecimal encoding.
pub fn hex_upper() -> Encoding {
  Encoding(inner: ybase.base16(), uses_padding: False)
}

/// RFC 4648 Base32 encoding (padded variant).
pub fn base32_rfc() -> Encoding {
  Encoding(inner: ybase.base32_rfc4648(), uses_padding: True)
}

/// RFC 4648 Base32 encoding (unpadded variant).
pub fn base32_rfc_unpadded() -> Encoding {
  Encoding(inner: ybase.base32_rfc4648(), uses_padding: False)
}

/// Base32hex encoding.
pub fn base32_hex() -> Encoding {
  Encoding(inner: ybase.base32_hex(), uses_padding: True)
}

/// Crockford's Base32 encoding.
pub fn base32_crockford() -> Encoding {
  Encoding(inner: ybase.base32_crockford(), uses_padding: False)
}

/// z-base-32 encoding.
pub fn base32_z() -> Encoding {
  Encoding(inner: ybase.base32_z_base32(), uses_padding: False)
}

/// Base36 encoding (lowercase).
pub fn base36() -> Encoding {
  Encoding(inner: ybase.base36(), uses_padding: False)
}

/// Base58 encoding (Bitcoin alphabet).
pub fn base58() -> Encoding {
  Encoding(inner: ybase.base58_bitcoin(), uses_padding: False)
}

/// Base62 encoding.
pub fn base62() -> Encoding {
  Encoding(inner: ybase.base62(), uses_padding: False)
}

/// Standard Base64 encoding.
pub fn base64() -> Encoding {
  Encoding(inner: ybase.base64_standard(), uses_padding: True)
}

/// Base64URL encoding (URL-safe).
pub fn base64_url() -> Encoding {
  Encoding(inner: ybase.base64_url_safe(), uses_padding: True)
}
