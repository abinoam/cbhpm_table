require 'rspec'
require 'cbhpm_table'

describe CBHPMTable do
  let(:cbhpm_table) do
    CBHPMTable.new("spec/cbhpm/cbhpm_cut_for_testing.xlsx",
                   CBHPMTable::CBHPM2012[:header_format])
  end

  it { expect(cbhpm_table).to respond_to(:headers) }

  describe "#headers_hash - the format hash for headers" do
    it { expect(cbhpm_table.headers_hash).to eq CBHPMTable::CBHPM2012[:header_format] }
  end

  describe "#headers - the first line of the CBHPM Table" do
    it { expect(cbhpm_table.headers).to be_instance_of(Hash) }
    it { expect(cbhpm_table.headers).to eq({ "code"=>"ID do Procedimento",
                                        "name"=>"Descrição do Procedimento",
                                        "cir_size"=>nil,
                                        "uco"=>"Custo Operac.",
                                        "aux_qty"=>"Nº de Aux.",
                                        "an_size"=>"Porte Anestés."}) }
  end

  describe "#row - any row" do
    let(:row) { cbhpm_table.row(2) }

    it { expect(row).to be_instance_of(Hash) }
    it { expect(row).to eq({"code"=>"10101012",
                            "name"=>"Em consultório (no horário normal ou preestabelecido)",
                            "cir_size"=>"2B",
                            "uco"=>nil,
                            "aux_qty"=>nil,
                            "an_size"=>nil})}
  end

  describe "#each_row" do
    describe "returns an Enumerator when no block given" do
      it { expect(cbhpm_table.each_row).to be_instance_of Enumerator }
    end

    describe "iterates through each row" do
      specify do
        cbhpm_table.each_row do |row|
          expect(row).to be_instance_of Hash
          expect(row['code']).to match /\d{8}/
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
end

