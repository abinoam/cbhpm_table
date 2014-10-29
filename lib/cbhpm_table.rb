require "cbhpm_table/version"

require 'roo'

class CBHPMTable
  attr_reader :roo

  def initialize(cbhpm_path, headers_hash = nil)
    @cbhpm_path = cbhpm_path

    roo_class = ROO_CLASS_FOR_EXTENSION[File.extname(cbhpm_path)]
    @roo = roo_class.new(cbhpm_path)
    @headers_hash = headers_hash || get_headers_hash
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

  def edition_name
    version_format[:edition_name]
  end

  def version_format
    @version_format ||= get_version_format
  end

  def get_version_format
    VERSION_FOR_FILE[File.basename(cbhpm_path)]
  end

  def cbhpm_path
    @cbhpm_path
  end

  def each_row
    return to_enum(:each_row) unless block_given?
    roo_enum = roo.to_enum(:each)
    _skip_header = roo_enum.next
    loop do
      yield import_row(roo_enum.next)
    end
  end

  def headers_hash
    @headers_hash ||= get_headers_hash
  end

  def get_headers_hash
    version_format[:header_format]
  end

  def start_date
    version_format[:start_date]
  end

  def end_date
    version_format[:end_date]
  end

  private :first_row_index, :import_row, :get_version_format, :get_headers_hash
end

class CBHPMTable
  VERSIONS = {
    :cbhpm5a => CBHPM5a = {
      :file_basename => "CBHPM 5¶ Ediá∆o.xls",
      :edition_name => "5a",
      :header_format => {
        0 => "code",
        1 => "name",
        4 => "cir_size",
        5 => "uco",
        6 => "aux_qty",
        7 => "an_size"
      },
      :start_date => "01/01/2008",
      :end_date   => "31/12/2009"
    },
    :cbhpm2010 => CBHPM2010 = {
      :file_basename => "CBHPM 2010 separada.xls",
      :edition_name  => "2010",
      :header_format => {
        0 => "code",
        1 => "name",
        4 => "cir_size",
        5 => "uco",
        6 => "aux_qty",
        7 => "an_size"
      },
      :start_date => "01/01/2010",
      :end_date   => "31/12/2011"
    },
    :cbhpm2012 => CBHPM2012 = {
      :file_basename => "CBHPM 2012.xlsx",
      :edition_name => "2012",
      :header_format => {
        4 => "code",
        5 => "name",
        8 => "cir_size",
        9 => "uco",
        10 => "aux_qty",
        11 => "an_size"
      },
      :start_date => "01/01/2012",
      :end_date   => nil
    }
  }

  VERSION_FOR_FILE = {
    "CBHPM 5¶ Ediá∆o.xls" => CBHPM5a,
    "CBHPM 2010 separada.xls" => CBHPM2010,
    "CBHPM 2012.xlsx" => CBHPM2012,
    "cbhpm_cut_for_testing.xlsx" => CBHPM2012
  }

  ROO_CLASS_FOR_EXTENSION = { ".xls" => Roo::Excel, ".xlsx" => Roo::Excelx }
end
