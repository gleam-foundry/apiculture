//// Built-in alphabets for key generation.
////
//// These alphabets are useful with direct character sampling. The matching
//// `apiculture/encoding` functions instead transform arbitrary bytes into
//// text; the distinction matters when choosing a generation method.

import apiculture/alphabet.{type Alphabet}

// ============================================================================
// Hexadecimal Alphabets
// ============================================================================

/// Lowercase hexadecimal (0-9, a-f)
pub fn hex_lower() -> Alphabet {
  alphabet.Alphabet(chars: "0123456789abcdef")
}

/// Uppercase hexadecimal (0-9, A-F)
pub fn hex_upper() -> Alphabet {
  alphabet.Alphabet(chars: "0123456789ABCDEF")
}

// ============================================================================
// Base32 Alphabets (RFC 4648)
// ============================================================================

/// RFC 4648 Base32 alphabet (A-Z, 2-7)
pub fn base32_rfc() -> Alphabet {
  alphabet.Alphabet(chars: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
}

/// RFC 4648 Base32 alphabet with padding (not typically used for sampling)
pub fn base32_rfc_padding() -> Alphabet {
  alphabet.Alphabet(chars: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=")
}

/// Base32hex alphabet (0-9, A-V)
pub fn base32_hex() -> Alphabet {
  alphabet.Alphabet(chars: "0123456789ABCDEFGHIJKLMNOPQRSTUV")
}

/// Crockford's Base32 alphabet
/// Designed to be human-safe, excludes I, L, O, U
pub fn base32_crockford() -> Alphabet {
  alphabet.Alphabet(chars: "0123456789ABCDEFGHJKMNPQRSTVWXYZ")
}

/// z-base-32 alphabet (human-friendly)
/// Order is designed for easy memorization and transcription
pub fn base32_z() -> Alphabet {
  alphabet.Alphabet(chars: "ybndrfg8ejkmcpqxot1uwisza345h769")
}

// ============================================================================
// Base36 Alphabets
// ============================================================================

/// Lowercase Base36 (0-9, a-z)
pub fn base36_lower() -> Alphabet {
  alphabet.Alphabet(chars: "0123456789abcdefghijklmnopqrstuvwxyz")
}

/// Uppercase Base36 (0-9, A-Z)
pub fn base36_upper() -> Alphabet {
  alphabet.Alphabet(chars: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
}

// ============================================================================
// Base58 Alphabet
// ============================================================================

/// Bitcoin-style Base58 alphabet
/// Excludes 0, O, I, l for visual clarity
pub fn base58() -> Alphabet {
  alphabet.Alphabet(
    chars: "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
  )
}

// ============================================================================
// Base62 Alphabet
// ============================================================================

/// Standard Base62 (0-9, A-Z, a-z)
pub fn base62() -> Alphabet {
  alphabet.Alphabet(
    chars: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
  )
}

// ============================================================================
// Base64 Alphabets
// ============================================================================

/// Standard Base64 character repertoire
pub fn base64() -> Alphabet {
  alphabet.Alphabet(
    chars: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
  )
}

/// Base64URL variant (URL-safe, replaces +/ with -_)
pub fn base64_url() -> Alphabet {
  alphabet.Alphabet(
    chars: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
  )
}

// ============================================================================
// Letter Alphabets
// ============================================================================

/// Lowercase letters only (a-z)
pub fn lower() -> Alphabet {
  alphabet.Alphabet(chars: "abcdefghijklmnopqrstuvwxyz")
}

/// Uppercase letters only (A-Z)
pub fn upper() -> Alphabet {
  alphabet.Alphabet(chars: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
}

// ============================================================================
// Numeric Alphabet
// ============================================================================

/// Numeric characters only (0-9)
pub fn numeric() -> Alphabet {
  alphabet.Alphabet(chars: "0123456789")
}

// ============================================================================
// Alphanumeric Alphabets
// ============================================================================

/// Lowercase alphanumeric (0-9, a-z)
pub fn alphanumeric_lower() -> Alphabet {
  alphabet.Alphabet(chars: "0123456789abcdefghijklmnopqrstuvwxyz")
}

/// Uppercase alphanumeric (0-9, A-Z)
pub fn alphanumeric_upper() -> Alphabet {
  alphabet.Alphabet(chars: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
}

/// Mixed-case alphanumeric (0-9, A-Z, a-z)
pub fn alphanumeric_mixed() -> Alphabet {
  alphabet.Alphabet(
    chars: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
  )
}

// ============================================================================
// Human-Safe Alphabet
// ============================================================================

/// Human-safe alphabet excluding visually ambiguous characters
/// Excludes: 0, O, 1, I, l, B, 8, S (can be confused)
/// Uses: 2-9, A-H, J-N, P-R, T-Z, a-k, m-n, p-t, v-z
pub fn human_safe() -> Alphabet {
  alphabet.Alphabet(chars: "23456789ABCDEFGHJKMNPQRTVWXYZabcdefghjkmnpqrtvwxyz")
}
