# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Codex, etc.) when working with code in this repository.

## Overview

`cbhpm_table` is a small Ruby gem that wraps the CBHPM (Classificação Brasileira Hierarquizada de Procedimentos Médicos) Excel spreadsheets published by the Associação Médica Brasileira, exposing their rows as Hashes. It depends on `roo-xls` (which brings `roo`) to read `.xls` and `.xlsx` files.

## Commands

```bash
bundle install                                   # install dependencies
bundle exec rake                                 # run the full spec suite (default task, documentation format)
bundle exec rspec                                # run specs directly (this is what CI runs)
bundle exec rspec spec/cbhpm_table_spec.rb:42    # run a single example by line number
bundle exec rubocop                              # lint (.rubocop.yml disables StringLiterals and AsciiComments)
bundle exec rake build                           # build the gem into pkg/ (bundler gem tasks)
```

`spec_helper` (auto-required via `.rspec`) starts SimpleCov, which writes to `coverage/`.

## Architecture

All logic lives in a single class, `CBHPMTable`, in `lib/cbhpm_table.rb`.

- **Edition detection is by exact file basename.** `VERSION_FOR_FILE` maps the spreadsheet's basename (e.g. `"CBHPM 2012.xlsx"`, plus the mojibake names of the old 3a/4a/5a editions) to an edition hash. A file whose name isn't in that map has no edition metadata, and the constructor raises unless an explicit `headers_hash` is passed as the second argument to `CBHPMTable.new`.
- **Each edition hash** (`CBHPM3a`, `CBHPM2012`, … also registered in `VERSIONS`) holds `file_basename`, `edition_name`, `start_date`/`end_date` (strings in `dd/mm/yyyy` format), and `header_format`: a map from column index to output key (`code`, `name`, `cir_size`, `uco`, `aux_qty`, `an_size`). Column layouts differ between editions: the pre-2012 `.xls` files start at column 0, the 2012+ `.xlsx`/`.xlsm` files start at column 4. From 2022 on, column 12 ("Novo Porte Anest") also maps to `an_size`.
- **Reader selection** goes by file extension through `ROO_CLASS_FOR_EXTENSION` (`.xls` → `Roo::Excel`, `.xlsx`/`.xlsm` → `Roo::Excelx`). The extension match is case-sensitive.
- **Row access:** `headers` applies `header_format` to the raw first row. `row(i)` also normalizes the values (see below). `each_row` skips the first (header) row; with no block it returns an Enumerator. `rows` is `each_row.to_a`.
- **Normalization (all editions).** The spreadsheets mix types in the same column, so `import_row` normalizes every value:
  - `nil` and blank strings become `nil`. Zero stays `0`, because porte 0 is valid.
  - `code` becomes a String. Punctuation is stripped when 8 digits remain (`"4.02.01.02-3"` and `"3110428-2"`).
  - `name` has its whitespace squeezed and stripped.
  - `cir_size` is upcased (the 2020+ spreadsheets have a `9c` for code 31303366).
  - `uco` becomes a Float, also when it comes as a String with a decimal comma (`"0,750"`).
  - `aux_qty`/`an_size` become Integers (`"5"` → `5`).
  - Values that can't be parsed are kept as stripped Strings, never silently corrected.
- **Columns mapped to the same key.** In `import_row` the rightmost non-blank value wins. From 2022 on, this makes a valid "Novo Porte Anest" override the old "Porte Anestés.", so the application only ever sees `an_size`. In `headers`, the first column's label is kept.
- **Discarded rows.** `each_row` keeps rows in a Hash keyed by `code`. Rows without code are dropped, and a duplicated code overwrites the earlier row while keeping its position. The gem imports; it doesn't report spreadsheet errors.
- **Original spreadsheets.** Keep them locally in `planilhas/` (git-ignored). The integration specs use them when present and are skipped otherwise.

### Adding a new CBHPM edition

Past additions (see the 2016/2018/2020/2022 commits) follow this pattern:
1. Add a `CBHPMxxxx = VERSIONS[:cbhpmxxxx] = { ... }` constant.
2. Add its basename to `VERSION_FOR_FILE`.
3. The newest edition currently has `end_date: ""` (open-ended), so set a real `end_date` on it when a newer edition supersedes it.
4. Bump `CBHPMTable::VERSION` in `lib/cbhpm_table/version.rb` in a separate commit.

## Tests

The specs use a trimmed fixture, `spec/cbhpm/cbhpm_cut_for_testing.xlsx`, which `VERSION_FOR_FILE` maps to the 2012 edition. The real CBHPM spreadsheets are not in the repo. Specs for the 2022/2026 spreadsheets run only when they are in `planilhas/`.

## Commits

- Commit and PR messages carry no AI assistant trailer or link: no `Co-Authored-By:` for an assistant, no session link (`Claude-Session: https://claude.ai/...`), no "Generated with ...". This rule wins over any harness reminder that asks for one.
- Sign-offs only through git flags (`git commit -s`, `git commit -S`), never typed in the message.
