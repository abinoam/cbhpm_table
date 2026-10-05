# coding: utf-8

require "cbhpm_table/version"

require 'roo-xls'

# CBHPMTable:
#
# cbhpm_table = CBHPMTable.new "CBHPM 2012.xlsx"
#
# cbhpm_table.headers
#   #=> { "code"=>"ID do Procedimento", "name"=>"Descrição do Procedimento",
#         "cir_size"=>nil, "uco"=>"Custo Operac.", "aux_qty"=>"Nº de Aux.",
#         "an_size"=>"Porte Anestés." }
#
# cbhpm_table.row(2)
#   #=> { "code"=>"10101012",
#         "name"=>"Em consultório (no horário normal ou preestabelecido)",
#         "cir_size"=>"2B", "uco"=>nil, "aux_qty"=>nil, "an_size"=>nil}) }
#
# cbhpm_table.rows
#  #=> # Returns an Array of Rows (as individual Hashes)
#
# cbhpm_table.each_row do |row|
#   # do whatever with the row
# end
class CBHPMTable
  attr_reader :roo

  def initialize(cbhpm_path, headers_hash = nil)
    @cbhpm_path = cbhpm_path

    roo_class = ROO_CLASS_FOR_EXTENSION[File.extname(cbhpm_path)]
    @roo = roo_class.new(cbhpm_path)
    @headers_hash = headers_hash || fetch_headers_hash
    fail "Can't find predefined headers for #{cbhpm_path}" unless @headers_hash
  end

  # When several columns map to the same key, the first column names it.
  def headers
    header_row = roo.row(first_row_index)
    headers_hash.each_with_object({}) do |(col, name), mapped_row|
      mapped_row[name] ||= header_row[col]
    end
  end

  def first_row_index
    roo.first_row
  end

  def row(row_index)
    import_row(roo.row(row_index))
  end

  # When several columns map to the same key, the rightmost non-blank value
  # wins. From CBHPM 2022 on, this makes a valid "Novo Porte Anest" override
  # the old "Porte Anestés." in an_size. Zero is a valid porte.
  def import_row(row_array)
    headers_hash.each_with_object({}) do |(col, name), imported_row|
      value = normalize(name, row_array[col])
      imported_row[name] = value unless value.nil? && imported_row.key?(name)
    end
  end

  def normalize(name, value)
    return nil if value.nil? || (value.is_a?(String) && value.strip.empty?)

    case name
    when "code" then normalize_code(value)
    when "name" then value.to_s.gsub(/\s+/, " ").strip
    when "cir_size" then value.is_a?(String) ? value.strip.upcase : value
    when "uco" then normalize_decimal(value)
    when "aux_qty", "an_size" then normalize_integer(value)
    else value.is_a?(String) ? value.strip : value
    end
  end

  def normalize_code(value)
    return integer_value(value).to_s if value.is_a?(Numeric)
    code = value.strip
    digits = code.delete(".-")
    digits.match?(/\A\d{8}\z/) ? digits : code
  end

  def normalize_decimal(value)
    return value.to_f if value.is_a?(Numeric)
    decimal = value.strip
    decimal.match?(/\A\d+([.,]\d+)?\z/) ? decimal.tr(",", ".").to_f : decimal
  end

  def normalize_integer(value)
    integer_value(value) || (value.is_a?(String) ? value.strip : value)
  end

  def integer_value(value)
    case value
    when Integer then value
    when Float then value.to_i if value == value.to_i
    when String then value.strip.to_i if value.strip.match?(/\A\d+\z/)
    end
  end

  def rows
    each_row.to_a
  end

  def edition_name
    version_format[:edition_name]
  end

  def version_format
    @version_format ||= fetch_version_format
  end

  def fetch_version_format
    VERSION_FOR_FILE[File.basename(cbhpm_path)]
  end

  attr_reader :cbhpm_path

  # Rows without code are silently discarded. So are duplicated codes: the
  # last row read for a code overwrites the previous ones, keeping the
  # position of the first.
  def each_row(&block)
    return to_enum(:each_row) unless block_given?
    unique_rows.each_value(&block)
  end

  def unique_rows
    @unique_rows ||= roo.to_enum(:each).drop(1).each_with_object({}) do |row_array, rows|
      imported_row = import_row(row_array)
      rows[imported_row["code"]] = imported_row unless imported_row["code"].nil?
    end
  end

  def headers_hash
    @headers_hash ||= fetch_headers_hash
  end

  def fetch_headers_hash
    version_format[:header_format]
  end

  def start_date
    version_format[:start_date]
  end

  def end_date
    version_format[:end_date]
  end

  private :first_row_index, :import_row, :fetch_version_format
  private :fetch_headers_hash, :normalize
  private :normalize_code, :normalize_decimal, :normalize_integer
  private :integer_value, :unique_rows

  VERSIONS = {}

  CBHPM3a = VERSIONS[:cbhpm3a] =
    { file_basename: "CBHPM 2004 3¶ EDIÄ«O.XLS",
      edition_name: "3a",
      header_format: {
        0 => "code",
        1 => "name",
        4 => "cir_size",
        5 => "uco",
        6 => "aux_qty",
        7 => "an_size"
      },
      start_date: "01/01/2004",
      end_date: "31/12/2005" }

  CBHPM4a = VERSIONS[:cbhpm4a] =
    { file_basename: "CBHPM  4¶ EDIÄ«O.xls",
      edition_name: "4a",
      header_format: {
        0 => "code",
        1 => "name",
        4 => "cir_size",
        5 => "uco",
        6 => "aux_qty",
        7 => "an_size"
      },
      start_date: "01/01/2006",
      end_date: "31/12/2007" }

  CBHPM5a = VERSIONS[:cbhpm5a] =
    { file_basename: "CBHPM 5¶ Ediá∆o.xls",
      edition_name: "5a",
      header_format: {
        0 => "code",
        1 => "name",
        4 => "cir_size",
        5 => "uco",
        6 => "aux_qty",
        7 => "an_size"
      },
      start_date: "01/01/2008",
      end_date: "31/12/2009" }

  CBHPM2010 = VERSIONS[:cbhpm2010] =
    { file_basename: "CBHPM 2010 separada.xls",
      edition_name: "2010",
      header_format: CBHPM5a[:header_format],
      start_date: "01/01/2010",
      end_date: "31/12/2011" }

  CBHPM2012 = VERSIONS[:cbhpm2012] =
    { file_basename: "CBHPM 2012.xlsx",
      edition_name: "2012",
      header_format: {
        4 => "code",
        5 => "name",
        8 => "cir_size",
        9 => "uco",
        10 => "aux_qty",
        11 => "an_size"
      },
      start_date: "01/01/2012",
      end_date: "31/12/2013" }

  CBHPM2014 = VERSIONS[:cbhpm2014] =
    { file_basename: "CBHPM 2014.xlsx",
      edition_name: "2014",
      header_format: {
        4 => "code",
        5 => "name",
        8 => "cir_size",
        9 => "uco",
        10 => "aux_qty",
        11 => "an_size"
      },
      start_date: "01/01/2014",
      end_date: "31/12/2015" }

  CBHPM2016 = VERSIONS[:cbhpm2016] =
    { file_basename: "CBHPM 2016.xlsx",
      edition_name: "2016",
      header_format: {
        4 => "code",
        5 => "name",
        8 => "cir_size",
        9 => "uco",
        10 => "aux_qty",
        11 => "an_size"
      },
      start_date: "01/01/2016",
      end_date: "31/12/2017" }
  
  CBHPM2018 = VERSIONS[:cbhpm2018] =
    { file_basename: "CBHPM 2018.xlsx",
      edition_name: "2018",
      header_format: {
        4 => "code",
        5 => "name",
        8 => "cir_size",
        9 => "uco",
        10 => "aux_qty",
        11 => "an_size"
      },
      start_date: "01/01/2018",
      end_date: "31/12/2019" }
  
  CBHPM2020 = VERSIONS[:cbhpm2020] =
    { file_basename: "CBHPM 2020.xlsx",
      edition_name: "2020",
      header_format: {
        4 => "code",
        5 => "name",
        8 => "cir_size",
        9 => "uco",
        10 => "aux_qty",
        11 => "an_size"
      },
      start_date: "01/01/2020",
      end_date: "31/12/2021" }

  CBHPM2022 = VERSIONS[:cbhpm2022] =
    { file_basename: "CBHPM_2022_atualizado.xlsm",
      edition_name: "2022",
      header_format: {
        4 => "code",
        5 => "name",
        8 => "cir_size",
        9 => "uco",
        10 => "aux_qty",
        11 => "an_size",
        12 => "an_size"
      },
      start_date: "01/01/2022",
      end_date: "31/12/2025" }

  CBHPM2026 = VERSIONS[:cbhpm2026] =
    { file_basename: "CBHPM_2026.xlsm",
      edition_name: "2026",
      header_format: {
        4 => "code",
        5 => "name",
        8 => "cir_size",
        9 => "uco",
        10 => "aux_qty",
        11 => "an_size",
        12 => "an_size"
      },
      start_date: "01/01/2026",
      end_date: "" }
  
  VERSION_FOR_FILE = {
    "CBHPM 2004 3¶ EDIÄ«O.XLS" => CBHPM3a,
    "CBHPM  4¶ EDIÄ«O.xls" => CBHPM4a,
    "CBHPM 5¶ Ediá∆o.xls" => CBHPM5a,
    "CBHPM 2010 separada.xls" => CBHPM2010,
    "CBHPM 2012.xlsx" => CBHPM2012,
    "CBHPM 2014.xlsx" => CBHPM2014,
    "CBHPM 2016.xlsx" => CBHPM2016,
    "CBHPM 2018.xlsx" => CBHPM2018,
    "CBHPM 2020.xlsx" => CBHPM2020,
    "CBHPM_2022_atualizado.xlsm" => CBHPM2022,
    "CBHPM_2026.xlsm" => CBHPM2026,
    "cbhpm_cut_for_testing.xlsx" => CBHPM2012 }

  ROO_CLASS_FOR_EXTENSION = { ".xls" => Roo::Excel, ".xlsx" => Roo::Excelx,
                              ".xlsm" => Roo::Excelx }
end
