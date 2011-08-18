class APIStruct < Struct
  def initialize(atts = {})
    #converting all keys of atts to Symbols
    atts = Hash[atts.map {|k,v| [k.to_sym, v]}]
    super(*atts.values_at(*self.members.map(&:to_sym)))
  end
  
  def to_hash
    Hash[members.zip(entries)]
  end
  
  protected
  def update_from_hash(atts)
    atts.each do |k, v|
      self.send("#{k}=", v)
    end
  end
end