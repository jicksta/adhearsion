module Adhearsion
  module VoIP
    module Asterisk
      ##
      # Encapsulates call-related data and behavior.
      # For example, variables passed in on call initiation are
      # accessible here as attributes    
      class AsteriskCall < Call
  
        # This is basically a translation of ast_channel_reason2str() from main/channel.c and
        # ast_control_frame_type in include/asterisk/frame.h in the Asterisk source code. When
        # Asterisk jumps to the 'failed' extension, it sets a REASON channel variable to a number.
        # The indexes of these symbols represent the possible numbers REASON could be.
        ASTERISK_FRAME_STATES = [
          :failure,     # "Call Failure (not BUSY, and not NO_ANSWER, maybe Circuit busy or down?)"
          :hangup,      # Other end has hungup
          :ring,        # Local ring
          :ringing,     # Remote end is ringing
          :answer,      # Remote end has answered
          :busy,        # Remote end is busy
          :takeoffhook, # Make it go off hook
          :offhook,     # Line is off hook
          :congestion,  # Congestion (circuits busy)
          :flash,       # Flash hook
          :wink,        # Wink
          :option,      # Set a low-level option
          :radio_key,   # Key Radio
          :radio_unkey, # Un-Key Radio
          :progress,    # Indicate PROGRESS
          :proceeding,  # Indicate CALL PROCEEDING
          :hold,        # Indicate call is placed on hold
          :unhold,      # Indicate call is left from hold
          :vidupdate    # Indicate video frame update
        ]
  
  
        class << self
          ##
          # The primary public interface for creating a Call instance.
          # Given an IO (probably a socket accepted from an Asterisk service),
          # creates a Call instance which encapsulates everything we know about that call.
          def receive_from(io, &block)
            returning new(io, variable_parser_for(io).variables) do |call|
              block.call(call) if block
              call.register_globally_as_active
            end
          end
  
          private
          def variable_parser_for(io)
            Variables::Parser.parse(io)
          end
    
        end
  
        attr_accessor :io
        def initialize(io, variables)
          super(variables)
          @io, @variables = io, variables.symbolize_keys
          check_if_valid_call
          define_variable_accessors
          @tag_mutex = Mutex.new
          @tags = []
        end

        ##
        # Used in Call polymorphism to identify the media platform underneath Adhearsion. Returns :asterisk.
        #
        # @return [Symbol] :asterisk
        def originating_voip_platform
          :asterisk
        end

        def hangup!
          super
          io.close
        end

        def closed?
          io.closed?
        end
  
        ##
        # Asterisk sometimes uses the "failed" extension to indicate a failed dial attempt.
        # Since it may be important to handle these, this flag helps the dialplan Manager
        # figure that out.
        def failed_meta_call?
          @failed_meta_call
        end
  
        ##
        # This actual
        def hungup_meta_call?
          @hungup_meta_call
        end
  
        # Adhearsion indexes calls by this identifier so they may later be found and manipulated. For calls from Asterisk, this
        # method uses the following properties for uniqueness, falling back to the next if one is for some reason unavailable:
        #
        #     Asterisk channel ID     ->        unique ID        -> Call#object_id
        # (e.g. SIP/mytrunk-jb12c88a) -> (e.g. 1215039989.47033) -> (e.g. 2792080)
        #
        # Note: channel is used over unique ID because channel may be used to bridge two channels together.
        def unique_identifier
          variables[:channel] || variables[:uniqueid] || object_id
        end
  
        def extract_failed_reason_from(environment)
          failed_reason = environment.variable 'REASON'
          failed_reason &&= ASTERISK_FRAME_STATES[failed_reason.to_i]
          define_singleton_accessor_with_pair(:failed_reason, failed_reason, environment)
        end
  
        protected
        
        def check_if_valid_call
          extension = variables[:extension]
          @failed_meta_call = true if extension == 'failed'
          @hungup_meta_call = true if extension == 'h'
          raise UselessCallException if extension == 't' # TODO: Move this whole method to Manager
        end
  
        module Variables
    
          module Coercions

            COERCION_ORDER = %w{
              remove_agi_prefixes_from_keys_and_strip_whitespace
              coerce_keys_into_symbols
              coerce_extension_into_phone_number_object
              coerce_numerical_values_to_numerics
              replace_unknown_values_with_nil
              replace_yes_no_answers_with_booleans
              coerce_request_into_uri_object
              decompose_uri_query_into_hash
              override_variables_with_query_params
              remove_dashes_from_context_name
              coerce_type_of_number_into_symbol
            }

            class << self
        
              def remove_agi_prefixes_from_keys_and_strip_whitespace(variables)
                variables.inject({}) do |new_variables,(key,value)|
                  returning new_variables do
                    stripped_name = key.kind_of?(String) ? key[/^(agi_)?(.+)$/,2] : key
                    new_variables[stripped_name] = value.kind_of?(String) ? value.strip : value
                  end
                end
              end
        
              def coerce_keys_into_symbols(variables)
                variables.inject({}) do |new_variables,(key,value)|
                  returning new_variables do
                    new_variables[key.to_sym] = value
                  end
                end
              end
        
              def coerce_extension_into_phone_number_object(variables)
                returning variables do
                  variables[:extension] = Adhearsion::VoIP::DSL::PhoneNumber.new(variables[:extension])
                end
              end
        
              def coerce_numerical_values_to_numerics(variables)
                variables.inject({}) do |vars,(key,value)|
                  returning vars do
                    is_numeric = value =~ /^-?\d+(?:(\.)\d+)?$/
                    is_float   = $1
                    vars[key] = if is_numeric
                      if Adhearsion::VoIP::DSL::NumericalString.starts_with_leading_zero?(value)
                        Adhearsion::VoIP::DSL::NumericalString.new(value)
                      else
                        is_float ? value.to_f : value.to_i
                      end
                    else
                      value
                    end
                  end
                end
              end

              def replace_unknown_values_with_nil(variables)
                variables.each do |key,value|
                  variables[key] = nil if value == 'unknown'
                end
              end

              def replace_yes_no_answers_with_booleans(variables)
                variables.each do |key,value|
                  case value
                    when 'yes' : variables[key] = true
                    when 'no'  : variables[key] = false
                  end
                end
              end
        
              def coerce_request_into_uri_object(variables)
                returning variables do
                  variables[:request] = URI.parse(variables[:request]) unless variables[:request].kind_of? URI
                end
              end
        
              def coerce_type_of_number_into_symbol(variables)
                returning variables do
                  variables[:type_of_calling_number] = Adhearsion::VoIP::Constants::Q931_TYPE_OF_NUMBER[variables.delete(:callington).to_i]
                end
              end

              def decompose_uri_query_into_hash(variables)
                returning variables do
                  if variables[:request].query
                    variables[:query] = variables[:request].query.split('&').inject({}) do |query_string_parameters, key_value_pair|
                      parameter_name, parameter_value = *key_value_pair.match(/(.+)=(.+)/).captures
                      query_string_parameters[parameter_name] = parameter_value
                      query_string_parameters
                    end
                  else
                    variables[:query] = {}
                  end
                end
              end
        
              def override_variables_with_query_params(variables)
                returning variables do
                  if variables[:query]
                    variables[:query].each do |key, value|
                      variables[key.to_sym] = value
                    end
                  end
                end
              end
        
              def remove_dashes_from_context_name(variables)
                returning variables do
                  variables[:context].gsub!('-', '_')
                end
              end
        
            end
          end

          class Parser
      
            class << self
              def parse(*args, &block)
                returning new(*args, &block) do |parser|
                  parser.parse
                end
              end
        
              def coerce_variables(variables)
                Coercions::COERCION_ORDER.inject(variables) do |tmp_variables, coercing_method_name|
                  Coercions.send(coercing_method_name, tmp_variables)
                end
              end
        
              def separate_line_into_key_value_pair(line)
                line.match(/^([^:]+):\s?(.+)/).captures
              end
            end
    
            attr_reader :io, :variables, :lines
            def initialize(io)
              @io = io
              @lines = []
            end
    
            def parse
              extract_variable_lines_from_io
              initialize_variables_as_hash_from_lines
              @variables = self.class.coerce_variables(variables)
            end
      
            private
        
              def initialize_variables_as_hash_from_lines
                @variables = lines.inject({}) do |new_variables,line|
                  returning new_variables do
                    key, value = self.class.separate_line_into_key_value_pair line
                    new_variables[key] = value
                  end
                end
              end
        
              def extract_variable_lines_from_io
                while line = io.readline.chomp
                  break if line.empty?
                  @lines << line
                end
              end
      
          end
  
        end
      end
    end
  end
end