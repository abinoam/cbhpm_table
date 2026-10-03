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
- **Each edition hash** (`CBHPM3a`, `CBHPM2012`, … also registered in `VERSIONS`) holds `file_basename`, `edition_name`, `start_date`/`end_date` (strings in `dd/mm/yyyy` format), and `header_format`: a map from column index to output key (`code`, `name`, `cir_size`, `uco`, `aux_qty`, `an_size`). Column layouts differ between editions: the pre-2012 `.xls` files start at column 0, the 2012+ `.xlsx` files start at column 4.
- **Reader selection** goes by file extension through `ROO_CLASS_FOR_EXTENSION` (`.xls` → `Roo::Excel`, `.xlsx` → `Roo::Excelx`). The extension match is case-sensitive.
- **Row access:** `row(i)` / `headers` apply `header_format` to a raw roo row. `each_row` skips the first (header) row; with no block it returns an Enumerator. `rows` is `each_row.to_a`.

### Adding a new CBHPM edition

Past additions (see the 2016/2018/2020 commits) follow this pattern:
1. Add a `CBHPMxxxx = VERSIONS[:cbhpmxxxx] = { ... }` constant.
2. Add its basename to `VERSION_FOR_FILE`.
3. The newest edition currently has `end_date: ""` (open-ended), so set a real `end_date` on it when a newer edition supersedes it.
4. Bump `CBHPMTable::VERSION` in `lib/cbhpm_table/version.rb` in a separate commit.

## Tests

The specs use a trimmed fixture, `spec/cbhpm/cbhpm_cut_for_testing.xlsx`, which `VERSION_FOR_FILE` maps to the 2012 edition. The real CBHPM spreadsheets are not in the repo.
