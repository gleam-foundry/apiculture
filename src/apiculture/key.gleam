// Key generation with pipeline API
//
// This module provides flexible key generation with support for:
// - Custom encodings and alphabets
// - Optional prefixes and separators
// - Optional checksums for integrity verification

import apiculture/alphabet.{type Alphabet}
import apiculture/checksum.{type Checksum}
import apiculture/encoding.{type Encoding, decode, encode}
import apiculture/error.{type Error}
import apiculture/random
import gleam/bit_array
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type KeyConfig {
  KeyConfig(
    byte_count: Option(Int),
    char_count: Option(Int),
    alphabet: Option(Alphabet),
    encoding: Option(Encoding),
    prefix: Option(String),
    separator: Option(String),
    checksum: Option(Checksum),
    checksum_bytes: Option(Int),
  )
}

pub type Key {
  Key(value: String, bytes: BitArray)
}

pub fn new() -> KeyConfig {
  KeyConfig(
    byte_count: None,
    char_count: None,
    alphabet: None,
    encoding: None,
    prefix: None,
    separator: None,
    checksum: None,
    checksum_bytes: None,
  )
}

pub fn with_random_bytes(config: KeyConfig, count: Int) -> KeyConfig {
  KeyConfig(..config, byte_count: Some(count))
}

pub fn with_random_chars(config: KeyConfig, count: Int) -> KeyConfig {
  KeyConfig(..config, char_count: Some(count))
}

pub fn with_alphabet(config: KeyConfig, alphabet: Alphabet) -> KeyConfig {
  KeyConfig(..config, alphabet: Some(alphabet))
}

pub fn with_encoding(config: KeyConfig, encoding: Encoding) -> KeyConfig {
  KeyConfig(..config, encoding: Some(encoding))
}

pub fn with_prefix(config: KeyConfig, prefix: String) -> KeyConfig {
  KeyConfig(..config, prefix: Some(prefix))
}

pub fn with_separator(config: KeyConfig, separator: String) -> KeyConfig {
  KeyConfig(..config, separator: Some(separator))
}

pub fn with_checksum(config: KeyConfig, checksum: Checksum) -> KeyConfig {
  KeyConfig(..config, checksum: Some(checksum))
}

pub fn with_checksum_bytes(config: KeyConfig, count: Int) -> KeyConfig {
  KeyConfig(..config, checksum_bytes: Some(count))
}

pub fn without_checksum(config: KeyConfig) -> KeyConfig {
  KeyConfig(..config, checksum: None, checksum_bytes: None)
}

pub fn generate(config: KeyConfig) -> Result(Key, Error) {
  case config.byte_count, config.char_count, config.alphabet, config.encoding {
    None, Some(_), Some(_), None -> generate_from_alphabet(config)
    Some(_), None, None, Some(_) -> generate_from_encoding(config)
    Some(_), None, None, None -> generate_from_bytes(config)
    _, _, _, _ -> Error(error.InvalidByteCount)
  }
}

pub fn from_bytes(config: KeyConfig, bytes: BitArray) -> Result(Key, Error) {
  let encoded = encode_bytes_with_config(bytes, config)
  let formatted = format_key(encoded, bytes, config)
  Ok(Key(value: formatted, bytes: bytes))
}

pub fn from_uuid(input: String) -> Result(Key, Error) {
  from_uuid_with(default_import_config(), input)
}

pub fn from_uuid_with(config: KeyConfig, input: String) -> Result(Key, Error) {
  case parse_uuid_bytes(input) {
    Ok(bytes) -> from_bytes(config, bytes)
    Error(e) -> Error(e)
  }
}

pub fn from_ulid(input: String) -> Result(Key, Error) {
  from_ulid_with(default_import_config(), input)
}

pub fn from_ulid_with(config: KeyConfig, input: String) -> Result(Key, Error) {
  case parse_ulid_bytes(input) {
    Ok(bytes) -> from_bytes(config, bytes)
    Error(e) -> Error(e)
  }
}

fn generate_from_bytes(config: KeyConfig) -> Result(Key, Error) {
  case config.byte_count {
    Some(byte_count) -> {
      case random.random_bytes(byte_count) {
        Ok(bytes) -> {
          let encoded = encode_bytes_with_config(bytes, config)
          Ok(Key(value: encoded, bytes: bytes))
        }
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
          let formatted = format_key(chars, bytes, config)
          Ok(Key(value: formatted, bytes: bytes))
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
          let formatted = format_key(encoded, bytes, config)
          Ok(Key(value: formatted, bytes: bytes))
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

fn format_key(content: String, bytes: BitArray, config: KeyConfig) -> String {
  let prefixed = case config.prefix {
    Some(prefix) -> {
      let sep = config.separator |> option.unwrap("")
      prefix <> sep <> content
    }
    None -> content
  }

  case config.checksum {
    Some(chk) -> {
      let checksum = chk.compute(bytes)
      let checksum_truncated =
        truncate_checksum(checksum, config.checksum_bytes)
      let checksum_encoded = encode_checksum(checksum_truncated, config)
      prefixed <> checksum_encoded
    }
    None -> prefixed
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
  new()
  |> with_encoding(encoding.base62())
  |> with_checksum(checksum.crc32_checksum())
  |> with_checksum_bytes(4)
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
pub fn bytes(key: Key) -> BitArray {
  key.bytes
}
