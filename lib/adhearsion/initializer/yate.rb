require 'adhearsion/voip/asterisk'
module Adhearsion
  class Initializer
    
    class YateInitializer
      
      cattr_accessor :config, :host, :port, :connection
      class << self
        
        def start
          self.config     = Adhearsion::AHN_CONFIG.yate
          self.host       = config.host
          self.port       = config.port
          
          establish_connection_after_initialized
        end

        # No need to stop because EM will stop at shutdown.
        def stop
        end

        private
        
        # This done automatically by EventMachine basically.
        # def join_server_thread_after_initialized
        #   Adhearsion::Hooks::ThreadsJoinedAfterInitialized.create_hook { agi_server.join }
        # end
        
        def establish_connection_after_initialized
          Adhearsion::Hooks::AfterInitialized.create_hook do
            self.connection = Adhearsion::VoIP::Yate::YateInterface.connect(self.host, self.port)
          end
        end

      end
    end
    
  end
end
