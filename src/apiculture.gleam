//// Apiculture - cryptographically secure API-key generation for Gleam.
////
//// The top-level module provides the v0.3.0 API for generating, importing,
//// parsing, inspecting, and verifying structured API keys. Start here for
//// ordinary application use; the lower-level modules are available when a
//// more specialized encoding, alphabet, or checksum workflow is needed.

import apiculture/alphabet
import apiculture/checksum
import apiculture/default_key
import apiculture/encoding
import apiculture/error
import apiculture/key
import gleam/option.{type Option}

// ============================================================================
// Re-exports: Types
// ============================================================================

/// A validated character repertoire for direct random character sampling.
pub type Alphabet =
  alphabet.Alphabet

/// Errors returned by key generation, parsing, encoding, and validation.
pub type Error =
  error.Error

/// A finalized API key, including its serialized value and inspectable sections.
pub type Key =
  key.Key

/// The prefix, content, and checksum sections of a finalized key.
pub type KeySections =
  key.KeySections

/// A chainable plan for generating or formatting a key.
///
/// A `KeyConfig` is not a key. Finish it with `key_generate`, `key_from_bytes`,
/// or one of the configured UUID/ULID import functions.
pub type KeyConfig =
  key.KeyConfig

/// The parse-relevant shape of a serialized key.
///
/// Use `KeyFormat` with `key_parse_with_format`; generation intent is kept in
/// `KeyConfig` because it cannot be recovered from a serialized value.
pub type KeyFormat =
  key.KeyFormat

/// A byte-to-text encoding used for key content and checksum sections.
pub type Encoding =
  encoding.Encoding

/// A checksum algorithm used to validate key content.
pub type Checksum =
  checksum.Checksum

// ============================================================================
// Re-exports: Error constructors
// ============================================================================

/// Returns the error for an empty custom alphabet.
pub fn empty_alphabet_error() -> error.Error {
  error.EmptyAlphabet
}

/// Returns the error for a one-character custom alphabet.
pub fn single_character_alphabet_error() -> error.Error {
  error.SingleCharacterAlphabet
}

/// Returns the error for a custom alphabet containing duplicate characters.
pub fn duplicate_characters_error() -> error.Error {
  error.DuplicateCharacters
}

/// Returns the error raised when secure randomness is unavailable.
pub fn secure_random_unavailable_error() -> error.Error {
  error.SecureRandomUnavailable
}

/// Returns the error for an invalid or incomplete byte/character count.
pub fn invalid_byte_count_error() -> error.Error {
  error.InvalidByteCount
}

/// Returns the error for an invalid encoding configuration.
pub fn invalid_encoding_error() -> error.Error {
  error.InvalidEncoding
}

/// Returns the error for malformed encoded, UUID, ULID, or serialized input.
pub fn malformed_input_error() -> error.Error {
  error.MalformedInput
}

/// Returns the error for a checksum that does not match its content.
pub fn checksum_mismatch_error() -> error.Error {
  error.ChecksumMismatch
}

// ============================================================================
// Alphabet functions
// ============================================================================

/// Creates a validated custom alphabet for direct character sampling.
///
/// The alphabet must contain at least two unique graphemes.
pub fn new_alphabet(chars: String) -> Result(Alphabet, error.Error) {
  alphabet.new_alphabet(chars)
}

/// Returns the graphemes in a validated alphabet.
pub fn alphabet_characters(alphabet: Alphabet) -> List(String) {
  alphabet.characters(alphabet)
}

/// Returns the number of graphemes in an alphabet.
pub fn alphabet_size(alphabet: Alphabet) -> Int {
  alphabet.size(alphabet)
}

// ============================================================================
// Key functions
// ============================================================================

/// Generates one key using the v0.3.0 default format.
///
/// The default is `sk_<content>_crc32_<checksum>` with 16 random bytes encoded
/// as Base62 and a four-byte CRC32 checksum.
pub fn key_new() -> Result(Key, error.Error) {
  key.new_default()
}

/// Generates and serializes one key using the v0.3.0 default format.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(value) = key_new_as_string()
/// ```
pub fn key_new_as_string() -> Result(String, error.Error) {
  key.new_as_string()
}

/// Returns a ready-to-generate configuration containing the default settings.
///
/// Use the `key_with_*` and `key_disable_*` functions to customize it.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(key) =
///   key_new_as_config()
///   |> key_with_prefix("partner")
///   |> key_generate
/// ```
pub fn key_new_as_config() -> KeyConfig {
  key.new_as_config()
}

