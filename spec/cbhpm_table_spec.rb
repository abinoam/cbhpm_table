# coding: utf-8

require 'rspec'
require 'cbhpm_table'

describe CBHPMTable do
  let(:cbhpm_table) { CBHPMTable.new("spec/cbhpm/cbhpm_cut_for_testing.xlsx") }

  it { expect(cbhpm_table).to respond_to(:headers) }

  describe "#headers_hash - the format hash for headers" do
    it do
      header_format = CBHPMTable::CBHPM2012[:header_format]
      expect(cbhpm_table.headers_hash).to eq header_format
    end
  end

  describe "#headers - the first line of the CBHPM Table" do
    it { expect(cbhpm_table.headers).to be_instance_of(Hash) }
    it do
      expect(cbhpm_table.headers).to eq("code" => "ID do Procedimento",
                                        "name" => "Descrição do Procedimento",
                                        "cir_size" => nil,
                                        "uco" => "Custo Operac.",
                                        "aux_qty" => "Nº de Aux.",
                                        "an_size" => "Porte Anestés.")
    end
  end

  describe "#row - any row" do
    let(:row) { cbhpm_table.row(2) }

    it { expect(row).to be_instance_of(Hash) }
    it do
      expect(row).to eq(
        "code" => "10101012",
        "name" => "Em consultório (no horário normal ou preestabelecido)",
        "cir_size" => "2B",
        "uco" => nil,
        "aux_qty" => nil,
        "an_size" => nil)
    end
  end

  describe "#each_row" do
    describe "returns an Enumerator when no block given" do
      it { expect(cbhpm_table.each_row).to be_instance_of Enumerator }
    end

    describe "iterates through each row" do
      specify do
        cbhpm_table.each_row do |row|
          expect(row).to be_instance_of Hash
          expect(row['code']).to match(/\d{8}/)
        end
      end
    end
  end

  describe "#rows" do
    let(:rows) { cbhpm_table.rows }

    it { expect(rows).to be_instance_of Array }

    describe ".first" do
      it { expect(rows.first).to be_instance_of Hash }
    end
  end

  describe "#edition_name" do
    it { expect(cbhpm_table.edition_name).to eq "2012" }
  end

  describe "#version_format" do
    it { expect(cbhpm_table.version_format).to be_instance_of Hash }
    it "should return proper Hash with :edition_name key" do
      expect(cbhpm_table.version_format[:edition_name]).to eq "2012"
    end
  end

  describe "#cbhpm_path" do
    it "should return the cbhpm initialization path" do
      expect(cbhpm_table.cbhpm_path).to eq(
        "spec/cbhpm/cbhpm_cut_for_testing.xlsx")
    end
  end

  describe "#start_date" do
    it "should return proper start_date for cbhpm version" do
      expect(cbhpm_table.start_date).to eq "01/01/2012"
    end
  end

  describe "#end_date" do
    it "should return proper end_date for cbhpm version" do
      expect(cbhpm_table.end_date).to eq "31/12/2013"
    end
  end

  describe "normalization of mixed cell types" do
    let(:header_format) do
      CBHPMTable::CBHPM2026[:header_format]
    end
    let(:table) do
      CBHPMTable.new("spec/cbhpm/cbhpm_cut_for_testing.xlsx", header_format)
    end

    def raw_row(values)
      Array.new(13).tap do |row|
        { "code" => 4, "name" => 5, "cir_size" => 8, "uco" => 9,
          "aux_qty" => 10, "an_size" => 11, "new_an_size" => 12 }
          .each { |name, col| row[col] = values[name] }
      end
    end

    def import(values)
      table.send(:import_row, raw_row(values))
    end

    it "converts numeric codes to String" do
      expect(import("code" => 40901688)["code"]).to eq "40901688"
      expect(import("code" => 40901688.0)["code"]).to eq "40901688"
    end

    it "removes the punctuation of 8 digit codes" do
      expect(import("code" => "4.02.01.02-3")["code"]).to eq "40201023"
      expect(import("code" => "3110428-2")["code"]).to eq "31104282"
      expect(import("code" => "330735114")["code"]).to eq "330735114"
    end

    it "squeezes whitespace in names" do
      name = " Ablação de alvos\nintracerebrais  "
      expect(import("name" => name)["name"]).to eq "Ablação de alvos intracerebrais"
    end

    it "converts uco to Float, accepting decimal comma" do
      expect(import("uco" => "0,750")["uco"]).to eq 0.75
      expect(import("uco" => 7.39)["uco"]).to eq 7.39
    end

    it "converts portes and aux_qty to Integer, keeping zero" do
      expect(import("an_size" => "5")["an_size"]).to eq 5
      expect(import("an_size" => 5)["an_size"]).to eq 5
      expect(import("an_size" => "0")["an_size"]).to eq 0
      expect(import("aux_qty" => 2.0)["aux_qty"]).to eq 2
    end

    it "turns blank strings into nil" do
      row = import("cir_size" => "", "uco" => "  ", "an_size" => " ")
      expect(row.values_at("cir_size", "uco", "an_size")).to eq [nil, nil, nil]
    end

    it "keeps unparseable values as String" do
      expect(import("aux_qty" => "2A")["aux_qty"]).to eq "2A"
    end

    describe "anesthetic size resolution" do
      it "prefers the new an_size" do
        expect(import("an_size" => 3, "new_an_size" => 5)["an_size"]).to eq 5
      end

      it "accepts zero as a valid new an_size" do
        expect(import("an_size" => 2, "new_an_size" => 0)["an_size"]).to eq 0
      end

      it "falls back to the old an_size when the new one is blank" do
        expect(import("an_size" => "3", "new_an_size" => nil)["an_size"]).to eq 3
        expect(import("an_size" => "3", "new_an_size" => "")["an_size"]).to eq 3
      end

      it "does not expose new_an_size" do
        expect(import("new_an_size" => 4)).not_to have_key("new_an_size")
      end
    end
  end

  describe "duplicated codes and rows without code" do
    let(:roo) { instance_double(Roo::Excelx) }

    before do
      allow(Roo::Excelx).to receive(:new).and_return(roo)
      allow(roo).to receive(:each).and_yield([])
        .and_yield(row_array(10101012, "Primeira "))
        .and_yield(row_array("10101020", "Outra"))
        .and_yield(row_array(nil, ""))
        .and_yield(row_array(" ", nil))
        .and_yield(row_array("10101012", "Primeira"))
    end

    def row_array(code, name)
      Array.new(12).tap { |row| row[4] = code; row[5] = name }
    end

    it "keeps only the last row read for each code, discarding rows without code" do
      expect(cbhpm_table.rows.map { |r| r.values_at("code", "name") }).to eq(
        [%w[10101012 Primeira], %w[10101020 Outra]])
    end
  end

  %w[CBHPM_2022_atualizado.xlsm CBHPM_2026.xlsm].each do |basename|
    describe "original spreadsheet #{basename}" do
      path = File.join("planilhas", basename)
      before { skip "#{path} not available" unless File.exist?(path) }

      let(:table) { CBHPMTable.new(path) }
      let(:rows_by_code) { table.rows.to_h { |row| [row["code"], row] } }

      it "is detected by its basename" do
        expect(table.edition_name).to eq basename[/\d{4}/]
      end

      it "returns every code as an 8 digit String" do
        expect(rows_by_code.keys).to all(match(/\A\d{8}\z/))
      end

      it "returns no duplicated codes" do
        expect(table.rows.size).to eq rows_by_code.size
      end

      it "applies the new anesthetic size" do
        expect(rows_by_code["40202798"]["an_size"]).to eq 5
        expect(rows_by_code["40201015"]["an_size"]).to eq 0
      end
    end
  end
end
