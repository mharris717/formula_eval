# class Wrapper
#   attr_accessor :obj
#   include FromHash
#   def method_missing(sym,*args,&b)
#     obj.send(sym,*args,&b).to_wrapped
#   end
# end

class Wrapper
  def respond_to?(sym)
    obj.respond_to?(sym)
  end
end

class HashWrapper 
  attr_accessor :hash
  include FromHash
  def method_missing(sym,*args,&b)
    if obj.keys.include?(sym.to_s)
      self[sym.to_s]
    else
      super
    end
  end
  def [](x)
    raise 'dot_set' if x.to_s == 'dot_set'
    res = hash[x.to_s]
    res = nil if res.blank?
    # raise "nil key #{x}" unless res
    res.to_wrapped
  end
  def []=(k,v)
    obj[k.to_s] = v
  end
  def obj; hash; end
  def to_wrapped
    self
  end
  def to_unwrapped
    hash.to_unwrapped
  end
  def respond_to?(sym)
    obj.keys.include?(sym.to_s)
  end
  def delete(k)
    obj.delete(k)
  end
  def kind_of?(x)
    return true if x == Hash
    super
  end
  def keys
    obj.keys
  end
end

class Array
  def contains_all_hashes?
    all? { |x| x.kind_of?(Hash) || x.kind_of?(OrderedHash) }
  end
end

class Array
  def method_missing(sym,*args,&b)
    if sym.to_s =~ /_arrayindex_(\d+)/
      self[$1.to_i].to_wrapped
    else
      super
    end 
  end
end

module ArrayMod
  def [](i)
    raise "tried to pass string #{i} to array [] #{inspect}" unless i.kind_of?(Fixnum)
    super
  end
end

Array.send(:include,ArrayMod)

class ArrayWrapper
  attr_accessor :obj
  include FromHash
  def hash_mm(sym)
    map { |h| h[sym.to_s] }.select { |x| x }.flatten.to_wrapped
  end
  def method_missing(sym,*args,&b)
    res = if obj.respond_to?(sym)
      obj.send(sym,*args,&b).to_wrapped
    elsif sym.to_s =~ /_arrayindex_(\d+)/
      self[$1.to_i]
    elsif obj.contains_all_hashes?
      hash_mm(sym)
    else
      obj.send(sym,*args,&b).to_wrapped
    end
    res
  end
  def [](i)
    raise "tried to pass string #{i} to array [] #{inspect}" unless i.kind_of?(Fixnum)
    obj[i].to_wrapped
  end
  def *(arg)
    map { |x| x * arg }
  end
  def to_wrapped
    self
  end
  def to_unwrapped
    obj.to_unwrapped
  end
  def kind_of?(x)
    return true if x == Array
    super
  end
end

class Array
  def to_unwrapped
    map { |x| x.to_unwrapped } 
  end
end

class Hash
  def to_unwrapped
    map_value { |v| v.to_unwrapped }
  end
end

class Wrapper
  def self.new_inner(obj)
    if obj.kind_of?(Array)
      ArrayWrapper.new(:obj => obj)
    elsif obj.kind_of?(Hash)
      HashWrapper.new(:hash => obj)
    else
      obj
    end
  end
  def self.new(obj)
    new_inner(obj).tap { |x| mylog 'wrapper', :obj => obj, :wrapper_class => x.class }
  end
  def self.wrapped?(obj)
    [ArrayWrapper,HashWrapper].any? { |cls| obj.kind_of?(cls) }
  end
end

class Object
  def to_wrapped
    Wrapper.new(self)
  end
  def to_unwrapped_inner
    if Wrapper.wrapped?(self)
      obj.to_unwrapped
    else
      self
    end
  end
  def to_unwrapped
    to_unwrapped_inner.tap { |x| mylog 'unwrap', :klass => self.klass, :unwrapped => x.class }
  end
end