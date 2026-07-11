# apiculture

![apiculture banner](https://raw.githubusercontent.com/gleam-foundry/apiculture/master/docs/img/apiculture-gleam.png)

[![Package Version](https://img.shields.io/hexpm/v/apiculture)](https://hex.pm/packages/apiculture)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/apiculture/)

Cryptographically secure API-key generation for Gleam.

Apiculture v0.3.0 gives the common case a complete modern format while keeping
every important part configurable. Generate one random API key with the
defaults, change those defaults when an integration needs it, import UUIDs and
ULIDs without losing control of the final format, and inspect or parse the
result as structured data instead of treating it as an opaque string.

## Contents

- [Start here](#start-here)
- [The v0.3.0 default](#the-v030-default)
- [The business of API keys](#the-business-of-api-keys)
- [Why prefixes matter](#why-prefixes-matter)
- [Why checksums matter](#why-checksums-matter)
- [Generate a default key](#generate-a-default-key)
- [Modify the defaults](#modify-the-defaults)
- [Use random bytes or direct alphabet sampling](#use-random-bytes-or-direct-alphabet-sampling)
- [Work with UUIDs and ULIDs](#work-with-uuids-and-ulids)
- [Parse and validate serialized keys](#parse-and-validate-serialized-keys)
- [Inspect a `Key`](#inspect-a-key)
- [Choose an encoding](#choose-an-encoding)
- [Checksums and verification](#checksums-and-verification)
- [Builder and terminal operations](#builder-and-terminal-operations)
- [Errors and validation](#errors-and-validation)
- [Operational guidance](#operational-guidance)
- [Installation](#installation)
- [v0.3.0 API reference](#v030-api-reference)
- [License](#license)

## Start here

If you only need a new API key, use the string convenience function:

```gleam
import apiculture as ab

pub fn create_api_key() -> Result(String, ab.Error) {
  ab.key_new_as_string()
}
```

If you need to inspect the sections, verify the checksum, or keep the raw
content bytes, generate a `Key` instead:

```gleam
import apiculture as ab

pub fn create_inspectable_key() -> Result(ab.Key, ab.Error) {
  ab.key_new()
}
```

For a custom format, begin with a `KeyConfig` and finish with
`key_generate`:

```gleam
import apiculture as ab

pub fn create_partner_key() -> Result(ab.Key, ab.Error) {
  ab.key_new_as_config()
  |> ab.key_with_prefix("partner")
  |> ab.key_with_random_bytes(24)
  |> ab.key_with_encoding(ab.base58())
  |> ab.key_generate
}
```

There are three different values to keep in mind:

1. `KeyConfig` is an unfinished generation plan.
2. `Key` is a finalized key with retained structural metadata.
3. `String` is the serialized value sent to a client or stored as a token.

`key_new_as_config()` creates the first. `key_generate` creates the second.
`key_to_string` or `key_new_as_string()` gives you the third.

## The v0.3.0 default

The default API is intentionally opinionated. Calling `key_new()` or
`key_new_as_string()` does not make you assemble entropy, encoding, prefix,
separator, and checksum choices manually.

The default configuration is:

| Section | Default |
|---------|---------|
| Prefix | `sk` |
| Separator | `_` |
| Content source | 16 cryptographically secure random bytes |
| Content encoding | Base62 |
| Checksum name | `crc32` |
| Checksum | Four CRC32 bytes |

The serialized shape is:

```text
sk_<content>_crc32_<checksum>
```

For example:

```text
sk_3q2Z7x9P2R8LmNkJd4Hf6Y_crc32_2AB9XQ
```

The example is illustrative; generated values are random and will be
different every time. The content is the secret material. The prefix,
separator, checksum name, and checksum make the value identifiable and
parseable, but they do not replace secret storage or access control.

### One call for a serialized value

```gleam
let assert Ok(value) = ab.key_new_as_string()
```

Use this when the caller only needs the finished token:

```gleam
pub fn issue_key() -> Result(String, ab.Error) {
  ab.key_new_as_string()
}
```

### One call for a structured value

```gleam
let assert Ok(key) = ab.key_new()

let serialized = ab.key_to_string(key)
let content_bytes = ab.key_content_bytes(key)
let is_valid = ab.key_verify_checksum(key)
```

`key_new()` returns a finalized `Key`; it is not a builder. Use
`key_new_as_config()` when you want to customize generation.

### The default is a format contract

The default parser expects all of the following:

- exactly four `_`-separated sections
- the `sk` prefix
- Base62 content
- exactly 16 content bytes
- the lowercase checksum name `crc32`
- a four-byte Base62-encoded checksum
- a CRC32 that matches the content bytes

This strictness is intentional. A default key is not merely a random string
with some decoration around it. It is a small, self-describing wire format.

## The business of API keys

An API key is a credential issued by one system so another system can call it
without a human password, browser session, or interactive login. In practice,
that makes an API key a compact bearer credential: whoever possesses a valid
key may be able to act as its owner until the key is revoked, rotated, or
otherwise restricted.

Generating the random value is only one part of the business problem. A useful
API-key system also needs to answer operational questions:

- What product, service, or environment issued this credential?
- Can a scanner recognize it in a repository or CI log?
- Can a copied value be checked for accidental truncation or corruption?
- Can support and security teams classify it quickly during an incident?
- Can the server validate the format before looking up the credential?
- Can the organization revoke, rotate, scope, and audit it?

A naked random Base62 value addresses only the entropy question. It can be
excellent secret material and still be poor operational data. It looks like a
session identifier, a database value, a tracking ID, or ordinary application
text. That ambiguity makes secret discovery and incident response harder.

Apiculture treats the serialized key as both:

1. **A secret**, because the content must be unpredictable and protected.
2. **An operational signal**, because its shape should help software and people
   identify, classify, validate, and handle it correctly.

This is why v0.3.0 makes a prefix and checksum part of the default design.
They are not claims that a decorated string is magically safer. They are
practical metadata and integrity mechanisms around high-entropy content.

### What a generated key does not do

Apiculture generates and formats key material. It does not provide:

- a database for issued credentials
- authentication middleware
- authorization or scopes
- revocation or rotation storage
- rate limiting
- audit logging
- encryption at rest
- protection after a key has been exposed

Your application still needs a lifecycle around the value. Usually that means
storing a hash or keyed digest for lookup, showing the secret only at creation
time, assigning scopes, recording creation and last-use metadata, and offering
revocation and rotation.

## Why prefixes matter

A prefix is a short, recognizable label at the start of the serialized key.
The default is `sk`; an application can choose a more specific label such as
`pk`, `service`, `partner`, or `test` when its surrounding format requires it.

### Prefixes improve discovery

Secret scanners and repository tools often start with a candidate pattern. A
stable prefix gives them a strong signal that a string is intended to be a
credential rather than a random identifier. The structured default can be
matched with a pattern such as:

```text
sk_[A-Za-z0-9]+_crc32_[A-Za-z0-9]+
```

The prefix is not secret, so it is safe and useful for scanners to know. The
actual content remains unpredictable.

### Prefixes improve classification

Organizations commonly have several key families:

```text
sk_...        application secret key
pk_...        public or publishable key
test_...      non-production credential
partner_...   integration credential
```

The label can tell an operator which product or environment should be
investigated before they decode or query anything. It can also help a server
route validation to the right credential store.

### Prefixes reduce handling mistakes

A key that visibly belongs to a specific system is less likely to be pasted
into the wrong dashboard, environment, or configuration field. This is a
human-factors benefit, not a cryptographic one.

### Prefix design guidance

Keep prefixes:

- short enough to scan and type
- stable across the lifetime of a format
- meaningful to operators and tooling
- free of the configured separator
- non-sensitive; never put a tenant secret or authorization data in it

If a legacy integration requires an unprefixed value, use
`key_disable_prefix` explicitly rather than weakening the default for every
caller.

## Why checksums matter

A checksum is a compact integrity signal computed from the content bytes. In
the default format, CRC32 is rendered as four bytes and then encoded with the
same Base62 encoding as the content.

### Checksums catch accidental damage

API keys are copied through systems that can truncate or alter text:

- a user copies only part of a value from a terminal
- a line-wrapping or export step drops characters
- a support ticket changes a character
- a configuration template inserts or removes text
- a value is pasted into the wrong field

Recomputing CRC32 lets the receiver reject a damaged value before treating it
as a real credential lookup. This is especially useful for diagnostics,
imports, and secret-scanning workflows.

### Checksums make the format self-describing

The default includes the literal checksum name `crc32`:

```text
sk_<content>_crc32_<checksum>
```

That name tells a parser which algorithm the trailing section represents. It
also leaves room for future named algorithms without requiring a parser to
guess from the checksum length.

### Checksums are not security hashes

CRC32 is not intended to:

- make a weak secret strong
- hide the content
- resist a deliberate attacker
- replace password hashing
- replace authenticated encryption

CRC32 is fast and useful for accidental corruption detection. The security of
the credential comes from the unpredictable random content and from the
application's storage, authorization, and revocation controls.

### Checksums are not proof that a key is safe

An attacker who can modify a key can generally recompute a non-cryptographic
checksum. A valid checksum says that the serialized checksum matches the
content under the selected algorithm. It does not prove who issued the key or
whether the key is currently authorized.

## Generate a default key

### Return a string immediately

```gleam
import apiculture as ab

pub fn issue_default_key() -> Result(String, ab.Error) {
  ab.key_new_as_string()
}
```

### Keep the sections for later work

```gleam
import apiculture as ab

pub fn inspect_default_key() -> Result(
  #(String, Int, Bool),
  ab.Error,
) {
  let assert Ok(key) = ab.key_new()

  Ok(#(
    ab.key_to_string(key),
    ab.key_content_byte_count(key),
    ab.key_verify_checksum(key),
  ))
}
```

### Generate several keys

Each call obtains fresh cryptographically secure random bytes. Do not generate
one key and reuse it for unrelated users or integrations merely because the
content is long enough.

```gleam
import apiculture as ab
import gleam/list

pub fn issue_many(count: Int) -> Result(List(String), ab.Error) {
  list.try_map(list.range(1, count), fn(_) {
    ab.key_new_as_string()
  })
}
```

The uniqueness of a generated key is probabilistic, as with all random
identifiers. The default carries 128 bits of random content, which is intended
to make accidental collisions and guessing infeasible for ordinary API-key
issuance volumes.

## Modify the defaults

The v0.3.0 builder starts from an opinionated, ready-to-generate configuration:

```gleam
let config = ab.key_new_as_config()
ab.key_config_is_ready(config)
// True
```

Builder functions return another `KeyConfig`, so they work naturally in a
pipeline. The final call is either `key_generate` for random content or one of
the terminal import functions for existing identifier content.

### Change the prefix

```gleam
let assert Ok(key) =
  ab.key_new_as_config()
  |> ab.key_with_prefix("service")
  |> ab.key_generate
```

The result keeps the default Base62 content, `_` separator, and CRC32 sections
while replacing only the prefix.

### Change the amount of random content

```gleam
let assert Ok(key) =
  ab.key_new_as_config()
  |> ab.key_with_random_bytes(32)
  |> ab.key_generate
```

`key_with_random_bytes(32)` means 32 random bytes, or 256 bits, before
encoding. It does not mean 32 serialized characters.

### Change the encoding

```gleam
let assert Ok(key) =
  ab.key_new_as_config()
  |> ab.key_with_encoding(ab.base58())
  |> ab.key_generate
```

When the configuration generates random bytes, the selected encoding renders
those bytes as the content section. The checksum is rendered with that same
encoding.

### Change the separator

```gleam
let assert Ok(key) =
  ab.key_new_as_config()
  |> ab.key_with_separator(".")
  |> ab.key_generate
```

The separator is structural. It is used at every configured boundary:

```text
sk.<content>.crc32.<checksum>
```

This is mainly for interoperability. `_` is the recommended default because
it is easy to recognize, scan, split, and transport.

### Change the checksum byte count

```gleam
let assert Ok(key) =
  ab.key_new_as_config()
  |> ab.key_with_checksum_bytes(2)
  |> ab.key_generate
```

The checksum algorithm still computes CRC32, but only the requested number of
leading checksum bytes is serialized and retained. Use the default four bytes
unless an external format requires a shorter section.

### Change several defaults together

```gleam
let assert Ok(key) =
  ab.key_new_as_config()
  |> ab.key_with_prefix("partner")
  |> ab.key_with_separator("_")
  |> ab.key_with_random_bytes(24)
  |> ab.key_with_encoding(ab.base58())
  |> ab.key_with_checksum(ab.crc32())
  |> ab.key_with_checksum_bytes(4)
  |> ab.key_generate
```

This is still a structured key. It is simply a structured key with an
application-specific contract that your scanners, parsers, and consumers must
share.

### Disable only what an integration requires

The default is deliberately stronger operationally than a bare random string.
Use the explicit opt-outs only when an existing wire format requires them:

```gleam
let assert Ok(no_prefix) =
  ab.key_new_as_config()
  |> ab.key_disable_prefix
  |> ab.key_generate

let assert Ok(no_checksum_name) =
  ab.key_new_as_config()
  |> ab.key_disable_checksum_name
  |> ab.key_generate

let assert Ok(no_checksum) =
  ab.key_new_as_config()
  |> ab.key_disable_checksum
  |> ab.key_generate
```

`key_disable_checksum_name` keeps CRC32 but removes the serialized algorithm
name. `key_disable_checksum` removes both the checksum and its name. The
latter is the largest reduction in validation and should be intentional.

### Build an unprefixed, named-checksum format

```gleam
let assert Ok(key) =
  ab.key_new_as_config()
  |> ab.key_disable_prefix
  |> ab.key_generate
```

Its shape is:

```text
<content>_crc32_<checksum>
```

### Build a compact compatibility format

```gleam
let assert Ok(key) =
  ab.key_new_as_config()
  |> ab.key_disable_prefix
  |> ab.key_disable_checksum_name
  |> ab.key_generate
```

Its shape is:

```text
<content>_<checksum>
```

That shape is supported, but it is not the v0.3.0 recommendation because it
loses the strongest classification and self-description signals.

## Use random bytes or direct alphabet sampling

Apiculture supports two different random-generation operations. They are both
secure when used correctly, but they answer different design questions.

### Random bytes followed by encoding

This is the default and the usual choice for credentials. Secure random bytes
are generated first, then encoded for transport:

```gleam
let assert Ok(key) =
  ab.key_new_as_config()
  |> ab.key_with_random_bytes(16)
  |> ab.key_with_encoding(ab.base62())
  |> ab.key_generate
```

The security quantity is the byte count. The encoded character count depends
on the encoding and is not the same thing as the entropy count.

### Direct alphabet sampling

Use direct sampling when the output must contain a specific number of
characters from a specific alphabet:

```gleam
import apiculture as ab
import apiculture/alphabets

let assert Ok(key) =
  ab.key_new_as_config()
  |> ab.key_with_random_chars(24)
  |> ab.key_with_alphabet(alphabets.base58())
  |> ab.key_generate
```

Apiculture uses rejection sampling rather than a simple byte modulo. That
avoids over-representing some characters when the alphabet size does not divide
the byte range evenly.

### Choose the operation deliberately

Prefer random bytes plus encoding when:

- the credential's entropy is the primary requirement
- you want a stable byte count
- the content may later be decoded back to bytes
- you are using the opinionated default

Prefer direct alphabet sampling when:

- the serialized content must have an exact character count
- the alphabet has human-factors requirements
- you do not need the content to represent arbitrary random bytes under an
  encoding

## Work with UUIDs and ULIDs

UUIDs and ULIDs are already identifiers. They are not automatically secrets,
and they are not automatically API keys. A UUID or ULID may be predictable,
enumerable, or exposed in logs. Use these import APIs when you need to put an
existing 128-bit identifier into a consistent API-key-shaped format, not as a
replacement for generating high-entropy credentials.

### Convert a UUID with the default format

```gleam
import apiculture as ab

let assert Ok(key) =
  ab.key_from_uuid("019f3663-9b00-7a38-9427-16621a576830")

let value = ab.key_to_string(key)
// sk_<Base62 UUID bytes>_crc32_<checksum>
```

`key_from_uuid` is terminal. It parses the UUID, converts it to its canonical
16 bytes, applies the default format, and returns a finalized `Key`.

### Convert a ULID with the default format

```gleam
let assert Ok(key) =
  ab.key_from_ulid("01KWV69C49DSTWZBJ1SAC42E7V")
```

The terminal helper accepts the canonical 26-character ULID representation and
returns a formatted `Key` using the same default `sk`, Base62, `_`, `crc32`
layout.

### Parse first, format second

Use `bytes_from_uuid` or `bytes_from_ulid` when formatting needs to be a
separate, chainable step:

```gleam
import apiculture as ab

pub fn format_existing_ulid() -> Result(String, ab.Error) {
  let assert Ok(bytes) =
    ab.bytes_from_ulid("01KWV69C49DSTWZBJ1SAC42E7V")

  let assert Ok(key) =
    ab.key_new_as_config()
    |> ab.key_with_prefix("order")
    |> ab.key_with_encoding(ab.base32_crockford())
    |> ab.key_with_checksum(ab.crc32())
    |> ab.key_with_checksum_bytes(4)
    |> ab.key_from_bytes(bytes)

  Ok(ab.key_to_string(key))
}
```

This separation is useful when:

- the source type is selected dynamically
- the same bytes need several output formats
- you want to validate or store the canonical bytes before formatting
- the formatting pipeline is shared by UUID, ULID, and other binary sources

`bytes_from_*` returns raw bytes, not a partially built `KeyConfig` and not a
serialized key. `key_from_bytes` is the terminal step.

### Format a UUID with a configured layout

When the source type is known and you want one terminal operation, use the
configured helper:

```gleam
let config =
  ab.key_new_as_config()
  |> ab.key_with_prefix("customer")
  |> ab.key_with_encoding(ab.base58())
  |> ab.key_with_checksum(ab.crc32())

let assert Ok(key) =
  ab.key_from_uuid_with_config(
    config,
    "019f3663-9b00-7a38-9427-16621a576830",
  )
```

The ULID equivalent is `key_from_ulid_with_config(config, input)`.

### UUID and ULID validation

Malformed UUID and ULID input returns `Error(MalformedInput)`. UUID parsing
accepts the usual hyphenated form and UUID URN prefix. ULID parsing validates
the 26-character Crockford representation and rejects values whose leading
bits exceed the ULID range.

## Parse and validate serialized keys

Parsing is the reverse of serialization, but it is intentionally strict. The
parser does not guess an encoding or silently accept a malformed checksum.

### Parse the default format

```gleam
import apiculture as ab

pub fn validate_candidate(candidate: String) -> Bool {
  case ab.key_parse(candidate) {
    Ok(key) -> ab.key_verify_checksum(key)
    Error(_) -> False
  }
}
```

`key_parse` uses `key_default_format()` internally. A successful result has:

- canonical Base62 content
- 16 content bytes
- the expected `sk` prefix
- the expected lowercase `crc32` name
- four checksum bytes
- a checksum that matches the content

The returned value is a normal `Key`, so it can be passed to all inspection
helpers and serialized again with `key_to_string`.

### Parse a custom format

Start from the default format and change the parse-relevant properties:

```gleam
let format =
  ab.key_default_format()
  |> ab.key_format_with_prefix("partner")
  |> ab.key_format_with_encoding(ab.base58())
  |> ab.key_format_with_content_bytes(24)

let result = ab.key_parse_with_format(candidate, format)
```

`KeyFormat` describes the serialized shape only. It does not describe whether
the source was random bytes, a UUID, or a ULID; that information cannot be
recovered from the string.

### Parse reduced formats explicitly

```gleam
let format =
  ab.key_default_format()
  |> ab.key_format_without_prefix
  |> ab.key_format_without_checksum_name

let result = ab.key_parse_with_format(candidate, format)
```

The parser still validates every section that the format declares. There is no
unverified default parser: callers who want to inspect damaged candidates
should handle the parse error rather than treating a partially valid value as
an authenticated credential.

### Parsing errors

The parser distinguishes malformed structure from checksum failure:

- `MalformedInput` means the sections, encoding, canonical form, or expected
  lengths are invalid.
- `ChecksumMismatch` means the checksum section is structurally valid but does
  not match the content bytes.

Both cases should normally reject the candidate. The distinction is useful for
diagnostics and tests, not for granting access.

## Inspect a `Key`

A generated or parsed `Key` retains its structural sections. Use the direct
accessors for ordinary application code.

```gleam
let assert Ok(key) = ab.key_new()

let serialized = ab.key_to_string(key)
let prefix = ab.key_prefix_value(key)
let separator = ab.key_separator_value(key)
let has_prefix = ab.key_has_prefix(key)
let has_checksum = ab.key_has_checksum(key)
let content = ab.key_content_value(key)
let content_bytes = ab.key_content_bytes(key)
let content_byte_count = ab.key_content_byte_count(key)
let content_char_count = ab.key_content_char_count(key)
let checksum_name = ab.key_checksum_name(key)
let checksum_value = ab.key_checksum_value(key)
let checksum_bytes = ab.key_checksum_bytes(key)
let checksum_byte_count = ab.key_checksum_byte_count(key)
let checksum_char_count = ab.key_checksum_char_count(key)
```

`key_bytes` remains available as an alias for the raw content bytes. Prefer
`key_content_bytes` in new code because it makes the distinction from checksum
bytes explicit.

### Inspect grouped sections

When a tool needs the complete structure together, use `key_sections`:

```gleam
let sections = ab.key_sections(key)
```

The `KeySections` value contains:

- optional `prefix`
- optional `separator`
- encoded `content_value`
- raw `content_bytes`
- optional `checksum_name`
- optional encoded `checksum_value`
- optional raw `checksum_bytes`

This is convenient for diagnostics, reporting, secret-scanning adapters, and
format-aware tooling.

### Verify a checksum

The default verifier uses CRC32:

```gleam
let valid = ab.key_verify_checksum(key)
```

Use the explicit algorithm form when validating a key built with an explicitly
selected checksum algorithm:

```gleam
let valid = ab.key_verify_checksum_with_algo(key, ab.crc32())
```

A key without a checksum returns `False` from either verifier. Verification is
local and does not prove that a server has issued or authorized the key.

## Choose an encoding

Encodings transform bytes into transport-safe strings. They affect the visible
length and character set, but the entropy comes from the underlying bytes.

| Function | Character set or purpose |
|----------|--------------------------|
| `hex_lower()` | Lowercase hexadecimal |
| `hex_upper()` | Uppercase hexadecimal |
| `base32_rfc()` | RFC 4648 Base32 with padding |
| `base32_rfc_unpadded()` | RFC 4648 Base32 without padding |
| `base32_hex()` | Base32hex |
| `base32_crockford()` | Human-oriented Crockford Base32 |
| `base32_z()` | z-base-32 |
| `base36()` | Base36 |
| `base58()` | Bitcoin-style Base58 |
| `base62()` | Uppercase/lowercase letters and digits |
| `base64()` | Standard Base64 |
| `base64_url()` | URL-safe Base64 |

### Encoding example

```gleam
let assert Ok(hex_key) =
  ab.key_new_as_config()
  |> ab.key_with_encoding(ab.hex_lower())
  |> ab.key_generate
```

If a format needs a fixed character count instead of a fixed byte count, use
direct alphabet sampling with `key_with_random_chars` and
`key_with_alphabet`.

### Encoding and canonical parsing

The parser checks that decoding and re-encoding produces the exact supplied
section. This rejects alternate spellings and makes serialized values
canonical. When you change an encoding, provide the matching `KeyFormat` to
`key_parse_with_format`.

## Checksums and verification

CRC32 is the checksum currently provided by apiculture:

```gleam
let algorithm = ab.crc32()
```

You can use the low-level checksum helpers when integrating with another
format:

```gleam
let expected =
  ab.checksum_format(
    ab.crc32(),
    content_bytes,
    fn(bytes) { ab.encoding_encode(ab.hex_lower(), bytes) },
  )
```

When the surrounding protocol already has the raw expected checksum bytes,
`checksum_verify(ab.crc32(), content_bytes, expected_bytes)` verifies them.
The key builder is usually preferable because it retains the rendered and raw
checksum sections together.

## Builder and terminal operations

The API separates configuration from finalization so a pipeline does not
accidentally confuse a source identifier with a finished credential.

### Configuration operations

These return `KeyConfig` and can be chained:

- `key_new_as_config`
- `key_with_random_bytes`
- `key_with_random_chars`
- `key_with_alphabet`
- `key_with_encoding`
- `key_with_prefix`
- `key_with_separator`
- `key_with_checksum`
- `key_with_checksum_bytes`
- `key_disable_prefix`
- `key_disable_checksum_name`
- `key_disable_checksum`

### Terminal generation operations

These return `Result(Key, Error)`:

- `key_generate(config)` generates new random content according to the plan.
- `key_from_bytes(config, bytes)` formats existing bytes.
- `key_from_uuid(input)` parses and formats a UUID with defaults.
- `key_from_uuid_with_config(config, input)` uses a custom UUID format.
- `key_from_ulid(input)` parses and formats a ULID with defaults.
- `key_from_ulid_with_config(config, input)` uses a custom ULID format.

### Readiness checks

Use `key_config_is_ready` when building a configuration incrementally:

```gleam
let config =
  ab.key_new_as_config()
  |> ab.key_with_random_chars(24)
  |> ab.key_with_alphabet(ab.base58())

case ab.key_config_is_ready(config) {
  True -> ab.key_generate(config)
  False -> Error(ab.invalid_byte_count_error())
}
```

Most pipelines can simply call `key_generate`; the readiness function is most
useful when configuration comes from application data or several optional
branches.

## Errors and validation

Public operations return `Result` rather than silently producing a malformed
value. The error type includes:

| Error | Meaning |
|-------|---------|
| `EmptyAlphabet` | The custom alphabet has no characters. |
| `SingleCharacterAlphabet` | A one-character alphabet cannot provide useful randomness. |
| `DuplicateCharacters` | The alphabet contains duplicate symbols. |
| `SecureRandomUnavailable` | Secure randomness is unavailable on the target. |
| `InvalidByteCount` | A byte or character count is zero, negative, or incomplete. |
| `InvalidEncoding` | An encoding configuration is invalid. |
| `MalformedInput` | UUID, ULID, serialized key, or encoded input is malformed. |
| `ChecksumMismatch` | A parsed checksum does not match the content. |

### Treat failures as failures

Do not fall back to timestamps, counters, `String.hash`, or a non-secure random
source when `key_new` or `key_generate` returns an error. A credential generator
should fail closed and make the availability problem visible.

### Validate before authorization

For a server receiving a serialized key:

1. Parse the expected format.
2. Reject malformed values and checksum mismatches.
3. Look up the credential using a protected representation of the content.
4. Check revocation, scope, tenant, environment, and status.
5. Record appropriate audit metadata without logging the secret.

Parsing and checksum verification are input hygiene. They are not an
authorization decision.

## Operational guidance

### Never log the complete key

Avoid logging the serialized key in request logs, exceptions, metrics, tracing
spans, support messages, or analytics events. A prefix is safe to use as a
search signal, but the content is a bearer credential.

If diagnostics need correlation, log a short non-reversible fingerprint or an
internal credential ID instead of the key.

### Store credentials for lookup safely

The exact storage design belongs to the application, but a common pattern is:

- show the full secret only once at creation
- store a cryptographic hash or keyed digest of the content for lookup
- store prefix, owner, scopes, environment, creation time, and expiry separately
- support revocation and rotation
- use constant-time comparisons where applicable
- protect the storage and encryption keys independently

The checksum is not a substitute for this storage representation.

### Use environment-specific prefixes carefully

Prefixes such as `test` and `live` can reduce operator mistakes and improve
scanning, but they do not enforce environment isolation. Enforce environment
boundaries in authorization and credential storage too.

### Rotate exposed keys

If a key appears in a public repository, CI output, chat, a ticket, or a
screenshot, assume it is compromised. Revoke it, issue a replacement, and
investigate where it was used. A matching CRC32 does not make exposure safe.

### Keep formats stable once published

The default v0.3.0 layout is a wire contract. If your application publishes a
custom prefix, separator, encoding, or checksum length, document that format
and use a matching `KeyFormat` for parsing. Do not silently change the format
of already-issued values.

## Installation

Add apiculture to a Gleam project:

```sh
gleam add apiculture
```

Then import the top-level API:

```gleam
import apiculture as ab
```

The package uses `gleam_crypto` for secure randomness, `yabase` for encoding,
and `crc32` for the default checksum implementation.

## v0.3.0 API reference

### Default creation

| Function | Result | Use |
|----------|--------|-----|
| `key_new()` | `Result(Key, Error)` | Generate a default structured key. |
| `key_new_as_string()` | `Result(String, Error)` | Generate and serialize a default key. |
| `key_new_as_config()` | `KeyConfig` | Start a customizable default configuration. |
| `key_generate(config)` | `Result(Key, Error)` | Finalize a random-generation configuration. |
| `key_config_is_ready(config)` | `Bool` | Check whether a configuration can be finalized. |

### Imported content

| Function | Use |
|----------|-----|
| `bytes_from_uuid(input)` | Parse a UUID into 16 canonical bytes. |
| `bytes_from_ulid(input)` | Parse a ULID into 16 canonical bytes. |
| `key_from_bytes(config, bytes)` | Format existing bytes as a key. |
| `key_from_uuid(input)` | Import a UUID using the default format. |
| `key_from_uuid_with_config(config, input)` | Import a UUID using a custom format. |
| `key_from_ulid(input)` | Import a ULID using the default format. |
| `key_from_ulid_with_config(config, input)` | Import a ULID using a custom format. |

### Key inspection

| Function | Returns |
|----------|---------|
| `key_to_string(key)` / `key_value(key)` | Serialized key string. |
| `key_bytes(key)` | Raw content bytes; compatibility alias. |
| `key_prefix_value(key)` | `Option(String)` prefix. |
| `key_separator_value(key)` | `Option(String)` separator. |
| `key_has_prefix(key)` | Whether a prefix is present. |
| `key_has_checksum(key)` | Whether a checksum is present. |
| `key_content_value(key)` | Encoded content section. |
| `key_content_bytes(key)` | Raw content bytes. |
| `key_content_byte_count(key)` | Content byte count. |
| `key_content_char_count(key)` | Encoded content character count. |
| `key_checksum_name(key)` | `Option(String)` algorithm name. |
| `key_checksum_value(key)` | `Option(String)` encoded checksum. |
| `key_checksum_bytes(key)` | `Option(BitArray)` raw checksum. |
| `key_checksum_byte_count(key)` | Checksum byte count, or `0`. |
| `key_checksum_char_count(key)` | `Option(Int)` encoded checksum length. |
| `key_sections(key)` | All sections grouped as `KeySections`. |
| `key_verify_checksum(key)` | Verify with default CRC32. |
| `key_verify_checksum_with_algo(key, checksum)` | Verify with an explicit algorithm. |

### Builder functions

| Function | Effect |
|----------|--------|
| `key_with_random_bytes(config, count)` | Select secure random bytes. |
| `key_with_random_chars(config, count)` | Select direct alphabet sampling. |
| `key_with_alphabet(config, alphabet)` | Set the direct-sampling alphabet. |
| `key_with_encoding(config, encoding)` | Set the content/checksum encoding. |
| `key_with_prefix(config, prefix)` | Set a prefix. |
| `key_with_separator(config, separator)` | Set every structural separator. |
| `key_with_checksum(config, checksum)` | Set the checksum algorithm. |
| `key_with_checksum_bytes(config, count)` | Set retained checksum byte count. |
| `key_disable_prefix(config)` | Remove the prefix. |
| `key_disable_checksum_name(config)` | Keep the checksum, remove its name. |
| `key_disable_checksum(config)` | Remove checksum and checksum name. |

### Parsing functions

| Function | Use |
|----------|-----|
| `key_default_format()` | Get the strict default `KeyFormat`. |
| `key_parse(input)` | Parse the default `sk_<content>_crc32_<checksum>` format. |
| `key_parse_with_format(input, format)` | Parse an explicitly configured format. |
| `key_format_with_prefix(format, prefix)` | Change expected prefix. |
| `key_format_without_prefix(format)` | Remove expected prefix. |
| `key_format_with_separator(format, separator)` | Change expected separator. |
| `key_format_with_encoding(format, encoding)` | Change expected encoding. |
| `key_format_with_checksum(format, checksum)` | Set expected checksum. |
| `key_format_without_checksum_name(format)` | Remove expected checksum name. |
| `key_format_without_checksum(format)` | Remove expected checksum. |
| `key_format_with_checksum_bytes(format, count)` | Set expected checksum size. |
| `key_format_with_content_bytes(format, count)` | Set expected content size. |

### Encodings and checksums

The top-level encoding constructors are `hex_lower`, `hex_upper`,
`base32_rfc`, `base32_rfc_unpadded`, `base32_hex`, `base32_crockford`,
`base32_z`, `base36`, `base58`, `base62`, `base64`, and `base64_url`.

The checksum API includes `crc32`, `checksum_format`, and `checksum_verify`.
Custom alphabets can be created with `new_alphabet` and inspected with
`alphabet_characters` and `alphabet_size`.

## License

MIT License - Copyright (c) 2026 Antonio Ognio

Made with ❤️ from 🇵🇪. El Perú es clave 🔑.
