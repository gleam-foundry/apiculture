# apiculture

![apiculture banner](https://raw.githubusercontent.com/gleam-foundry/apiculture/master/docs/img/apiculture-gleam.png)

[![Package Version](https://img.shields.io/hexpm/v/apiculture)](https://hex.pm/packages/apiculture)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/apiculture/)

Cryptographically secure random key generation for Gleam with support for multiple encodings and checksums.

## Installation

```sh
gleam add apiculture
```

## Dependencies

- **gleam_crypto** - Cryptographically secure random bytes (using `crypto:strong_rand_bytes` on Erlang, Web Crypto API on JavaScript)
- **yabase** - Base encoding/decoding (base16, base32, base36, base58, base62, base64)
- **crc32** - CRC-32 checksums for data integrity verification

## Quick Start

```gleam
import apiculture as ab

// Generate a random key with a semantic prefix
let assert Ok(key) = ab.default_prefixed("sk")
ab.key_value(key)
// => "sk_3q2Z7x9P2R8LmNkJd4Hf6Y1Bo5VsGcT7EwKu0IqXp3Zs6Ud"

 // Generate raw random bytes encoded in hex
let assert Ok(key) =
  ab.key_new()
  |> ab.key_with_random_bytes(16)
  |> ab.key_with_encoding(ab.hex_lower())
  |> ab.key_generate

ab.key_value(key)
// => "deadbeef12345678abcdef"
```

## Two Distinct Operations

This library supports two mathematically distinct operations:

### 1. Random Byte Generation

Generate cryptographically secure random bytes and encode them:

```gleam
import apiculture as ab

let assert Ok(key) =
  ab.key_new()
  |> ab.key_with_random_bytes(32)
  |> ab.key_with_encoding(ab.base64())
  |> ab.key_generate

ab.key_value(key)
```

### 2. Direct Alphabet Sampling

Generate random characters by sampling directly from an alphabet using rejection sampling to avoid modulo bias:

```gleam
import apiculture as ab
import apiculture/alphabet

let assert Ok(key) =
  ab.key_new()
  |> ab.key_with_random_chars(24)
  |> ab.key_with_alphabet(alphabet.base58())
  |> ab.key_generate

ab.key_value(key)
```

## Built-in Encodings

| Encoding | Description |
|----------|-------------|
| `hex_lower()` / `hex_upper()` | Hexadecimal |
| `base32_rfc()` / `base32_rfc_unpadded()` | RFC 4648 Base32 |
| `base32_hex()` | Base32hex |
| `base32_crockford()` | Crockford's Base32 |
| `base32_z()` | z-base-32 |
| `base36()` | Base36 |
| `base58()` | Bitcoin Base58 |
| `base62()` | Standard Base62 |
| `base64()` / `base64_url()` | Base64 / URL-safe Base64 |

## Built-in Alphabets

```gleam
import apiculture/alphabet

// For direct character sampling
alphabet.base58()        // Bitcoin-style (excludes 0, O, I, l)
alphabet.base62()         // Standard (0-9, A-Z, a-z)
alphabet.human_safe()     // Excludes visually ambiguous chars
```

## Checksums

Add integrity verification to keys:

```gleam
import apiculture as ab

let assert Ok(key) =
  ab.key_new()
  |> ab.key_with_random_bytes(16)
  |> ab.key_with_encoding(ab.base62())
  |> ab.key_with_checksum(ab.crc32())
  |> ab.key_generate
```

## Import Existing Identifiers

Convert existing UUIDs or ULIDs into API-key formatted values:

```gleam
import apiculture as ab

let assert Ok(uuid_key) =
  ab.key_from_uuid("019f3663-9b00-7a38-9427-16621a576830")

let assert Ok(ulid_key) =
  ab.key_from_ulid("01KWV69C49DSTWZBJ1SAC42E7V")
```

## Versioning Policy

- **0.1.x**: Initial development period. Breaking API changes may occur.
- **Bug fixes**: Patch version bump
- **New features**: Minor version bump
- **Breaking changes**: Minor version bump

The package will reach `1.0.0` after the API has been exercised by at least one real consumer project.

## License

MIT License - Copyright (c) 2026 Antonio Ognio

Made with ❤️ from 🇵🇪. El Perú es clave 🔑.
