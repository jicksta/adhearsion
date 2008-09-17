module Adhearsion
  module VoIP
    module Yate
      class YateCall < Call

        class << self
          def coerce_variables(variables)
            VariableCoercions::COERCION_ORDER.inject(variables) do |modified_variables, coercion_method|
              VariableCoercions.send(coercion_method, modified_variables)
            end
          end
        end
        
        def initialize(variables)
          super(variables)
        end

        module VariableCoercions
          
          COERCION_ORDER = %w[
            coerce_to_boolean
          ]
          
          class << self
            def coerce_to_boolean(variables={})
              variables.inject({}) do |hash,(key,value)|
                hash[key] = case value
                when "true"
                  true
                when "false"
                  false
                else
                  value
                end
                hash
              end
            end
          end
        end
        
      end
    end
  end
end
