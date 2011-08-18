module EY
  module ServicesAPI
    class Invoice < APIStruct.new(:total_amount_cents, :line_item_description)
    end
  end
end