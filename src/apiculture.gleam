// Apiculture - Cryptographically secure random key generation for Gleam
//
// This library provides tools for generating cryptographically secure
// random keys and tokens with support for various encodings and checksums.

import apiculture/alphabet
import apiculture/checksum
import apiculture/default_key
import apiculture/encoding
import apiculture/error
import apiculture/key

// ============================================================================
// Re-exports: Types
// ============================================================================

pub type Alphabet =
  alphabet.Alphabet

pub type Error =
  error.Error

pub type Key =
  key.Key

pub type KeyConfig =
  key.KeyConfig

pub type Encoding =
  encoding.Encoding

pub type Checksum =
  checksum.Checksum

// ============================================================================
// Re-exports: Error constructors
// ============================================================================

pub fn empty_alphabet_error() -> error.Error {
  error.EmptyAlphabet
}

pub fn single_character_alphabet_error() -> error.Error {
  error.SingleCharacterAlphabet
}

pub fn duplicate_characters_error() -> error.Error {
  error.DuplicateCharacters
}

pub fn secure_random_unavailable_error() -> error.Error {
  error.SecureRandomUnavailable
}

pub fn invalid_byte_count_error() -> error.Error {
  error.InvalidByteCount
}

pub fn invalid_encoding_error() -> error.Error {
  error.InvalidEncoding
}

pub fn malformed_input_error() -> error.Error {
  error.MalformedInput
}

pub fn checksum_mismatch_error() -> error.Error {
  error.ChecksumMismatch
}

// ============================================================================
// Alphabet functions
// ============================================================================

pub fn new_alphabet(chars: String) -> Result(Alphabet, error.Error) {
  alphabet.new_alphabet(chars)
}

pub fn alphabet_characters(alphabet: Alphabet) -> List(String) {
  alphabet.characters(alphabet)
}

pub fn alphabet_size(alphabet: Alphabet) -> Int {
  alphabet.size(alphabet)
}

// ============================================================================
// Key functions
// ============================================================================

pub fn key_new() -> KeyConfig {
  key.new()
}

pub fn key_generate(config: KeyConfig) -> Result(Key, error.Error) {
  key.generate(config)
}

pub fn key_from_bytes(
  config: KeyConfig,
  bytes: BitArray,
) -> Result(Key, error.Error) {
  key.from_bytes(config, bytes)
}

pub fn key_from_uuid(input: String) -> Result(Key, error.Error) {
  key.from_uuid(input)
}

pub fn key_from_uuid_with(
  config: KeyConfig,
  input: String,
) -> Result(Key, error.Error) {
  key.from_uuid_with(config, input)
}

pub fn key_from_ulid(input: String) -> Result(Key, error.Error) {
  key.from_ulid(input)
}

pub fn key_from_ulid_with(
  config: KeyConfig,
  input: String,
) -> Result(Key, error.Error) {
  key.from_ulid_with(config, input)
}

pub fn key_value(k: Key) -> String {
  key.value(k)
}

pub fn key_bytes(k: Key) -> BitArray {
  key.bytes(k)
}

// Builder functions
pub fn key_with_random_bytes(config: KeyConfig, count: Int) -> KeyConfig {
  key.with_random_bytes(config, count)
}

pub fn key_with_random_chars(config: KeyConfig, count: Int) -> KeyConfig {
  key.with_random_chars(config, count)
}

pub fn key_with_alphabet(config: KeyConfig, alphabet: Alphabet) -> KeyConfig {
  key.with_alphabet(config, alphabet)
}

pub fn key_with_encoding(config: KeyConfig, encoding: Encoding) -> KeyConfig {
  key.with_encoding(config, encoding)
}

pub fn key_with_prefix(config: KeyConfig, prefix: String) -> KeyConfig {
  key.with_prefix(config, prefix)
}

pub fn key_with_separator(config: KeyConfig, separator: String) -> KeyConfig {
  key.with_separator(config, separator)
}

pub fn key_with_checksum(config: KeyConfig, checksum: Checksum) -> KeyConfig {
  key.with_checksum(config, checksum)
}

pub fn key_without_checksum(config: KeyConfig) -> KeyConfig {
  key.without_checksum(config)
}

// ============================================================================
// Encoding functions
// ============================================================================

pub fn encoding_encode(enc: Encoding, bytes: BitArray) -> String {
  encoding.encode(enc, bytes)
}

pub fn encoding_decode(
  enc: Encoding,
  input: String,
) -> Result(BitArray, error.Error) {
  encoding.decode(enc, input)
}

pub fn encoding_uses_padding(enc: Encoding) -> Bool {
  encoding.uses_padding(enc)
}

pub fn encoding_name(enc: Encoding) -> String {
  encoding.name(enc)
}

// Hex encodings
pub fn hex_lower() -> Encoding {
  encoding.hex_lower()
}

pub fn hex_upper() -> Encoding {
  encoding.hex_upper()
}

// Base32 encodings
pub fn base32_rfc() -> Encoding {
  encoding.base32_rfc()
}

pub fn base32_rfc_unpadded() -> Encoding {
  encoding.base32_rfc_unpadded()
}

pub fn base32_hex() -> Encoding {
  encoding.base32_hex()
}

pub fn base32_crockford() -> Encoding {
  encoding.base32_crockford()
}

pub fn base32_z() -> Encoding {
  encoding.base32_z()
}

// Base36 encoding
pub fn base36() -> Encoding {
  encoding.base36()
}

// Base58 encoding
pub fn base58() -> Encoding {
  encoding.base58()
}

// Base62 encoding
pub fn base62() -> Encoding {
  encoding.base62()
}

// Base64 encodings
pub fn base64() -> Encoding {
  encoding.base64()
}

pub fn base64_url() -> Encoding {
  encoding.base64_url()
}

// ============================================================================
// Checksum functions
// ============================================================================

pub fn checksum_format(
  csum: Checksum,
  bytes: BitArray,
  format_with: fn(BitArray) -> String,
) -> String {
  checksum.format(csum, bytes, format_with)
}

pub fn checksum_verify(
  csum: Checksum,
  bytes: BitArray,
  expected: BitArray,
) -> Bool {
  checksum.verify(csum, bytes, expected)
}

pub fn crc32() -> Checksum {
  checksum.crc32_checksum()
}

// ============================================================================
// Default key functions
// ============================================================================

/// Generate a default format key without a prefix.
///
/// This produces a key in the format: `<base62-random><checksum>`
pub fn default_generate() -> Result(Key, error.Error) {
  default_key.generate()
}

/// Generate a default format key with the given prefix.
///
/// This produces a key in the format: `<prefix>_<base62-random><checksum>`
///
/// The prefix should be a short semantic identifier (e.g., "sk", "token", "key").
pub fn default_prefixed(prefix: String) -> Result(Key, error.Error) {
  default_key.prefixed(prefix)
}
