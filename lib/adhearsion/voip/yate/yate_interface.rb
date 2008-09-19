require 'rubygems'
require 'eventmachine'
require 'adhearsion/voip/yate/yate_message'
require 'adhearsion/voip/yate/yate_call'

# FRAGEN
# - Are all the fields after a certain point key/value pairs? It better be consistent.  :(
# - I really don't like how Yate will hang if something doesn't acknowledge a message. what if someone does kill -9 on the handling process? There could be messages not yet acknowledged and Yate itself hangs. weak sauce.
# - Can Diana document the weaknesses in the platform? Her answer was too terse.
module Adhearsion
  module VoIP
    module Yate
      
      class YateInterface < EM::Protocols::LineAndTextProtocol
        
        class << self
          def connect(host, port)
            EM.connect(host, port, self)
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
        
        def send_message(destination, options)
          action_id, priority = options.values_at :action_id, :priority
          send_data "%%<#{action_id}:#{priority}:#{destination}\n"
        end
        
        def receive_line(raw_message)
          puts "Received #{raw_message.inspect}"
          message = YateMessage.from_protocol_text raw_message
          case message.origination
            when "call.created" # Or whatever it is...
              call = YateCall.from_protocol_text line
              spawn_call_handler_for call
            when 'call.destroyed'
              call = Adhearsion.active_calls.with_tag(:yate).find message.call_id
              call.hangup!
            when "something_else_call_related"
              call = Adhearsion.active_calls.with_tag(:yate).find message.call_id
              call.handle_message message
            else
              # Let's return so that we don't acknowledge the message
              return
          end
          acknowledge_message message
          # respond to route command to send to an "ivr".
        rescue => e
          # TELL YATE TO CONTINUE WITHOUT AN ACKNOWLEDGEMENT OR SOMETHING...
          p e, *e.backtrace
        end
        
        ##
        # Yate's messaging systems works by having things "install" message handlers for a particular message endpoint.
        # It can be (and often is) the case that many things register themselves for a particular message endpoint and
        # Yate treats them with a certain priority. If a message handler decides it should not handle the message, it
        # does not acknowledge the message. If it does want to handle it, it "acknowledges" the message immediately.
        #
        # @param [YateMessage] message The message which we'll acknowledge with Yate.
        def acknowledge(message)
          send_data message.acknowledgement
        end
        
        def spawn_call_handler_for(call)
          @thread_group.add(Thread.new { handle_call call })
        end
        
        def handle_call(call)
          # Since we're using yate, have it use the first context defined.
          # Load dialplan
        end
        
      end
    end
  end
end
