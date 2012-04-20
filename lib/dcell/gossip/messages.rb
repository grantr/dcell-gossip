module DCell
  module Gossip
    class RequestMessage
      attr_reader :reply_to, :digest

      def initialize(reply_to, digest)
        @reply_to = reply_to 
        @digest = digest
      end

      def dispatch
        #puts "received #{self.class.name}: #{digest.inspect}"
        Celluloid::Actor[:gossiper].handle_request(self)
      end
    end

    class FirstResponseMessage
      attr_reader :reply_to, :digest, :updates

      def initialize(reply_to, digest, updates)
        @reply_to = reply_to
        @digest, @updates = digest, updates
      end

      def dispatch
        #puts "received #{self.class.name}: #{digest.inspect} #{updates.inspect}"
        Celluloid::Actor[:gossiper].handle_first_response(self)
      end
    end
    
    class SecondResponseMessage
      attr_reader :updates

      def initialize(updates)
        @updates = updates
      end

      def dispatch
        #puts "received #{self.class.name}: #{updates.inspect}"
        Celluloid::Actor[:gossiper].handle_second_response(self)
      end
    end
  end
end
