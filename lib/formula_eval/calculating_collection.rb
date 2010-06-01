

class Hash
  def each_with_str_key
    each do |k,v|
      yield(k.to_s,v)
    end 
  end
  def nested_hash_set(*args)
    args = args.flatten
    KeyParts.with_parts(args[0..-2],:array => true) do |start,lst,mult|
      start.each { |k| self[k] ||= {} }
      self[lst] = args[-1]
    end
  end
end

class WrappingCollection
  attr_accessor :coll
  include FromHash
  def method_missing(sym,*args,&b)
    coll.send(sym,*args,&b)
  end
  def user_coll
    coll.user_coll
  end
  fattr(:user_coll_last_calc_dt) do
    user_coll.save! unless user_coll.last_calc_dt
    user_coll.last_calc_dt
  end
end

class CalculatingCollection < WrappingCollection
  fattr(:column_hash) do
    {}
  end
  fattr(:constants_hash) do
    {}
  end
  def add_constant_column(name,formula)
    arr = eval(formula).to_a
    constants_hash[name] = arr
  end
  def add_column(name,blk)
    blk = FormulaEval.new(:formula => blk, :coll => coll) if blk.kind_of?(String)
    self.column_hash[name.to_s] = blk
  end
  def cleaned_doc(doc)
    column_hash.keys.each do |k|
      doc.dot_set(k,nil)
    end
    doc
  end
  def constants_enriched_doc(doc,ops)
    constants_hash.each do |col,vals|
      vals = vals.to_a
      KeyParts.with_parts(col) do |start,lst,mult|
        if mult
          doc[start] ||= []
          vals.each_with_index do |val,i|
            field = "#{start}.#{i}.#{lst}"
            doc.dot_set(field,val)
          end
        elsif ops[:row_index]
          doc[col] = vals[ops[:row_index]]
        end
      end
    end
    doc
  end
  def calc_enriched_doc(doc,ops)
    doc = cleaned_doc(doc)
    column_hash.each_with_str_key do |col,blk|
      if KeyParts.single?(col)
        val = blk.call(doc)
        doc.dot_set(col,val)  
      else
        doc.dot_set(col) do |obj|
          multi = MultiEval.new(:objs => [obj,doc])
          blk.call(multi)
        end
      end
    end
    doc.to_unwrapped
  end
  def enriched_doc(doc,other_ops={})
    doc = constants_enriched_doc(doc,other_ops)
    doc = calc_enriched_doc(doc,other_ops)
  end
  def keys
    ks = column_hash.keys.map { |x| x.split('.').first }.uniq
    coll.keys.make_last(ks)
  end
  def save(doc,ops={},other_ops={})
    doc = enriched_doc(doc,other_ops)
    doc.nested_hash_set '_admin','last_calc_dt',Time.now
    
    res = coll.save(doc,ops)
    doc[:_id] = res
    doc
  end
  def update_calcs!
  end
  def update_calcs_real!
    constants_max = constants_hash.values.map { |x| x.to_a.size }.max || 0
    find({},{:limit => 9999}).each_with_index do |row,i|
      save(row,{},:row_index => i)
    end
    if constants_max > count
      (count...constants_max).each do |i|
        save({},{},:row_index => i)
      end
    end
  rescue => exp
    mylog 'update_calcs', :trace => exp.backtrace.join("\n"), :message => exp.message
    raise exp
  end
  def update_row(row_id,fields)
    row = coll.update_row(row_id,fields)
    mylog 'calc_update_row', :row => row, :coll => coll.class
    row = save(row)
  end
  def needs_calc?(doc)
    doc_dt = doc['_admin'].andand['last_calc_dt'] || Time.local(1970,1,1)
    user_coll_last_calc_dt > doc_dt
  end
  def find(selector={},ops={})
    res = coll.find(selector,ops)
    if res.respond_to?(:each)
      res.select { |doc| needs_calc?(doc) }.each { |doc| save(doc) }
    end
    res
  end
end