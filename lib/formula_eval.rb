require 'mharris_ext'
require 'safe_eval'

class Object
  attr_accessor :calculating_formula
end

class WrappingProxy
  attr_accessor :obj
  include FromHash
  def method_missing(sym,*args,&b)
    WrappingProxy.new(:obj => obj.send(sym,*args,&b).to_wrapped)
  end
  def respond_to?(x)
    obj.respond_to?(x)
  end
  def kind_of?(x)
    obj.kind_of?(x)
  end
end

class FormulaEval
  attr_accessor :row, :formula, :row_index, :rows, :coll
  include FromHash
  def current_user
    $current_user
  end
  def wrapped_row
    Wrapper.new(row)
  end
  def method_missing(sym,*args,&b)
    res = 'errored'
    res = if row.respond_to?(sym)
      wrapped_row.send(sym,*args,&b)
    elsif row.respond_to?('[]')
      wrapped_row[sym.to_s]
    else
      puts "mm #{sym} #{args.inspect}"
      super
    end
  ensure
    # puts "Formula mm #{sym} #{args.inspect} #{res.inspect}"
  end
  def fixed_formula
    MultiEval.fix_str(formula)
  end
  def safe_eval_result
    safe_instance_eval(fixed_formula).to_unwrapped
  rescue => exp
     t = exp.backtrace.join("\n").gsub("/Users/mharris/.rvm/gems/ruby-1.9.1-p378/gems","gems").gsub("/Users/mharris/Code/smartlist/vendor/mongo_ui","mongo_ui")
     t = t.gsub("/Users/mharris/Code/smartlist","smartlist")
     mylog "formula_eval", :formula => formula, :row => row, :message => exp.message, :trace => t
     "Error #{exp.message}"
  #rescue => exp
    # puts "error evaling #{formula} against #{row.inspect}, #{exp.message}"
    #raise exp
  end
  def result
    self.formula = formula[1..-1] if formula[0..0] == '='
    res = safe_eval_result
    eat_exceptions { res.calculating_formula = formula }
    res
  end
  def call(row)
    self.row = row
    result
  end
end

class FormulaEval
  def next_row
    res = rows[row_index+1] || {}
    HashWrapper.new(:hash => res)
  end
  def prev_row_inner
    return {} if row_index == 0
    rows[row_index-1] || {}
  end
  def prev_row
    HashWrapper.new(:hash => prev_row_inner)
  end
end



class FormulaEval
  def self.load_subfiles!
    load File.dirname(__FILE__) + "/formula_eval/wrapper.rb"
    load File.dirname(__FILE__) + "/formula_eval/calculating_collection.rb"
    load File.dirname(__FILE__) + "/formula_eval/multi_eval.rb"
  end
  def self.load_self!
    load File.dirname(__FILE__) + "/formula_eval.rb"
  end
  def self.load_files!
    load_subfiles!
    load_self!
  end
end

FormulaEval.load_subfiles!
require 'nested_hash_tricks'


class Object
  def klass
    self.class
  end
end

class Object
  def blank?
    to_s.strip == ''
  end
  def present?
    !blank?
  end
end

