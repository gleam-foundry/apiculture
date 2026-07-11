# Changelog

All notable changes to this project will be documented in this file.

## Unreleased (planned 0.3.0)

### Breaking changes

- **Default key layout changes** from an unprefixed or checksum-concatenated
  value to the self-describing format
  `sk_<content>_crc32_<checksum>`.
  - The default prefix changes to `sk`.
  - `_` separates every structural section.
  - The lowercase checksum name `crc32` is serialized before the checksum.
  - CRC32, using all four checksum bytes, is the default checksum.
- **`key_new()` now creates a finalized default `Key`.** It uses 16 random
  bytes, Base62 content, the `sk` prefix, `_` separator, `crc32` name, and a
  CRC32 checksum. Replace builder uses of `key_new()` with
  `key_new_as_config()`.
- **Default string generation is explicit.** Use
  `key_new_as_string() -> Result(String, Error)` to generate the default
  serialized key in one call. Use `key_new() -> Result(Key, Error)` when
  inspection metadata is required.
- **`key_with_separator` now applies to every structural boundary**, including
  the content/checksum-name and checksum-name/checksum boundaries, not only
  the prefix/content boundary.
- **Checksum verification is split by intent.**
  - Replace `key_verify_checksum(key, ab.crc32())` with
    `key_verify_checksum(key)` for the default CRC32 algorithm.
  - Replace `key_verify_checksum(key, algorithm)` with
    `key_verify_checksum_with_algo(key, algorithm)` for an explicitly chosen
    algorithm.
- **Checksum opt-out is renamed.** Replace `key_without_checksum` with
  `key_disable_checksum`. The new `key_disable_prefix` and
  `key_disable_checksum_name` helpers make reduced layouts explicit.
- **Default UUID and ULID import output changes** from the `sk_live_` format
  with a concatenated checksum to `sk_<content>_crc32_<checksum>`.
- **Configurable UUID and ULID import helpers are renamed.** Replace
  `key_from_uuid_with` with `key_from_uuid_with_config`, and
  `key_from_ulid_with` with `key_from_ulid_with_config`.

### Added

- Add `key_parse(input) -> Result(Key, Error)` for strict parsing and CRC32
  verification of the default `sk_<content>_crc32_<checksum>` layout.
- Add `KeyFormat` and `key_parse_with_format(input, format)` for explicitly
  configured non-default serialized layouts.
- Add direct `Key` accessors for prefix, separator, content bytes and
  character count, checksum name, checksum byte count, checksum character
  count, and prefix/checksum predicates.

### Migration guidance

- Prefer `ab.key_new_as_string()` when only the default serialized value is
  needed, or `ab.key_new()` when a structured `Key` is needed.
- Start customized builder flows with `ab.key_new_as_config()`.
- Use `key_disable_prefix`, `key_disable_checksum_name`, or
  `key_disable_checksum` only when interoperating with a format that requires
  a reduced layout.
- Update consumers, storage validation, secret-scanning patterns, and parsers
  to expect the serialized checksum name and underscore-delimited sections.
- Treat existing generated keys as legacy values; their serialized form does
  not change in storage, but new keys use the 0.3.0 format.

## 0.2.0 - 2026-07-06

- Add support for importing existing identifiers into API-key formatted values
- Add `key_from_bytes`, `key_from_uuid`, and `key_from_ulid` APIs
- Add configurable `key_from_uuid_with` and `key_from_ulid_with` helpers
- Add `bytes_from_uuid` and `bytes_from_ulid` helpers for explicit parse-then-format flows
- Add `key_config_is_ready` to distinguish builder state from finalized keys
- Add key checksum/content inspection helpers (`key_content_value`, `key_content_byte_count`, `key_checksum_value`, `key_checksum_bytes`, `key_verify_checksum`, `key_sections`)
- Add UUID and ULID parsing coverage and documentation examples
- Add repository banner asset and canonical GitHub banner URL in `README.md`

## 0.1.0 - 2026-07-06

- Initial release
- Cryptographically secure random key generation for Gleam
- Support for multiple encodings, alphabets, prefixes, and CRC32 checksums
- Default structured key format helpers
