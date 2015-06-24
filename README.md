[![Gem Version](https://badge.fury.io/rb/cbhpm_table.svg)](http://badge.fury.io/rb/cbhpm_table)

# CBHPMTable

A simple gem to wrap the CBHPM excel files from Associação Brasileira de Medicina.

**CBHPM**:

* Classificação Brasileira Hierarquizada de Procedimentos Médicos (pt)
* Brazilian Hierarchical Classification of Medical Procedures (en)

## Installation

Add this line to your application's Gemfile:

    gem 'cbhpm_table'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cbhpm_table

## Usage

```ruby
cbhpm_table = CBHPMTable.new "CBHPM 2012.xlsx"

cbhpm_table.headers
  #=> { "code"=>"ID do Procedimento", "name"=>"Descrição do Procedimento", "cir_size"=>nil, "uco"=>"Custo Operac.", "aux_qty"=>"Nº de Aux.", "an_size"=>"Porte Anestés."}

cbhpm_table.row(2)
  #=> {"code"=>"10101012", "name"=>"Em consultório (no horário normal ou preestabelecido)", "cir_size"=>"2B", "uco"=>nil, "aux_qty"=>nil, "an_size"=>nil})}

cbhpm_table.rows
  #=> # Returns an Array of Rows (as individual Hashes)

cbhpm_table.each_row do |row|
  # do whatever with the row
end
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cbhpm_table/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Thanks to:

* Brandon Hilkert (@brandonhilkert) - for his "Build a Ruby Gem Email Course"
