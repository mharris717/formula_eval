class MultiEval
  attr_accessor :objs
  include FromHash
  def methodf_missing(sym,*args,&b)
    # puts "multi_eval mm #{sym}"
    objs.each do |obj|
      begin
        res = obj.send(sym,*args,&b)
        if res
          #other = objs - [obj]
          # puts "success sending #{sym} to #{obj}"
          return MultiEval.new(:objs => [res])
        end
      rescue => exp
        # puts "error sending #{sym} to #{obj} #{exp.message}"
      end
    end
    objs.first.send(sym,*args,&b)
  end
  def without_obj(obj)
    res = objs.reject { |x| x == obj }
    raise "didn't find" unless objs.size == res.size+1
    res
  rescue => exp
    puts "#{objs.inspect} #{obj.inspect}"
    raise exp
  end
  def method_missing(sym,*args,&b)
    objs.each do |obj|
      if obj.smart_respond_to?(sym,args)
        res = obj.send(sym,*args,&b)
        #return MultiEval.new(:objs => [res]+without_obj(obj)) #if res
        return res if res
      end
    end
    raise 'none respond'
    objs.first.send(sym,*args,&b)
  end
  def respond_to?(sym)
    objs.any? { |x| x.respond_to?(sym) }
  end
  def coerce(x)
    objs.first.coerce(x)
  end
  def +(x)
    objs.first + x
  end
  def *(x)
    objs.first * x
  end
  def self.get_nested(obj,method_str)
    method_str = fix_str(method_str)
    other = obj.to_wrapped.safe_instance_eval(method_str)
    mylog 'get_nested', :obj => obj, :method_str => method_str, :other => other
    arr = [other,obj]
    new(:objs => arr)
  end
  def to_unwrapped
    objs.first.to_unwrapped
  end
  def self.fix_str(str)
    str.gsub(/\.(\d+)\./) { "._arrayindex_#{$1}." }.gsub(/\.(\d+)$/) { "._arrayindex_#{$1}" }
  end
end

class Object
  def smart_respond_to?(k,args)
    sup = respond_to?(k)
    if k.to_s == '[]'
      return false if args.first.kind_of?(Numeric) && kind_of?(Hash)
      return false if !args.first.kind_of?(Numeric) && kind_of?(Array)
      return false if !args.first.kind_of?(Numeric) && kind_of?(Numeric)
      return false if !args.first.kind_of?(Numeric) && kind_of?(String)
      sup
    else
      sup
    end
  end
end