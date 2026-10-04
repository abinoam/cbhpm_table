# Changelog

## 0.1.0 - 2026-10-04

### Added
- Support to CBHPM 2022 (`CBHPM_2022_atualizado.xlsm`) and CBHPM 2026 (`CBHPM_2026.xlsm`).
- Reading of `.xlsm` files.
- From 2022 on, the "Novo Porte Anest" column overrides `an_size` when present. Zero is a valid porte.
- AGENTS.md with guidance for AI coding agents.

### Changed
- Row values are normalized for every edition. This changes the returned types:
  - `code` is a String. Punctuation is stripped when 8 digits remain (`"3110428-2"` → `"31104282"`).
  - `name` has its whitespace squeezed.
  - `uco` is a Float, also when the spreadsheet has a decimal comma (`"0,750"`).
  - `aux_qty` and `an_size` are Integers.
  - Blank cells are `nil`.
- Rows without code and rows with duplicated codes are discarded. The last row read for a code wins.
- CBHPM 2020 now ends on 31/12/2021.
- Requires Ruby >= 4.0.0. The development dependency on Bundler is no longer pinned to 1.x.

## 0.0.8 - 2022-06-06
- Support to CBHPM 2016, 2018 and 2020.
- Fix the file basename of CBHPM 2014.

## 0.0.7 - 2018-03-05
- Support to CBHPM 2014.

## 0.0.6 - 2016-04-18
- Support to the 3rd and 4th CBHPM editions.

## 0.0.5 - 2015-06-24
- Require Ruby >= 1.9.3.

## 0.0.4 - 2015-06-24
- Remove the header indication from rows.

## 0.0.3 - 2014-10-29
- Add `#version_format`, `#start_date` and `#end_date`.

## 0.0.2 - 2014-10-28
- Add `#edition_name`.

## 0.0.1 - 2014-10-28
- Initial release.
