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