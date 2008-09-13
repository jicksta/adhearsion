require 'uri'
#TODO Some of this is asterisk-specific
module Adhearsion
  class << self
    def active_calls
      @calls ||= Calls.new
    end
  
    def remove_inactive_call(call)
      active_calls.remove_inactive_call(call)
    end
  end
  
  ##
  # This manages the list of calls the Adhearsion service receives
  class Calls
    def initialize
      @semaphore = Monitor.new
      @calls     = {}
    end
    
    def <<(call)
      atomically do
        calls[call.unique_identifier] = call
      end
    end
    
    def any?
      atomically do
        !calls.empty?
      end
    end
    
    def size
      atomically do
        calls.size
      end
    end
    
    def remove_inactive_call(call)
      atomically do
        calls.delete call.unique_identifier
      end
    end
    
    # Searches all active calls by their unique_identifier. See Call#unique_identifier.
    def find(id)
      atomically do
        return calls[id]
      end
    end
    
    def clear!
      atomically do
        calls.clear
      end
    end
    
    def with_tag(tag)
      atomically do
        calls.inject(Array.new) do |calls_with_tag,(key,call)|
          call.tagged_with?(tag) ? calls_with_tag << call : calls_with_tag
        end
      end
    end
    
    private
      attr_reader :semaphore, :calls
      
      def atomically(&block)
        semaphore.synchronize(&block)
      end
      
  end
  
  class UselessCallException < Exception; end
  
  class MetaAgiCallException < Exception
    attr_reader :call
    def initialize(call)
      super()
      @call = call
    end
  end
  
  class FailedExtensionCallException < MetaAgiCallException; end
  
  class HungupExtensionCallException < MetaAgiCallException; end
  
  ##
  # Encapsulates call-related data and behavior.
  # For example, variables passed in on call initiation are
  # accessible here as attributes    
  class Call
    
    attr_accessor :variables
    attr_reader :inbox
    
    def initialize(variables)
      @variables = variables.symbolize_keys
      define_variable_accessors
      @tag_mutex = Mutex.new
      @tags = []
    end

    def register_globally_as_active
      Adhearsion.active_calls << self
    end

    def originating_voip_platform
      raise NotImplementedError, "This is only implemented in subclasses of Call!"
    end
    
    def tags
      @tag_mutex.synchronize do
        return @tags.clone
      end
    end

    def tag(symbol)
      raise ArgumentError, "tag must be a Symbol" unless symbol.is_a? Symbol
      @tag_mutex.synchronize do
        @tags << symbol
      end
    end
    
    def remove_tag(symbol)
      @tag_mutex.synchronize do
        @tags.reject! { |tag| tag == symbol }
      end
    end
    
    def tagged_with?(symbol)
      @tag_mutex.synchronize do
        @tags.include? symbol
      end
    end

    def deliver_message(message)
      inbox << message
    end
    alias << deliver_message

    def inbox
      @inbox ||= Queue.new
    end

    def hangup!
      Adhearsion.remove_inactive_call self
    end

    def closed?
      io.closed?
    end
    
    # Adhearsion indexes calls by this identifier so they may later be found and manipulated. For calls from Asterisk, this
    # method uses the following properties for uniqueness, falling back to the next if one is for some reason unavailable:
    #
    #     Asterisk channel ID     ->        unique ID        -> Call#object_id
    # (e.g. SIP/mytrunk-jb12c88a) -> (e.g. 1215039989.47033) -> (e.g. 2792080)
    #
    # Note: channel is used over unique ID because channel may be used to bridge two channels together.
    def unique_identifier
      raise NotImplementedError, "Must be implemented in subclass!"
    end
    
    def define_variable_accessors(recipient=self)
      variables.each do |key, value| 
        define_singleton_accessor_with_pair(key, value, recipient)
      end
    end
    
    protected
      
    def define_singleton_accessor_with_pair(key, value, recipient=self)
      recipient.metaclass.send :attr_accessor, key unless recipient.class.respond_to?("#{key}=")
      recipient.send "#{key}=", value
    end
    
  end  

end
