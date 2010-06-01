require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "CalculatingCollection" do
  fattr(:row) { {'pension' => {'year' => 2025, 'perc' => 0.65}, 'salary' => 42000, 'year' => 2010} }
  fattr(:wrapped_row) { Wrapper.new(row) }
  fattr(:formula) { FormulaEval.new(:row => row) }
  fattr(:column) { 'pension.perc_plus_salary' }
  fattr(:str) { '=perc*salary' }
  fattr(:column_hash) { {column => FormulaEval.new(:formula => str)} }
  fattr(:constants_hash) { {} }
  fattr(:calc) do
    CalculatingCollection.new(:column_hash => column_hash, :constants_hash => constants_hash, 
                              :user_coll_last_calc_dt => Time.now, :coll => SilentMM.new)
  end
  fattr(:enriched) do
    calc.enriched_doc(wrapped_row)
  end
  it 'enriched' do
    enriched['pension'].should == {'year' => 2025, 'perc' => 0.65, 'perc_plus_salary' => 42000.0*0.65}
  end
  it 'enriched 2' do
    calc.column_hash['double_year'] = FormulaEval.new(:formula => '=year*2')
    enriched['double_year'].should == 4020
  end
  it 'uses sub first' do
    self.str = '=year+1'
    enriched['pension']['perc_plus_salary'].should == 2026
  end
  it 'sub array' do
    self.row['pension'] = [{'year' => 2025, 'perc' => 0.65},{'year' => 2026, 'perc' => 0.7}]
    enriched['pension'][0]['perc_plus_salary'].should == 42000.0*0.65
  end
  it 'reverse uniq' do
    a = [1,2,3,4,5,2,7]
    a.reverse.uniq.reverse.should == [1,3,4,5,2,7]
  end
  it 'saving' do
    calc.save(row)
    row['pension']['perc_plus_salary'].should == 42000*0.65
  end
  describe 'constants' do
    before do
      self.row['pension'] = [{'year' => 2025, 'perc' => 0.65},{'year' => 2026, 'perc' => 0.7}]
    end
    it 'sub level' do
      self.constants_hash = {'pension.one_five' => [1,2,3,4,5]}
      calc.save(row)
      row['pension'][0]['one_five'].should == 1
      row['pension'].size.should == 5
      row['pension'][3]['one_five'].should == 4
    end
    it 'top level' do
      self.constants_hash = {'one_five' => [1,2,3,4,5]}
      calc.save(row,{},:row_index => 2)
      row['one_five'].should == 3
    end
  end
  describe 'safe_eval' do
    it 'shellout' do
      SafeEval.with_level(4) do
        self.str = "=`rm -r -f /code/fghgfhrthyhthyht`; perc*salary"
        lambda { enriched }.should raise_error(SecurityError)
      end
    end
    # it 'change' do
    #   self.str = "=self.year = 42; perc*salary"
    #   #lambda { enriched }.should raise_error(SecurityError)
    #   raise enriched.inspect
    # end
  end
  
end
