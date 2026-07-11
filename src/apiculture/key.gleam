//// Key generation, formatting, parsing, and inspection.
////
//// This is the implementation module behind the top-level `apiculture` API.
//// It keeps generation plans (`KeyConfig`), finalized values (`Key`), and
//// parse descriptions (`KeyFormat`) as separate types so each pipeline stage
//// has an explicit meaning.

import apiculture/alphabet.{type Alphabet}
import apiculture/checksum
import apiculture/encoding.{type Encoding, decode, encode}
import apiculture/error.{type Error}
import apiculture/random
import gleam/bit_array
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// A chainable plan for generating or formatting a key.
///
/// A configuration can select secure random bytes, direct alphabet sampling, or
/// existing bytes supplied by an import function. It becomes a finalized `Key`
/// only through a terminal operation such as `generate` or `from_bytes`.
pub type KeyConfig {
  KeyConfig(
    byte_count: Option(Int),
    char_count: Option(Int),
    alphabet: Option(Alphabet),
    encoding: Option(Encoding),
    prefix: Option(String),
    separator: Option(String),
    checksum: Option(checksum.Checksum),
    checksum_name: Option(String),
    checksum_bytes: Option(Int),
  )
}

/// A finalized serialized key and its inspectable sections.
///
/// `bytes` and `content` describe the content section. Checksum fields contain
/// only the checksum that was rendered into `value`, when one is configured.
pub type Key {
  Key(
    value: String,
    bytes: BitArray,
    prefix: Option(String),
    separator: Option(String),
    content: String,
    checksum_name: Option(String),
    checksum_value: Option(String),
    checksum_bytes: Option(BitArray),
  )
}

/// The sections of a finalized key grouped for tooling and diagnostics.
pub type KeySections {
  KeySections(
    prefix: Option(String),
    separator: Option(String),
    content_value: String,
    content_bytes: BitArray,
    checksum_name: Option(String),
    checksum_value: Option(String),
    checksum_bytes: Option(BitArray),
  )
}

/// The serialized shape required by a key parser.
///
/// Unlike `KeyConfig`, this type does not describe how content was generated;
/// parsing cannot recover whether the source was random bytes, a UUID, or ULID.
pub type KeyFormat {
  KeyFormat(
    prefix: Option(String),
    separator: String,
    encoding: Encoding,
    checksum: Option(checksum.Checksum),
    checksum_name: Option(String),
    checksum_bytes: Option(Int),
    content_byte_count: Option(Int),
  )
}

/// Returns an empty configuration for building a custom key plan.
pub fn new() -> KeyConfig {
  KeyConfig(
    byte_count: None,
    char_count: None,
    alphabet: None,
    encoding: None,
    prefix: None,
    separator: None,
    checksum: None,
    checksum_name: None,
    checksum_bytes: None,
  )
}

/// Returns a ready configuration containing the v0.3.0 defaults.
pub fn new_as_config() -> KeyConfig {
  KeyConfig(
    byte_count: Some(16),
    char_count: None,
    alphabet: None,
    encoding: Some(encoding.base62()),
    prefix: Some("sk"),
    separator: Some("_"),
    checksum: Some(checksum.crc32_checksum()),
    checksum_name: Some("crc32"),
    checksum_bytes: Some(4),
  )
}

/// Generates one finalized key using the v0.3.0 defaults.
pub fn new_default() -> Result(Key, Error) {
  generate(new_as_config())
}

/// Generates and serializes one key using the v0.3.0 defaults.
pub fn new_as_string() -> Result(String, Error) {
  case new_default() {
    Ok(key) -> Ok(value(key))
    Error(error) -> Error(error)
  }
}

/// Returns the strict parser format for the v0.3.0 default layout.
pub fn default_format() -> KeyFormat {
  KeyFormat(
    prefix: Some("sk"),
    separator: "_",
    encoding: encoding.base62(),
    checksum: Some(checksum.crc32_checksum()),
    checksum_name: Some("crc32"),
    checksum_bytes: Some(4),
    content_byte_count: Some(16),
  )
}

