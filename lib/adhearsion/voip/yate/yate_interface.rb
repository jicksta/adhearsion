require 'rubygems'
require 'eventmachine'

# Fragen für Diana über Yate
# - Could I embed Yate within a Ruby process? That'd be kickasssss.
# - Does it have many dependencies? 
# - Maybe create a STOMP client in Yate? that'd be awesome too.
# - What if there is %%% in the protocol? Can that ever happen? Are there any other things to unescape?
# - When Yate goes off and does something, can you tell it to stop doing it? (e.g. stop playback on dtmf)
# - What do you know about GrandCentral?
# - Do calls have unique ids? When I get a DTMF message, how do I identify the call it came from?
# - I don't understand which messages need to be send to do common things, e.g. dial(). Ar there other Yate abstractions I can look at?

module Adhearsion
  module VoIP
    module Yate
      
      class YateInterface < EM::Protocols::LineAndTextProtocol
        
        class << self
          def connect(host, port)
            EM.connect(host, port, self)
          end
          
          def parse_line(line)
            line = line[3..-1].split(":").map do |field|
              field.gsub("%Z", ":").gsub('%%', '%')
            end
          end

        end
        
        def initialize(*args)
          super
          @thread_group = ThreadGroup.new
        end
        
        def post_init
          ahn_log.yate "Connection established"
          # Adhearsion.receive_call_from(io) # Bah..
          # subscribe_to "engine.timer"
          # subscribe_to "yyy"
        end
        
        def subscribe_to(options)
          send_message "install"
        end
        
        def send_message(message_name, options)
          handler, priority = options.values_at :handler, :priority
          send_data "%%>#{message_name}:#{priority}:#{handler}\n"
        end
        
        def receive_line(line)
          line = parse_line line
          puts "Received #{line.inspect}"
        end
        
      end
    end
  end
end
