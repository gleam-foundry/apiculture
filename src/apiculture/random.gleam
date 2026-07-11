//// Secure randomness abstraction.
////
//// This module provides cryptographically secure random generation for Erlang
//// and JavaScript targets. It exposes both byte generation and unbiased direct
//// alphabet sampling.

import apiculture/alphabet.{type Alphabet}
import apiculture/error.{type Error}
import gleam/crypto
import gleam/list

// ============================================================================
// Random Bytes
// ============================================================================

/// Generates cryptographically secure random bytes.
///
/// On Erlang: Uses `crypto:strong_rand_bytes/1`
/// On JavaScript: Uses `crypto.getRandomValues()` (Web Crypto API)
/// 
/// Returns an error if secure randomness is unavailable.
pub fn random_bytes(count: Int) -> Result(BitArray, Error) {
  case count <= 0 {
    True -> Error(error.InvalidByteCount)
    False -> Ok(crypto.strong_random_bytes(count))
  }
}

// ============================================================================
// Direct Alphabet Sampling
// ============================================================================

/// Generates cryptographically secure random characters by sampling directly
/// from an alphabet using rejection sampling to avoid modulo bias.
///
/// This is mathematically distinct from generating random bytes and then
/// encoding them - this samples characters directly from the alphabet.
pub fn random_chars(
  alphabet alphabet: Alphabet,
  count count: Int,
) -> Result(List(Int), Error) {
  case count <= 0 {
    True -> Error(error.InvalidByteCount)
    False -> {
      let alphabet_size = alphabet.size(alphabet)
      do_rejection_sample(alphabet_size, count, [])
    }
  }
}

fn do_rejection_sample(
  alphabet_size: Int,
  count: Int,
  acc: List(Int),
) -> Result(List(Int), Error) {
  case count {
    0 -> Ok(list.reverse(acc))
    _ -> {
      let bytes = crypto.strong_random_bytes(1)

      case bytes {
        <<byte>> -> {
          let max_acceptable = { 256 / alphabet_size } * alphabet_size

          case byte < max_acceptable {
            True -> {
              let char_index = byte % alphabet_size
              do_rejection_sample(alphabet_size, count - 1, [char_index, ..acc])
            }
            False -> {
              do_rejection_sample(alphabet_size, count, acc)
            }
          }
        }
        _ -> Error(error.SecureRandomUnavailable)
      }
    }
  }
}