/// Finalizes a random-generation configuration as a `Key`.
///
/// This is a terminal operation. It generates fresh content according to the
/// selected mode and retains the rendered sections for later inspection.
pub fn key_generate(config: KeyConfig) -> Result(Key, error.Error) {
  key.generate(config)
}

/// Reports whether a configuration contains one valid content-generation mode.
pub fn key_config_is_ready(config: KeyConfig) -> Bool {
  key.is_ready(config)
}

/// Formats existing bytes using a key configuration.
///
/// This is the terminal step for parse-then-format UUID and ULID workflows.
pub fn key_from_bytes(
  config: KeyConfig,
  bytes: BitArray,
) -> Result(Key, error.Error) {
  key.from_bytes(config, bytes)
}

/// Parses a UUID into its canonical 16 bytes.
pub fn bytes_from_uuid(input: String) -> Result(BitArray, error.Error) {
  key.bytes_from_uuid(input)
}

/// Parses a ULID into its canonical 16 bytes.
pub fn bytes_from_ulid(input: String) -> Result(BitArray, error.Error) {
  key.bytes_from_ulid(input)
}

/// Imports a UUID using the v0.3.0 default key format.
///
/// This is a terminal operation. Use `bytes_from_uuid` followed by
/// `key_from_bytes` when the formatting pipeline needs to remain explicit.
pub fn key_from_uuid(input: String) -> Result(Key, error.Error) {
  key.from_uuid(input)
}

/// Imports a UUID and formats it with a supplied configuration.
pub fn key_from_uuid_with_config(
  config: KeyConfig,
  input: String,
) -> Result(Key, error.Error) {
  key.from_uuid_with_config(config, input)
}

/// Imports a ULID using the v0.3.0 default key format.
pub fn key_from_ulid(input: String) -> Result(Key, error.Error) {
  key.from_ulid(input)
}

/// Imports a ULID and formats it with a supplied configuration.
pub fn key_from_ulid_with_config(
  config: KeyConfig,
  input: String,
) -> Result(Key, error.Error) {
  key.from_ulid_with_config(config, input)
}

/// Parses and verifies a key in the strict default serialized format.
///
/// A successful result has canonical Base62 content, the expected `sk` prefix,
/// 16 content bytes, and a matching four-byte CRC32 checksum.
pub fn key_parse(input: String) -> Result(Key, error.Error) {
  key.parse(input)
}

/// Returns the parse format corresponding to the v0.3.0 default.
pub fn key_default_format() -> KeyFormat {
  key.default_format()
}

/// Parses and verifies a key using an explicitly supplied format.
pub fn key_parse_with_format(
  input: String,
  format: KeyFormat,
) -> Result(Key, error.Error) {
  key.parse_with_format(input, format)
}

/// Returns the serialized value of a finalized key.
///
/// Prefer `key_to_string` in pipelines; this name remains for compatibility.
pub fn key_value(k: Key) -> String {
  key.value(k)
}

/// Returns the serialized value of a finalized key.
pub fn key_to_string(k: Key) -> String {
  key.value(k)
}

/// Returns the raw content bytes of a finalized key.
///
/// This is a compatibility alias for `key_content_bytes`.
pub fn key_bytes(k: Key) -> BitArray {
  key.bytes(k)
}

/// Returns the optional serialized prefix.
pub fn key_prefix_value(k: Key) -> Option(String) {
  key.prefix_value(k)
}

/// Returns the optional structural separator.
pub fn key_separator_value(k: Key) -> Option(String) {
  key.separator_value(k)
}

/// Reports whether the key has a prefix.
pub fn key_has_prefix(k: Key) -> Bool {
  key.has_prefix(k)
}

/// Reports whether the key has a checksum.
pub fn key_has_checksum(k: Key) -> Bool {
  key.has_checksum(k)
}

/// Returns the encoded content section without prefix or checksum sections.
pub fn key_content_value(k: Key) -> String {
  key.content_value(k)
}

/// Returns the raw bytes represented by the content section.
pub fn key_content_bytes(k: Key) -> BitArray {
  key.content_bytes(k)
}

/// Returns the number of raw content bytes.
pub fn key_content_byte_count(k: Key) -> Int {
  key.content_byte_count(k)
}

/// Returns the number of characters in the encoded content section.
pub fn key_content_char_count(k: Key) -> Int {
  key.content_char_count(k)
}

