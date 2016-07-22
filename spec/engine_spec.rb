require 'rspec'
require_relative '../lib/engine'


describe 'Engine Tests' do
  it 'should run a_to_z' do
    a_to_z = Engine.new('programs/a_to_z.bmp')
    a_to_z.run_one_instruction
    a_to_z.run_one_instruction
    a_to_z.run_one_instruction
    expect(a_to_z.pistons.first.instance_variable_get("@i").last).to eq 0x5A
    expect(a_to_z.pistons.first.instance_variable_get("@i").first).to eq 0x41
    a_to_z.run_one_instruction
    expect(a_to_z.pistons.first.instance_variable_get("@i").first).to eq 0x41
    expect(a_to_z.pistons.first.mbv).to eq 0x5A
    a_to_z.run_one_instruction
    expect(a_to_z.pistons.first.mav).to eq 0x41
    a_to_z.run_one_instruction
    a_to_z.run_one_instruction
    expect(a_to_z.output).to eq "A"
    a_to_z.run_one_instruction
    expect(a_to_z.pistons.first.mav).to eq 0x42
    a_to_z.run_one_instruction
    a_to_z.run_one_instruction
    a_to_z.run_one_instruction
    a_to_z.run_one_instruction
    a_to_z.run_one_instruction
    expect(a_to_z.output).to eq "AB"

    a_to_z.run
    expect(a_to_z.output).to eq "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  end

  it 'should run fibonacci' do
    engine = Engine.new 'programs/fibonacci.bmp', "9"
    engine.run
    expect(engine.output).to eq "1 1 2 3 5 8 13 21 34 55 89"
  end

  #easy tests
  it 'should run int_overflow_test' do
    engine = Engine.new 'programs/tests/int_overflow_test.bmp'
    engine.run_one_instruction
    engine.run_one_instruction
    engine.run_one_instruction
    engine.run_one_instruction
    engine.run_one_instruction
    expect(engine.pistons.first.mav).to eq 0
    expect(engine.pistons.first.mbv).to eq 0xFFFFF
  end


  it 'should run swap_test' do
    swap_test = Engine.new('programs/tests/swap_test.bmp')
    swap_test.run
    expect(swap_test.output).to eq "AB\nBA"
  end

  it "should run ma_mav_test" do
    engine = Engine.new('programs/tests/ma_mav_test.bmp')
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
    engine = Engine.new('programs/tests/mb_mbv_test.bmp')
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