/// Returns a parser format with the expected prefix changed.
pub fn format_with_prefix(format: KeyFormat, prefix: String) -> KeyFormat {
  KeyFormat(..format, prefix: Some(prefix))
}

/// Returns a parser format that does not expect a prefix.
pub fn format_without_prefix(format: KeyFormat) -> KeyFormat {
  KeyFormat(..format, prefix: None)
}

/// Returns a parser format with a different structural separator.
pub fn format_with_separator(
  format: KeyFormat,
  separator: String,
) -> KeyFormat {
  KeyFormat(..format, separator: separator)
}

/// Returns a parser format with a different content encoding.
pub fn format_with_encoding(
  format: KeyFormat,
  encoding: Encoding,
) -> KeyFormat {
  KeyFormat(..format, encoding: encoding)
}

/// Returns a parser format expecting the supplied checksum algorithm and name.
pub fn format_with_checksum(
  format: KeyFormat,
  checksum: checksum.Checksum,
) -> KeyFormat {
  KeyFormat(
    ..format,
    checksum: Some(checksum),
    checksum_name: Some(string.lowercase(checksum.name)),
  )
}

/// Returns a parser format that does not expect a checksum algorithm name.
pub fn format_without_checksum_name(format: KeyFormat) -> KeyFormat {
  KeyFormat(..format, checksum_name: None)
}

/// Returns a parser format that does not expect a checksum.
pub fn format_without_checksum(format: KeyFormat) -> KeyFormat {
  KeyFormat(..format, checksum: None, checksum_name: None, checksum_bytes: None)
}

/// Returns a parser format expecting the supplied checksum byte count.
pub fn format_with_checksum_bytes(format: KeyFormat, count: Int) -> KeyFormat {
  KeyFormat(..format, checksum_bytes: Some(count))
}

/// Returns a parser format expecting the supplied content byte count.
pub fn format_with_content_bytes(format: KeyFormat, count: Int) -> KeyFormat {
  KeyFormat(..format, content_byte_count: Some(count))
}

/// Selects secure random byte generation with the given byte count.
///
/// This clears direct alphabet sampling settings.
pub fn with_random_bytes(config: KeyConfig, count: Int) -> KeyConfig {
  KeyConfig(..config, byte_count: Some(count), char_count: None, alphabet: None)
}

/// Selects direct random character sampling with the given character count.
///
/// Pair this with `with_alphabet`. This clears byte encoding settings.
pub fn with_random_chars(config: KeyConfig, count: Int) -> KeyConfig {
  KeyConfig(..config, byte_count: None, char_count: Some(count), encoding: None)
}

/// Sets the alphabet used by direct character sampling.
pub fn with_alphabet(config: KeyConfig, alphabet: Alphabet) -> KeyConfig {
  KeyConfig(..config, alphabet: Some(alphabet))
}

/// Sets the encoding used for generated or imported bytes.
pub fn with_encoding(config: KeyConfig, encoding: Encoding) -> KeyConfig {
  KeyConfig(
    ..config,
    char_count: None,
    alphabet: None,
    encoding: Some(encoding),
  )
}

/// Sets the serialized prefix for a key.
pub fn with_prefix(config: KeyConfig, prefix: String) -> KeyConfig {
  KeyConfig(..config, prefix: Some(prefix))
}

/// Sets the separator used at every structural boundary.
pub fn with_separator(config: KeyConfig, separator: String) -> KeyConfig {
  KeyConfig(..config, separator: Some(separator))
}

/// Sets the checksum algorithm and its serialized lowercase name.
pub fn with_checksum(
  config: KeyConfig,
  checksum: checksum.Checksum,
) -> KeyConfig {
  KeyConfig(
    ..config,
    checksum: Some(checksum),
    checksum_name: Some(string.lowercase(checksum.name)),
  )
}

/// Sets how many checksum bytes are retained in the serialized key.
pub fn with_checksum_bytes(config: KeyConfig, count: Int) -> KeyConfig {
  KeyConfig(..config, checksum_bytes: Some(count))
}

