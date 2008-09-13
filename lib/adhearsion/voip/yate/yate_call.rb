module Adhearsion
  module VoIP
    module Yate
      class YateCall < Call
        
        def initialize(variables)
          super(variables)
        end
        
        module Variables
          
          module Coercions
            COERCION_ORDER = %w[
              coerce_to_boolean
            ]
            
            def coerce_to_boolean(variables={})
              variables.inject({}) do |hash,(key,value)|
                hash[key] = value
                hash
              end
            end
          end
          
          class Parser
            def initialize
              
            end
          end
          
        end
        
      end
    end
  end
end
