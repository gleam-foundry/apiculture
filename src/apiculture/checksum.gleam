//// CRC32 checksum implementation for data integrity verification.
////
//// This module is a thin wrapper around the `crc32` package that adapts
//// its `Int` return type to the `BitArray` expected by apiculture's key API.
////
//// **This is NOT cryptographic authentication** - CRC32 is designed to
//// detect accidental data corruption only, not malicious tampering.
////
//// For authenticated checksums suitable for security-sensitive applications,
//// consider using HMAC-based approaches with a cryptographic hash.

import crc32
import gleam/int

/// A checksum algorithm that can produce output in various formats.
pub type Checksum {
  Checksum(
    /// Compute the raw checksum bytes (4 bytes for CRC32)
    compute: fn(BitArray) -> BitArray,
    /// Human-readable name
    name: String,
  )
}

/// Compute a CRC32 checksum of the given bytes.
/// Returns a 4-byte BitArray for compatibility with the Checksum API.
fn crc32_bytes(bytes: BitArray) -> BitArray {
  let checksum_int = crc32.checksum(bytes)
  int_to_4bytes(checksum_int)
}

/// Convert a 32-bit integer to a 4-byte BitArray (little-endian).
fn int_to_4bytes(n: Int) -> BitArray {
  let b0 = int.bitwise_and(n, 255)
  let b1 = int.bitwise_and(int.bitwise_shift_right(n, 8), 255)
  let b2 = int.bitwise_and(int.bitwise_shift_right(n, 16), 255)
  let b3 = int.bitwise_and(int.bitwise_shift_right(n, 24), 255)
  <<b0, b1, b2, b3>>
}

/// CRC32 checksum algorithm using CRC-32/ISO-HDLC variant.
/// This matches the standard CRC-32 used by ZIP, gzip, PNG, and Ethernet.
pub fn crc32_checksum() -> Checksum {
  Checksum(compute: crc32_bytes, name: "CRC32")
}

/// Compute a CRC32 checksum and return it as a 4-byte BitArray.
/// This is a convenience function for direct checksum computation.
pub fn crc32(bytes: BitArray) -> BitArray {
  crc32_bytes(bytes)
}

/// Format the checksum output through an encoding or alphabet.
pub fn format(
  checksum: Checksum,
  bytes: BitArray,
  format_with: fn(BitArray) -> String,
) -> String {
  format_with(checksum.compute(bytes))
}

/// Verify that data matches an expected checksum.
pub fn verify(checksum: Checksum, bytes: BitArray, expected: BitArray) -> Bool {
  checksum.compute(bytes) == expected
}
