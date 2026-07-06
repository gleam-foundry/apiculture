// Default structured-secret format implementation
//
// This module provides the default key generation format inspired by
// modern scanner-friendly credential design.
//
// Default format: `<prefix>_<base62-random><checksum>`
//
// Properties:
// - High entropy: 16 bytes (128 bits) of cryptographically secure random
// - Recognizable prefix: user-defined semantic prefix
// - Fixed structure: prefix + underscore + random + checksum
// - Scanner-friendly: no special characters beyond underscore
// - Offline verification: CRC32 checksum enables integrity verification
//
// This format is inspired by the engineering properties of modern token
// formats like GitHub's authentication tokens, but does not claim wire
// compatibility and uses different prefixes and encoding details.

import apiculture/checksum
import apiculture/encoding
import apiculture/error.{type Error}
import apiculture/key

/// Default number of random bytes for structured secrets (128 bits).
const default_key_bytes: Int = 16

/// Number of bytes in a CRC32 checksum.
const checksum_bytes: Int = 4

/// Generate a default format key without a prefix.
///
/// This produces a key in the format: `<base62-random><checksum>`
pub fn generate() -> Result(key.Key, Error) {
  key.new()
  |> key.with_random_bytes(default_key_bytes)
  |> key.with_encoding(encoding.base62())
  |> key.with_checksum(checksum.crc32_checksum())
  |> key.with_checksum_bytes(checksum_bytes)
  |> key.generate
}

/// Generate a default format key with the given prefix.
///
/// This produces a key in the format: `<prefix>_<base62-random><checksum>`
///
/// The prefix should be a short semantic identifier (e.g., "sk", "token", "key").
pub fn prefixed(prefix: String) -> Result(key.Key, Error) {
  key.new()
  |> key.with_random_bytes(default_key_bytes)
  |> key.with_encoding(encoding.base62())
  |> key.with_prefix(prefix)
  |> key.with_separator("_")
  |> key.with_checksum(checksum.crc32_checksum())
  |> key.with_checksum_bytes(checksum_bytes)
  |> key.generate
}