/// Returns the optional lowercase checksum algorithm name.
pub fn key_checksum_name(k: Key) -> Option(String) {
  key.checksum_name(k)
}

/// Returns the optional encoded checksum section.
pub fn key_checksum_value(k: Key) -> Option(String) {
  key.checksum_value(k)
}

/// Returns the optional raw checksum bytes.
pub fn key_checksum_bytes(k: Key) -> Option(BitArray) {
  key.checksum_bytes(k)
}

/// Returns the checksum byte count, or `0` when no checksum is present.
pub fn key_checksum_byte_count(k: Key) -> Int {
  key.checksum_byte_count(k)
}

/// Returns the encoded checksum character count, when present.
pub fn key_checksum_char_count(k: Key) -> Option(Int) {
  key.checksum_char_count(k)
}

/// Verifies a key with the default CRC32 algorithm.
pub fn key_verify_checksum(k: Key) -> Bool {
  key.verify_default_checksum(k)
}

/// Verifies a key with an explicitly supplied checksum algorithm.
pub fn key_verify_checksum_with_algo(k: Key, csum: Checksum) -> Bool {
  key.verify_checksum(k, csum)
}

/// Returns all serialized and raw key sections as one value.
pub fn key_sections(k: Key) -> key.KeySections {
  key.sections(k)
}

// Builder functions
/// Selects secure random byte generation with the given byte count.
pub fn key_with_random_bytes(config: KeyConfig, count: Int) -> KeyConfig {
  key.with_random_bytes(config, count)
}

/// Selects direct alphabet sampling with the given character count.
///
/// Pair this with `key_with_alphabet`; it is distinct from generating random
/// bytes and then encoding them.
pub fn key_with_random_chars(config: KeyConfig, count: Int) -> KeyConfig {
  key.with_random_chars(config, count)
}

/// Sets the alphabet used by direct character sampling.
pub fn key_with_alphabet(config: KeyConfig, alphabet: Alphabet) -> KeyConfig {
  key.with_alphabet(config, alphabet)
}

/// Sets the encoding used for content and checksum sections.
pub fn key_with_encoding(config: KeyConfig, encoding: Encoding) -> KeyConfig {
  key.with_encoding(config, encoding)
}

/// Sets the serialized key prefix.
pub fn key_with_prefix(config: KeyConfig, prefix: String) -> KeyConfig {
  key.with_prefix(config, prefix)
}

/// Sets the separator used at every structural boundary.
pub fn key_with_separator(config: KeyConfig, separator: String) -> KeyConfig {
  key.with_separator(config, separator)
}

/// Sets the checksum algorithm and serialized algorithm name.
pub fn key_with_checksum(config: KeyConfig, checksum: Checksum) -> KeyConfig {
  key.with_checksum(config, checksum)
}

/// Sets the number of checksum bytes retained in the key.
pub fn key_with_checksum_bytes(config: KeyConfig, count: Int) -> KeyConfig {
  key.with_checksum_bytes(config, count)
}

/// Removes the prefix from a key configuration.
pub fn key_disable_prefix(config: KeyConfig) -> KeyConfig {
  key.disable_prefix(config)
}

/// Removes the checksum name while retaining the checksum.
pub fn key_disable_checksum_name(config: KeyConfig) -> KeyConfig {
  key.disable_checksum_name(config)
}

/// Removes both the checksum and its serialized name.
pub fn key_disable_checksum(config: KeyConfig) -> KeyConfig {
  key.without_checksum(config)
}

/// Changes the expected prefix in a parser format.
pub fn key_format_with_prefix(format: KeyFormat, prefix: String) -> KeyFormat {
  key.format_with_prefix(format, prefix)
}

/// Removes the expected prefix from a parser format.
pub fn key_format_without_prefix(format: KeyFormat) -> KeyFormat {
  key.format_without_prefix(format)
}

/// Changes the expected separator in a parser format.
pub fn key_format_with_separator(
  format: KeyFormat,
  separator: String,
) -> KeyFormat {
  key.format_with_separator(format, separator)
}

/// Changes the expected encoding in a parser format.
pub fn key_format_with_encoding(
  format: KeyFormat,
  encoding: Encoding,
) -> KeyFormat {
  key.format_with_encoding(format, encoding)
}

/// Changes the expected checksum algorithm in a parser format.
pub fn key_format_with_checksum(
  format: KeyFormat,
  checksum: Checksum,
) -> KeyFormat {
  key.format_with_checksum(format, checksum)
}