/// Removes the checksum and its serialized name from a configuration.
pub fn without_checksum(config: KeyConfig) -> KeyConfig {
  KeyConfig(..config, checksum: None, checksum_name: None, checksum_bytes: None)
}

/// Removes the prefix from a configuration.
pub fn disable_prefix(config: KeyConfig) -> KeyConfig {
  KeyConfig(..config, prefix: None)
}

/// Removes only the checksum name while keeping the checksum enabled.
pub fn disable_checksum_name(config: KeyConfig) -> KeyConfig {
  KeyConfig(..config, checksum_name: None)
}

/// Reports whether a configuration selects one valid content source mode.
pub fn is_ready(config: KeyConfig) -> Bool {
  case config.byte_count, config.char_count, config.alphabet, config.encoding {
    None, Some(_), Some(_), None -> True
    Some(_), None, None, Some(_) -> True
    Some(_), None, None, None -> True
    _, _, _, _ -> False
  }
}

/// Finalizes a configuration by generating its selected content.
pub fn generate(config: KeyConfig) -> Result(Key, Error) {
  case is_ready(config) {
    True ->
      case
        config.byte_count,
        config.char_count,
        config.alphabet,
        config.encoding
      {
        None, Some(_), Some(_), None -> generate_from_alphabet(config)
        Some(_), None, None, Some(_) -> generate_from_encoding(config)
        Some(_), None, None, None -> generate_from_bytes(config)
        _, _, _, _ -> Error(error.InvalidByteCount)
      }

    False -> Error(error.InvalidByteCount)
  }
}

/// Formats existing bytes according to a configuration.
pub fn from_bytes(config: KeyConfig, bytes: BitArray) -> Result(Key, Error) {
  Ok(build_key(bytes, config))
}

/// Parses and formats a UUID using the default configuration.
pub fn from_uuid(input: String) -> Result(Key, Error) {
  from_uuid_with(default_import_config(), input)
}

/// Parses and formats a UUID using a supplied configuration.
pub fn from_uuid_with_config(
  config: KeyConfig,
  input: String,
) -> Result(Key, Error) {
  from_uuid_with(config, input)
}

/// Compatibility alias for `from_uuid_with_config`.
pub fn from_uuid_with(config: KeyConfig, input: String) -> Result(Key, Error) {
  case bytes_from_uuid(input) {
    Ok(bytes) -> from_bytes(config, bytes)
    Error(e) -> Error(e)
  }
}

/// Parses and formats a ULID using the default configuration.
pub fn from_ulid(input: String) -> Result(Key, Error) {
  from_ulid_with(default_import_config(), input)
}

/// Parses and formats a ULID using a supplied configuration.
pub fn from_ulid_with_config(
  config: KeyConfig,
  input: String,
) -> Result(Key, Error) {
  from_ulid_with(config, input)
}

/// Compatibility alias for `from_ulid_with_config`.
pub fn from_ulid_with(config: KeyConfig, input: String) -> Result(Key, Error) {
  case bytes_from_ulid(input) {
    Ok(bytes) -> from_bytes(config, bytes)
    Error(e) -> Error(e)
  }
}

/// Parses a UUID into canonical 16-byte content.
pub fn bytes_from_uuid(input: String) -> Result(BitArray, Error) {
  parse_uuid_bytes(input)
}

/// Parses a ULID into canonical 16-byte content.
pub fn bytes_from_ulid(input: String) -> Result(BitArray, Error) {
  parse_ulid_bytes(input)
}

/// Parses and verifies the strict default serialized key format.
pub fn parse(input: String) -> Result(Key, Error) {
  parse_with_format(input, default_format())
}

