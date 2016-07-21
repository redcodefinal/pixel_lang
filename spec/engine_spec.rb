require 'rspec'
require_relative '../lib/engine'


describe 'Engine Tests' do
  #easy tests
  it 'should run swap_test' do
    a_to_z = Engine.new('programs/swap_test.bmp')
    a_to_z.run
    expect(a_to_z.output).to eq "AB\nBA"
  end

  it "should run ma_mav_test" do
    engine = Engine.new('programs/ma_mav_test.bmp')
    engine.run_one_instruction
    engine.run_one_instruction
    expect(engine.pistons.first.instance_variable_get("@i").first).to eq 0x100
    engine.run_one_instruction
    expect(engine.pistons.first.mav).to eq 0x100
    engine.run_one_instruction
    expect(engine.pistons.first.ma).to eq 0x100
    expect(engine.pistons.first.mav).to eq 0
    engine.run_one_instruction
    expect(engine.pistons.first.instance_variable_get("@i").first).to eq 0x200
    engine.run_one_instruction
    expect(engine.pistons.first.mav).to eq 0x200
    engine.run_one_instruction
    expect(engine.ended?)
  end

  it "should run mb_mbv_test" do
    engine = Engine.new('programs/mb_mbv_test.bmp')
    engine.run_one_instruction
    engine.run_one_instruction
    expect(engine.pistons.first.instance_variable_get("@i").first).to eq 0x100
    engine.run_one_instruction
    expect(engine.pistons.first.mbv).to eq 0x100
    engine.run_one_instruction
    expect(engine.pistons.first.mb).to eq 0x100
    expect(engine.pistons.first.mbv).to eq 0
    engine.run_one_instruction
    expect(engine.pistons.first.instance_variable_get("@i").first).to eq 0x200
    engine.run_one_instruction
    expect(engine.pistons.first.mbv).to eq 0x200
    engine.run_one_instruction
    expect(engine.ended?)
  end
end
