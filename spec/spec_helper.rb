$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'formula_eval'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end

def mylog(*args)
  yield if block_given?
  #puts args.inspect if args.first == 'enriched_doc' or args.first == 'dot_set'
end

def bt
  raise 'foo'
rescue => exp
  puts exp.message
  puts exp.backtrace.join("\n")
end

class SilentMM
  def method_missing(*args)
  end
end

class String
  def safe_to_i
     num? ? to_i : (raise 'not num')
  end
end

def debug_log(*args)
end

DEFAULT_SAFE_LEVEL = 0