require "cbhpm_table/version"

require 'roo'

class CBHPMTable
  attr_reader :roo, :headers_hash, :edition_name

  def initialize(cbhpm_path, headers_hash = nil)
    cbhpm_file_extension = File.extname(cbhpm_path)
    cbhpm_file_basename  = File.basename(cbhpm_path)

    @edition_name = EDITION_NAME_FOR_FILE[cbhpm_file_basename]

    roo_class = ROO_CLASS_FOR_EXTENSION[cbhpm_file_extension]
    @roo = roo_class.new(cbhpm_path)
    @headers_hash = headers_hash || HEADER_FOR_FILE[cbhpm_file_basename]
    raise "Can't find predefined headers for #{cbhpm_path}" unless @headers_hash
  end

  def headers
    row(first_row_index)
  end

  def first_row_index
    roo.first_row
  end

  def row(row_index)
    import_row(roo.row(row_index))
  end

  def import_row(row_array)
    imported_row = Hash.new

    headers_hash.each do |col, name|
      imported_row[name] = row_array[col]
    end

    imported_row
  end

  def rows
    each_row.to_a
  end

  def each_row
    return to_enum(:each_row) unless block_given?
    roo_enum = roo.to_enum(:each)
    _skip_header = roo_enum.next
    loop do
      yield import_row(roo_enum.next)
    end
  end

  private :first_row_index, :import_row
end

class CBHPMTable
  module HeaderFormat
    CBHPM5a =
      { 0 => "code",
        1 => "name",
        4 => "cir_size",
        5 => "uco",
        6 => "aux_qty",
        7 => "an_size" }

    CBHPM2010 =
      { 0 => "code",
        1 => "name",
        4 => "cir_size",
        5 => "uco",
        6 => "aux_qty",
        7 => "an_size" }

    CBHPM2012 =
      { 4 => "code",
        5 => "name",
        8 => "cir_size",
        9 => "uco",
        10 => "aux_qty",
        11 => "an_size" }
  end

  HEADER_FOR_FILE =
    { "CBHPM 5¶ Ediá∆o.xls" => HeaderFormat::CBHPM5a,
      "CBHPM 2010 separada.xls" => HeaderFormat::CBHPM2010,
      "CBHPM 2012.xlsx" => HeaderFormat::CBHPM2012,
      "cbhpm_cut_for_testing.xlsx" => HeaderFormat::CBHPM2012 }

  EDITION_NAME_FOR_FILE =
    { "CBHPM 5¶ Ediá∆o.xls" => "5a",
      "CBHPM 2010 separada.xls" => "2010",
      "CBHPM 2012.xlsx" => "2012",
      "cbhpm_cut_for_testing.xlsx" => "2012" }

  ROO_CLASS_FOR_EXTENSION = { ".xls" => Roo::Excel, ".xlsx" => Roo::Excelx }
end
