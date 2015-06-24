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
      expect(cbhpm_table.end_date).to eq nil
    end
  end
end
