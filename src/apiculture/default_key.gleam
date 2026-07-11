//// Default structured-secret format implementation.
////
//// The v0.3.0 default is `sk_<content>_crc32_<checksum>`: 16 bytes of
//// cryptographically secure random content, Base62 encoding, an `sk` prefix,
//// `_` separators, and four CRC32 checksum bytes. The checksum detects
//// accidental corruption; it is not cryptographic authentication.

import apiculture/error.{type Error}
import apiculture/key

/// Generate a default format key.
///
/// This produces a key in the format: `sk_<base62-random>_crc32_<checksum>`.
pub fn generate() -> Result(key.Key, Error) {
  key.new_default()
}

/// Generate a default format key with the given prefix.
///
/// This produces a key in the format:
/// `<prefix>_<base62-random>_crc32_<checksum>`.
///
/// The prefix should be a short semantic identifier (e.g., "sk", "token", "key").
pub fn prefixed(prefix: String) -> Result(key.Key, Error) {
  key.new_as_config()
  |> key.with_prefix(prefix)
  |> key.generate
}
