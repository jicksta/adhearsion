# %%>message:<id>:<time>:<name>:<retvalue>[:<key>=<value>...]
module Adhearsion
  module VoIP
    module Yate
      class YateMessage
        
        class << self
          
          def from_protocol_text(text)
            unique_id, message_name, *rest = parse_line text
            new(message_name, unique_id, *rest)
          end
          
          def parse_line(line)
            line = line.chomp[3..-1].split(":").map do |field|
              field.gsub("%Z", ":").gsub('%%', '%')
            end
          end
          
        end
        
        def initialize(message_name, unique_id, *rest_of_fields)
          @message_name, @unique_id, @rest_of_fields = message_name, unique_id, rest_of_fields
        end
        
        def to_s
          "%%<#{}:#{}:#{}" # ...
        end
        
        def acknowledgement
          clone#.change_property_here
        end
        
      end
      
    end
  end
end