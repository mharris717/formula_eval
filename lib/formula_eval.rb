require 'mharris_ext'
require 'active_support'

class Object
  attr_accessor :calculating_formula
end


  

class FormulaEval
  attr_accessor :row, :formula, :row_index, :rows
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
      super
    end
  ensure
    # puts "Formula mm #{sym} #{args.inspect} #{res.inspect}"
  end
  def safe_eval_result
    instance_eval(formula).to_unwrapped
  # rescue => exp
  #   t = exp.backtrace.join("\n").gsub("/Users/mharris/.rvm/gems/ruby-1.9.1-p378/gems","gems").gsub("/Users/mharris/Code/smartlist/vendor/mongo_ui","mongo_ui")
  #   t = t.gsub("/Users/mharris/Code/smartlist","smartlist")
  #   mylog "formula_eval", :formula => formula, :row => row, :message => exp.message, :trace => t
  #   "Error #{exp.message}"
  rescue => exp
    # puts "error evaling #{formula} against #{row.inspect}, #{exp.message}"
    raise exp
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

load File.dirname(__FILE__) + "/formula_eval/wrapper.rb"
load File.dirname(__FILE__) + "/formula_eval/calculating_collection.rb"
load File.dirname(__FILE__) + "/formula_eval/multi_eval.rb"

def mylog(*args)
  yield if block_given?
  #puts args.inspect if args.first == 'enriched_doc' or args.first == 'dot_set'
end

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

class Object
  def dot_get(str)
    str = str.split(".") if str.is_a?(String)
    res = self
    last_f = last_res = nil
    str.each do |f|
      if f.num? && !res.kind_of?(Array)
        last_res[last_f] = res = []
      end
      last_res = res
      if res.kind_of?(Array)
        temp = res[f.safe_to_i]
        if !temp
          res << {}
          temp = res.last
          raise "can only add new row at end" unless res.size-1 == f.safe_to_i
        end
        res = temp
      else
        res = res[f]
      end
      last_f = f
    end
    res
  end
  def dot_set(str,val)
    mylog 'dot_set', :str => str, :val => val, :self => self do
      return self[str] = val if str.split(".").size == 1
      strs = str.split(".")[0..-2]
      lst = str.split(".")[-1]
      obj = dot_get(strs)
      return obj unless obj
      #puts "dot_set, obj is #{obj.inspect}, str is #{str}, val is #{val}, lst is #{lst}"
      obj.nested_set(lst,val)
    end
  end
end

class Object
  def nested_set(k,v)
    self[k] = v
  end
end

class Array
  def nested_set(k,v)
    mylog 'dot_set', :context => 'nested', :klass => klass, :self => self, :k => k, :v => v do
      each { |x| x.nested_set(k,v) } 
    end
  end
end

class String
  def num?
    size > 0 && self =~ /^[\d\.]*$/
  end
  def date?
    matches = (self =~ /\/\d+\//) || (self =~ /-\d+-/)
    matches2 = self =~ /^[ \d\-\/:]+$/
    !!(matches && matches2 && Time.parse(self))
  rescue
    return false
  end
  def to_time
    Time.parse(self)
  end
  def tmo
    if num? 
      to_f.tmo 
    elsif blank?
      nil
    else
      self
    end
  end
end