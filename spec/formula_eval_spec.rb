require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class A
  def a
    1
  end
  def [](k)
    #puts "sending #{k} to #{self}"
    send(k)
  end
end

class B
  def b
    2
  end
  def [](k)
    #puts "sending #{k} to #{self}"
    send(k)
  end
end

class C
  def c
    3
  end
  def c_array
    [{'d' => 4, 'e' => 5},{'d' => 6, 'e' => 7}]
  end
  def c_hash
    {'d' => 4, 'e' => 5}
  end
  def [](k)
    send(k)
  end
end

describe "FormulaEval" do
  fattr(:str) { '=2+2' }
  fattr(:row) { {'year' => 2010} }
  fattr(:formula) { FormulaEval.new(:row => row, :formula => str) }
  it '2+2' do
    formula.result.should == 4
  end
  it 'double_year' do
    self.str = '=year*2'
    formula.result.should == 4020
  end
  it 'double' do
    self.row = MultiEval.new(:objs => [A.new,B.new])
    self.str = '=a+b'
    formula.result.should == 3
  end
  it 'double 2' do
    hash = {'year' => 2010, 'pension' => {'start_year' => 2025, 'perc' => 0.65}}
    self.row = MultiEval.get_nested(Wrapper.new(hash),'pension')
    self.str = '=perc*year + perc*year'
    formula.result.should == 0.65 * 2010 * 2
  end
  it 'with hash' do
    self.row = {'year' => 2010, 'pension' => {'start_year' => 2025, 'perc' => 0.65}}
    self.str = '=year'
    formula.result.should == 2010
  end
  it 'nested with array' do
    self.row = MultiEval.get_nested(C.new,'c_array._arrayindex_0')
    row.objs[0].obj.should == {'d' => 4, 'e' => 5}
  end
  it 'nested with array 2' do
    MultiEval.fix_str('c_array.0').should == 'c_array._arrayindex_0'
    MultiEval.fix_str('c_array.0.d').should == 'c_array._arrayindex_0.d'
  end
  it 'nested with array 3' do
    self.row = MultiEval.get_nested(C.new,'c_array.0')
    row.objs[0].obj.should == {'d' => 4, 'e' => 5}
    self.str = '=c+c_array.0.d'
    formula.result.should == 7
  end
  it 'nested with array 4' do
    self.row = MultiEval.get_nested(C.new,'c_array.0')
    self.str = '=c+d'
    formula.result.should == 7
  end
  it 'nested with array 5' do
    self.row = MultiEval.get_nested(C.new,'c_array.1')
    self.str = '=c+d'
    formula.result.should == 9
  end
  it 'nested with array' do
    self.row = MultiEval.get_nested(C.new,'c_array._arrayindex_0')
    #raise row.objs.inspect
    self.str = '=c+d'
    formula.result.should == 7
  end
  # it 'double 3' do
  #   hash = {'year' => 2010, 'pension' => [{'start_year' => 2025, 'perc' => 0.65},{'start_year' => 2026, 'perc' => 0.7}]}
  #   self.row = MultiEval.get_nested(Wrapper.new(hash),'pension')
  # end
end
