require 'rubygems'
require 'eventmachine'
require 'adhearsion/voip/yate/'

# Fragen für Diana über Yate
# - Can I add new SIP registrations? I don't want to use ysipchan.conf
# - Could I embed Yate within a Ruby process? That'd be kickasssss.
# - Does it have many dependencies? 
# - Maybe create a STOMP client in Yate? that'd be awesome too.
# - What if there is %%% in the protocol? Can that ever happen? Are there any other things to unescape?
# - When Yate goes off and does something, can you tell it to stop doing it? (e.g. stop playback on dtmf)
# - What do you know about GrandCentral?
# - Do calls have unique ids? When I get a DTMF message, how do I identify the call it came from?
# - I don't understand which messages need to be send to do common things, e.g. dial(). Ar there other Yate abstractions I can look at?
# - How difficult is it to talk to a Digium PRI card? Is that stack 100% stable? Examples online?
# - Can Yate be compiled on OSX?
# - Some of the example stuff (e..g the PHP lib) are broken on the Yate website.
# - Given Yate's architecture, what are the limitations you've found? Are there any features you realized you couldn't implement? Be frank.
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
        
        def spawn_call_with_parameters(params)
          @thread_group.add(Thread.new { handle_call params })
        end
        
        def handle_call(params)
          YateCall.new
        end
        
      end
    end
  end
end
