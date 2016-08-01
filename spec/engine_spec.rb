require 'rspec'
require_relative '../lib/engine'


describe 'Engine Tests' do
  it 'should run a_to_z' do
    a_to_z = Engine.new('programs/simple_examples/a_to_z.bmp')
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

  it 'should run is_prime' do
    engine = Engine.new 'programs/math/is_prime.bmp', "5"
    engine.run
    expect(engine.output).to eq "T"

    engine = Engine.new 'programs/math/is_prime.bmp', "11"
    engine.run
    expect(engine.output).to eq "T"

    engine = Engine.new 'programs/math/is_prime.bmp', "10"
    engine.run
    expect(engine.output).to eq "F"

    engine = Engine.new 'programs/math/is_prime.bmp', "13195"
    engine.run
    expect(engine.output).to eq "F"

    engine = Engine.new 'programs/math/is_prime.bmp', "541"
    engine.run
    expect(engine.output).to eq "T"
  end

  it 'should run factorial' do
    engine = Engine.new 'programs/math/factorial.bmp', "5"
    engine.run
    expect(engine.output).to eq "120"

    engine = Engine.new 'programs/math/factorial.bmp', "6"
    engine.run
    expect(engine.output).to eq "720"

    engine = Engine.new 'programs/math/factorial.bmp', "7"
    engine.run
    expect(engine.output).to eq "5040"
  end

  it 'should run fibonacci' do
    engine = Engine.new 'programs/math/fibonacci.bmp', "9"
    engine.run
    expect(engine.output).to eq "1 1 2 3 5 8 13 21 34 55 89"
  end

  it 'should run sum_of_divisors_of_3' do
    engine = Engine.new 'programs/project_euler/1/sketches/sum_of_divisors_of_3.bmp'
    engine.run
    expect(engine.output).to eq "166833"
  end

  it 'should run sum_of_divisors_of_5_not_3' do
    engine = Engine.new 'programs/project_euler/1/sketches/sum_of_divisors_of_5_not_3.bmp'
    engine.run
    expect(engine.memory[0]).to eq 66335
  end

  it 'should run project_euler 1' do
    engine = Engine.new 'programs/project_euler/1/solution.bmp'
    engine.run
    expect(engine.memory[0]).to eq 233168
    expect(engine.output).to eq "233168"
  end

  it 'should run project_euler 2' do
    max = 10
    engine = Engine.new 'programs/project_euler/2/solution.bmp', max.to_s
    engine.run

    expect(engine.memory[max]).to eq 10
    expect(engine.output).to eq "10"

    max = 100
    engine = Engine.new 'programs/project_euler/2/solution.bmp', max.to_s
    engine.run

    expect(engine.memory[max]).to eq 44
    expect(engine.output).to eq "44"

    max = 3000
    engine = Engine.new 'programs/project_euler/2/solution.bmp', max.to_s
    engine.run

    expect(engine.memory[max]).to eq 3382
    expect(engine.output).to eq "3382"
  end

  it 'should run project_euler 3' do
    engine = Engine.new 'programs/project_euler/3/solution.bmp', "13195"
    engine.run
    expect(engine.memory[13195]).to eq 29
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
