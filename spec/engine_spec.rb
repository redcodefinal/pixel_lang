require 'rspec'
require_relative '../lib/engine'


describe 'Engine Tests' do
  #easy tests
  it 'should run a_to_z' do
    a_to_z = Engine.new('programs/a_to_z.bmp')
    a_to_z.run
    expect(a_to_z.output).to eq (?A..?Z).to_a.join
  end

  it 'should run swap_test' do
    a_to_z = Engine.new('programs/swap_test.bmp')
    a_to_z.run
    expect(a_to_z.output).to eq "AB\nBA"
  end
end
