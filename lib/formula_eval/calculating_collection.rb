class CalculatingCollection
  attr_accessor :coll
  include FromHash
  fattr(:column_hash) do
    res = {}
    # res[:zzz] = lambda { |doc| (doc['abc']||0).to_i + 7 }
    # res[:xyz] = FormulaEval.new(:formula => '=(abc||0)+8')
    # res[:percs] = FormulaEval.new(:formula => '=pension.perc')
    # res[:percs2] = FormulaEval.new(:formula => '=pension.perc * 2.0')
    if coll.name == 'yefffars'
      res['pension.just_perc'] = FormulaEval.new(:formula => '=perc')
      res['wheeeee'] = FormulaEval.new(:formula => '=17')
      res['pension.perc_plus_salary'] = FormulaEval.new(:formula => '=perc+salary')
    end
    # res['pension.just_perc_plus'] = FormulaEval.new(:formula => '=perc+1')
    # 
    res
  end
  def add_column(name,blk)
    blk = FormulaEval.new(:formula => blk) if blk.kind_of?(String)
    self.column_hash[name.to_s] = blk
  end
  def enriched_doc(doc)
    di = doc.inspect
    column_hash.each do |col,blk|
      # mylog 'enriched_doc', :col => col, :blk_class => blk.class, :doc => doc
      if col.to_s.split('.').size == 1
        val = blk.call(doc)
        mylog 'dot_set',:col => col, :val => val, :doc => doc
        doc.dot_set(col.to_s,val)  
      else
        # base = col.to_s.split('.')[0..-2].join(".")
        # obj = MultiEval.get_nested(doc,base)
        # val = blk.call(obj)
        # mylog 'dot_set',:col => col, :val => val, :doc => doc, :obj => obj
        doc.dot_set(col.to_s) do |obj|
          multi = MultiEval.new(:objs => [obj,doc])
          val = blk.call(multi)
        end
      end
    end
    res = doc.to_unwrapped
    mylog "enriched_doc", :orig => di, :enriched => res, :columns => column_hash.keys
    res
  end
  def save(doc,ops={})
    mylog 'calc_save', :doc => doc, :doc_class => doc.class, :unwrapped => doc.to_unwrapped.class
    coll.save(enriched_doc(doc),ops)
  end
  def update_calcs!
    find({},{:limit => 9999}).each do |row|
      save(row)
    end
  end
  def update_row(row_id,fields)
    row = (row_id == 'NEW') ? {} : find_by_id(row_id)
    raise "can't find row #{row_id} #{row_id.class} in coll #{name}.  Count is #{find.count} IDs are "+find.to_a.map { |x| x['_id'] }.inspect + "Trying to update with #{fields.inspect}" unless row
    fields.each do |k,v|
      row.dot_set(k,mongo_value(v))
      row.delete(k) if v.blank?
    end
    row = enriched_doc(row)
    save(row)
    row
  end
  def method_missing(sym,*args,&b)
    coll.send(sym,*args,&b)
  end
end