/// Parses and verifies a serialized key using an explicit format.
pub fn parse_with_format(
  input: String,
  format: KeyFormat,
) -> Result(Key, Error) {
  case parse_sections(string.split(input, on: format.separator), format) {
    Ok(#(content, checksum_value)) ->
      parse_content(content, checksum_value, format)
    Error(error) -> Error(error)
  }
}

fn parse_sections(
  sections: List(String),
  format: KeyFormat,
) -> Result(#(String, Option(String)), Error) {
  case format.prefix, format.checksum, format.checksum_name, sections {
    Some(prefix),
      Some(_),
      Some(name),
      [found_prefix, content, found_name, checksum]
    ->
      case found_prefix == prefix && found_name == name {
        True -> Ok(#(content, Some(checksum)))
        False -> Error(error.MalformedInput)
      }
    None, Some(_), Some(name), [content, found_name, checksum] ->
      case found_name == name {
        True -> Ok(#(content, Some(checksum)))
        False -> Error(error.MalformedInput)
      }
    Some(prefix), Some(_), None, [found_prefix, content, checksum] ->
      case found_prefix == prefix {
        True -> Ok(#(content, Some(checksum)))
        False -> Error(error.MalformedInput)
      }
    None, Some(_), None, [content, checksum] -> Ok(#(content, Some(checksum)))
    Some(prefix), None, _, [found_prefix, content] ->
      case found_prefix == prefix {
        True -> Ok(#(content, None))
        False -> Error(error.MalformedInput)
      }
    None, None, _, [content] -> Ok(#(content, None))
    _, _, _, _ -> Error(error.MalformedInput)
  }
}

fn parse_content(
  content: String,
  checksum_value: Option(String),
  format: KeyFormat,
) -> Result(Key, Error) {
  case decode(format.encoding, content) {
    Error(_) -> Error(error.MalformedInput)
    Ok(bytes) -> {
      case
        encode(format.encoding, bytes) == content
        && valid_content_length(bytes, format)
      {
        False -> Error(error.MalformedInput)
        True -> parse_checksum(bytes, checksum_value, format)
      }
    }
  }
}

fn valid_content_length(bytes: BitArray, format: KeyFormat) -> Bool {
  case format.content_byte_count {
    Some(count) -> bit_array.byte_size(bytes) == count
    None -> True
  }
}

fn parse_checksum(
  bytes: BitArray,
  checksum_value: Option(String),
  format: KeyFormat,
) -> Result(Key, Error) {
  case format.checksum, checksum_value {
    None, None -> Ok(build_key(bytes, config_from_format(format)))
    Some(checksum), Some(value) ->
      case decode(format.encoding, value) {
        Error(_) -> Error(error.MalformedInput)
        Ok(actual) -> {
          let expected =
            checksum.compute(bytes)
            |> truncate_checksum(format.checksum_bytes)
          case
            bit_array.byte_size(actual) == bit_array.byte_size(expected)
            && encode(format.encoding, actual) == value
          {
            False -> Error(error.MalformedInput)
            True ->
              case actual == expected {
                True -> Ok(build_key(bytes, config_from_format(format)))
                False -> Error(error.ChecksumMismatch)
              }
          }
        }
      }
    _, _ -> Error(error.MalformedInput)
  }
}

fn config_from_format(format: KeyFormat) -> KeyConfig {
  KeyConfig(
    byte_count: None,
    char_count: None,
    alphabet: None,
    encoding: Some(format.encoding),
    prefix: format.prefix,
    separator: Some(format.separator),
    checksum: format.checksum,
    checksum_name: format.checksum_name,
    checksum_bytes: format.checksum_bytes,
  )
}

fn generate_from_bytes(config: KeyConfig) -> Result(Key, Error) {
  case config.byte_count {
    Some(byte_count) -> {
      case random.random_bytes(byte_count) {
        Ok(bytes) -> Ok(build_key(bytes, config))
        Error(e) -> Error(e)
      }
    }
    None -> Error(error.InvalidByteCount)
  }
}

fn generate_from_alphabet(config: KeyConfig) -> Result(Key, Error) {
  case config.char_count, config.alphabet {
    Some(char_count), Some(alphabet) -> {
      case random.random_chars(alphabet, char_count) {
        Ok(indices) -> {
          let chars = chars_from_indices(indices, alphabet)
          let bytes = bit_array.from_string(chars)
          Ok(build_key_with_content(chars, bytes, config))
        }
        Error(e) -> Error(e)
      }
    }
    _, _ -> Error(error.InvalidByteCount)
  }
}

fn generate_from_encoding(config: KeyConfig) -> Result(Key, Error) {
  case config.byte_count, config.encoding {
    Some(byte_count), Some(encoding) -> {
      case random.random_bytes(byte_count) {
        Ok(bytes) -> {
          let encoded = encode(encoding, bytes)
          Ok(build_key_with_content(encoded, bytes, config))
        }
        Error(e) -> Error(e)
      }
    }
    _, _ -> Error(error.InvalidByteCount)
  }
}

fn encode_bytes_with_config(bytes: BitArray, config: KeyConfig) -> String {
  case config.encoding {
    Some(enc) -> encode(enc, bytes)
    None -> bytes_to_hex(bytes)
  }
}

fn build_key(bytes: BitArray, config: KeyConfig) -> Key {
  let content = encode_bytes_with_config(bytes, config)
  build_key_with_content(content, bytes, config)
}

fn build_key_with_content(
  content: String,
  bytes: BitArray,
  config: KeyConfig,
) -> Key {
  let sections = key_sections_parts(content, bytes, config)
  Key(
    value: sections.value,
    bytes: bytes,
    prefix: sections.prefix,
    separator: sections.separator,
    content: content,
    checksum_name: sections.checksum_name,
    checksum_value: sections.checksum_value,
    checksum_bytes: sections.checksum_bytes,
  )
}

type KeySectionsParts {
  KeySectionsParts(
    value: String,
    prefix: Option(String),
    separator: Option(String),
    checksum_name: Option(String),
    checksum_value: Option(String),
    checksum_bytes: Option(BitArray),
  )
}

fn key_sections_parts(
  content: String,
  bytes: BitArray,
  config: KeyConfig,
) -> KeySectionsParts {
  let prefixed = case config.prefix {
    Some(prefix) -> {
      let sep = config.separator |> option.unwrap("")
      prefix <> sep <> content
    }
    None -> content
  }

  case config.checksum {
    Some(chk) -> {
      let checksum_bytes =
        chk.compute(bytes)
        |> truncate_checksum(config.checksum_bytes)
      let checksum_value = encode_checksum(checksum_bytes, config)
      let separator = config.separator |> option.unwrap("_")
      let named_checksum = case config.checksum_name {
        Some(name) -> separator <> name <> separator <> checksum_value
        None -> separator <> checksum_value
      }
      KeySectionsParts(
        value: prefixed <> named_checksum,
        prefix: config.prefix,
        separator: config.separator,
        checksum_name: config.checksum_name,
        checksum_value: Some(checksum_value),
        checksum_bytes: Some(checksum_bytes),
      )
    }
    None ->
      KeySectionsParts(
        value: prefixed,
        prefix: config.prefix,
        separator: config.separator,
        checksum_name: None,
        checksum_value: None,
        checksum_bytes: None,
      )
  }
}

fn truncate_checksum(bytes: BitArray, byte_count: Option(Int)) -> BitArray {
  case byte_count {
    Some(count) -> drop_first_bytes(bytes, bit_array.byte_size(bytes) - count)
    None -> bytes
  }
}

fn drop_first_bytes(bytes: BitArray, n: Int) -> BitArray {
  case n {
    0 -> bytes
    _ -> {
      case bytes {
        <<_, rest:bytes>> -> drop_first_bytes(rest, n - 1)
        _ -> <<>>
      }
    }
  }
}

fn default_import_config() -> KeyConfig {
  new_as_config()
}

fn encode_checksum(crc_bytes: BitArray, config: KeyConfig) -> String {
  case config.encoding {
    Some(enc) -> encode(enc, crc_bytes)
    None -> bytes_to_hex(crc_bytes)
  }
}

fn parse_uuid_bytes(input: String) -> Result(BitArray, Error) {
  let normalized =
    input
    |> string.lowercase
    |> string.replace(each: "urn:uuid:", with: "")
    |> string.replace(each: "-", with: "")

  case string.length(normalized) == 32 {
    False -> Error(error.MalformedInput)
    True ->
      case decode(encoding.hex_lower(), normalized) {
        Ok(bytes) ->
          case bit_array.byte_size(bytes) == 16 {
            True -> Ok(bytes)
            False -> Error(error.MalformedInput)
          }
        _ -> Error(error.MalformedInput)
      }
  }
}

fn parse_ulid_bytes(input: String) -> Result(BitArray, Error) {
  let chars =
    input
    |> string.uppercase
    |> string.to_graphemes

  case list.length(chars) == 26 {
    False -> Error(error.MalformedInput)
    True ->
      case chars {
        [first, ..rest] ->
          case ulid_char_value(first) {
            Ok(value) ->
              case value <= 7 {
                True -> decode_ulid_chars(rest, value, 3, [])
                False -> Error(error.MalformedInput)
              }
            _ -> Error(error.MalformedInput)
          }

        [] -> Error(error.MalformedInput)
      }
  }
}

fn decode_ulid_chars(
  chars: List(String),
  acc: Int,
  bit_count: Int,
  out: List(Int),
) -> Result(BitArray, Error) {
  case chars {
    [] ->
      case list.length(out) == 16 && bit_count == 0 && acc == 0 {
        True -> Ok(ints_to_bytes(list.reverse(out)))
        False -> Error(error.MalformedInput)
      }

    [char, ..rest] ->
      case ulid_char_value(char) {
        Ok(value) -> {
          let next_acc = acc * 32 + value
          let next_bit_count = bit_count + 5

          case next_bit_count >= 8 {
            True -> {
              let remaining_bits = next_bit_count - 8
              let byte =
                next_acc
                |> int.bitwise_shift_right(remaining_bits)
                |> int.bitwise_and(255)
              let remaining =
                int.bitwise_and(next_acc, low_bits_mask(remaining_bits))

              decode_ulid_chars(rest, remaining, remaining_bits, [byte, ..out])
            }

            False -> decode_ulid_chars(rest, next_acc, next_bit_count, out)
          }
        }

        Error(e) -> Error(e)
      }
  }
}

fn ulid_char_value(char: String) -> Result(Int, Error) {
  case char {
    "0" | "O" -> Ok(0)
    "1" | "I" | "L" -> Ok(1)
    "2" -> Ok(2)
    "3" -> Ok(3)
    "4" -> Ok(4)
    "5" -> Ok(5)
    "6" -> Ok(6)
    "7" -> Ok(7)
    "8" -> Ok(8)
    "9" -> Ok(9)
    "A" -> Ok(10)
    "B" -> Ok(11)
    "C" -> Ok(12)
    "D" -> Ok(13)
    "E" -> Ok(14)
    "F" -> Ok(15)
    "G" -> Ok(16)
    "H" -> Ok(17)
    "J" -> Ok(18)
    "K" -> Ok(19)
    "M" -> Ok(20)
    "N" -> Ok(21)
    "P" -> Ok(22)
    "Q" -> Ok(23)
    "R" -> Ok(24)
    "S" -> Ok(25)
    "T" -> Ok(26)
    "V" -> Ok(27)
    "W" -> Ok(28)
    "X" -> Ok(29)
    "Y" -> Ok(30)
    "Z" -> Ok(31)
    _ -> Error(error.MalformedInput)
  }
}

fn low_bits_mask(bit_count: Int) -> Int {
  case bit_count {
    0 -> 0
    _ -> int.bitwise_shift_left(1, bit_count) - 1
  }
}

fn ints_to_bytes(ints: List(Int)) -> BitArray {
  case ints {
    [] -> <<>>
    [first, ..rest] -> bit_array.append(<<first>>, ints_to_bytes(rest))
  }
}

fn chars_from_indices(indices: List(Int), alphabet: Alphabet) -> String {
  let char_list = alphabet.characters(alphabet)
  indices
  |> list.map(fn(index) {
    case index >= 0 && index < list.length(char_list) {
      True -> get_nth(index, char_list)
      False -> ""
    }
  })
  |> string.concat
}

fn get_nth(n: Int, items: List(String)) -> String {
  case n, items {
    0, [first, ..] -> first
    _, [_first, ..rest] -> get_nth(n - 1, rest)
    _, [] -> ""
  }
}

fn bytes_to_hex(bytes: BitArray) -> String {
  bytes
  |> do_bytes_to_hex([])
  |> list.reverse
  |> string.concat
}

fn do_bytes_to_hex(bytes: BitArray, acc: List(String)) -> List(String) {
  case bytes {
    <<>> -> acc
    <<byte, rest:bits>> -> {
      let hex = int_to_hex(byte)
      do_bytes_to_hex(rest, [hex, ..acc])
    }
    _ -> acc
  }
}

fn int_to_hex(byte: Int) -> String {
  let nibble_high = byte / 16
  let nibble_low = byte % 16
  hex_digit(nibble_high) <> hex_digit(nibble_low)
}

fn hex_digit(nibble: Int) -> String {
  case nibble {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    10 -> "a"
    11 -> "b"
    12 -> "c"
    13 -> "d"
    14 -> "e"
    15 -> "f"
    _ -> ""
  }
}

/// Returns the string value of the key.
pub fn value(key: Key) -> String {
  key.value
}

/// Returns the raw bytes that were used to generate the key.
/// Returns the raw content bytes of a finalized key.
pub fn bytes(key: Key) -> BitArray {
  key.bytes
}

/// Returns the optional serialized prefix.
pub fn prefix_value(key: Key) -> Option(String) {
  key.prefix
}

/// Returns the optional structural separator.
pub fn separator_value(key: Key) -> Option(String) {
  key.separator
}

/// Reports whether a key has a prefix.
pub fn has_prefix(key: Key) -> Bool {
  option.is_some(key.prefix)
}

/// Reports whether a key has a checksum.
pub fn has_checksum(key: Key) -> Bool {
  option.is_some(key.checksum_bytes)
}

/// Returns the encoded content section without surrounding metadata.
pub fn content_value(key: Key) -> String {
  key.content
}

/// Returns the raw bytes represented by the content section.
pub fn content_bytes(key: Key) -> BitArray {
  key.bytes
}

/// Returns the number of raw content bytes.
pub fn content_byte_count(key: Key) -> Int {
  bit_array.byte_size(key.bytes)
}

/// Returns the number of characters in the encoded content section.
pub fn content_char_count(key: Key) -> Int {
  string.length(key.content)
}

/// Returns the optional checksum algorithm name.
pub fn checksum_name(key: Key) -> Option(String) {
  key.checksum_name
}

/// Returns the optional encoded checksum section.
pub fn checksum_value(key: Key) -> Option(String) {
  key.checksum_value
}

/// Returns the optional raw checksum bytes.
pub fn checksum_bytes(key: Key) -> Option(BitArray) {
  key.checksum_bytes
}

/// Returns the checksum byte count, or `0` when absent.
pub fn checksum_byte_count(key: Key) -> Int {
  case key.checksum_bytes {
    Some(bytes) -> bit_array.byte_size(bytes)
    None -> 0
  }
}

/// Returns the encoded checksum character count, when present.
pub fn checksum_char_count(key: Key) -> Option(Int) {
  case key.checksum_value {
    Some(value) -> Some(string.length(value))
    None -> None
  }
}

/// Returns all key sections grouped in one value.
pub fn sections(key: Key) -> KeySections {
  KeySections(
    prefix: key.prefix,
    separator: key.separator,
    content_value: key.content,
    content_bytes: key.bytes,
    checksum_name: key.checksum_name,
    checksum_value: key.checksum_value,
    checksum_bytes: key.checksum_bytes,
  )
}

/// Verifies the stored checksum with an explicit algorithm.
pub fn verify_checksum(key: Key, checksum: checksum.Checksum) -> Bool {
  case key.checksum_bytes {
    Some(expected) ->
      checksum.compute(key.bytes)
      |> truncate_checksum(Some(bit_array.byte_size(expected)))
      == expected

    None -> False
  }
}

/// Verifies the stored checksum using CRC32.
pub fn verify_default_checksum(key: Key) -> Bool {
  verify_checksum(key, checksum.crc32_checksum())
}
