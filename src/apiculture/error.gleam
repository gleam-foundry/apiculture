//// Error types for apiculture operations.
////
//// These errors indicate failure conditions when generating keys,
//// creating alphabets, or encoding/decoding data.

/// Errors returned by apiculture operations.
pub type Error {
  /// The alphabet is empty.
  EmptyAlphabet

  /// The alphabet has only one character.
  SingleCharacterAlphabet

  /// The alphabet contains duplicate characters.
  DuplicateCharacters

  /// Secure randomness is not available on this platform.
  SecureRandomUnavailable

  /// The requested byte count is invalid (e.g., negative or zero).
  InvalidByteCount

  /// The encoding is invalid.
  InvalidEncoding

  /// The encoded input is malformed.
  MalformedInput

  /// The checksum does not match.
  ChecksumMismatch
}
