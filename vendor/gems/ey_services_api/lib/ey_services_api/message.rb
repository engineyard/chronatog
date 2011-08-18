module EY
  module ServicesAPI
    class Message < APIStruct.new(:message_type, :subject, :body)
    end
  end
end