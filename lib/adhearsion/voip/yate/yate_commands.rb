module Adhearsion
  module VoIP
    module Yate
      module Commands
        
        ##
        # Play a sound file at a given path.
        def play(*files)
          files.each do |file|
            send_message
          end
        end
        
        ##
        # Join a conference number
        def join(conference_number)
          channel = find_conference_channel(conference_number) || create_conference_channel(conference_number)
          attach_to channel
        end
        
        def dial
          call.execute :callto => "sip/sip:user@ip"
        end
        
        def menu
        end
        
        def interruptable_play(*files)
          
        end
        
      end
    end
  end
end