/// Removes the expected checksum name from a parser format.
pub fn key_format_without_checksum_name(format: KeyFormat) -> KeyFormat {
  key.format_without_checksum_name(format)
}

/// Removes the expected checksum from a parser format.
pub fn key_format_without_checksum(format: KeyFormat) -> KeyFormat {
  key.format_without_checksum(format)
}

/// Changes the expected checksum byte count in a parser format.
pub fn key_format_with_checksum_bytes(
  format: KeyFormat,
  count: Int,
) -> KeyFormat {
  key.format_with_checksum_bytes(format, count)
}

/// Changes the expected content byte count in a parser format.
pub fn key_format_with_content_bytes(
  format: KeyFormat,
  count: Int,
) -> KeyFormat {
  key.format_with_content_bytes(format, count)
}

// ============================================================================
// Encoding functions
// ============================================================================

/// Encodes bytes with an apiculture encoding.
pub fn encoding_encode(enc: Encoding, bytes: BitArray) -> String {
  encoding.encode(enc, bytes)
}

/// Decodes a string with an apiculture encoding.
pub fn encoding_decode(
  enc: Encoding,
  input: String,
) -> Result(BitArray, error.Error) {
  encoding.decode(enc, input)
}

/// Reports whether an encoding uses padding.
pub fn encoding_uses_padding(enc: Encoding) -> Bool {
  encoding.uses_padding(enc)
}

/// Returns the multibase name of an encoding.
pub fn encoding_name(enc: Encoding) -> String {
  encoding.name(enc)
}

// Hex encodings
/// Returns lowercase hexadecimal encoding.
pub fn hex_lower() -> Encoding {
  encoding.hex_lower()
}

/// Returns uppercase hexadecimal encoding.
pub fn hex_upper() -> Encoding {
  encoding.hex_upper()
}

// Base32 encodings
/// Returns padded RFC 4648 Base32 encoding.
pub fn base32_rfc() -> Encoding {
  encoding.base32_rfc()
}

/// Returns unpadded RFC 4648 Base32 encoding.
pub fn base32_rfc_unpadded() -> Encoding {
  encoding.base32_rfc_unpadded()
}

/// Returns Base32hex encoding.
pub fn base32_hex() -> Encoding {
  encoding.base32_hex()
}

/// Returns Crockford Base32 encoding.
pub fn base32_crockford() -> Encoding {
  encoding.base32_crockford()
}

/// Returns z-base-32 encoding.
pub fn base32_z() -> Encoding {
  encoding.base32_z()
}

// Base36 encoding
/// Returns lowercase Base36 encoding.
pub fn base36() -> Encoding {
  encoding.base36()
}

// Base58 encoding
/// Returns Bitcoin-style Base58 encoding.
pub fn base58() -> Encoding {
  encoding.base58()
}

// Base62 encoding
/// Returns Base62 encoding.
pub fn base62() -> Encoding {
  encoding.base62()
}

// Base64 encodings
/// Returns standard padded Base64 encoding.
pub fn base64() -> Encoding {
  encoding.base64()
}

/// Returns URL-safe padded Base64 encoding.
pub fn base64_url() -> Encoding {
  encoding.base64_url()
}

// ============================================================================
// Checksum functions
// ============================================================================

/// Formats a checksum using a caller-provided byte encoding function.
pub fn checksum_format(
  csum: Checksum,
  bytes: BitArray,
  format_with: fn(BitArray) -> String,
) -> String {
  checksum.format(csum, bytes, format_with)
}

/// Verifies raw bytes against an expected checksum.
pub fn checksum_verify(
  csum: Checksum,
  bytes: BitArray,
  expected: BitArray,
) -> Bool {
  checksum.verify(csum, bytes, expected)
}

/// Returns the CRC32 checksum algorithm used by the default key format.
pub fn crc32() -> Checksum {
  checksum.crc32_checksum()
}

// ============================================================================
// Default key functions
// ============================================================================

/// Compatibility alias for generating a v0.3.0 default key.
///
/// Prefer `key_new()` in new code. This function returns the same structured
/// `sk_<content>_crc32_<checksum>` format.
pub fn default_generate() -> Result(Key, error.Error) {
  default_key.generate()
}

/// Generates a v0.3.0 structured key with a custom prefix.
///
/// The format is `<prefix>_<content>_crc32_<checksum>`.
///
/// The prefix should be a short semantic identifier (e.g., "sk", "token", "key").
pub fn default_prefixed(prefix: String) -> Result(Key, error.Error) {
  default_key.prefixed(prefix)
}
