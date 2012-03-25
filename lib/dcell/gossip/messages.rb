module DCell
  module Gossip
    class RequestMessage
      attr_reader :digest

      def initialize(digest)
        super
        @digest = digest
      end

      def dispatch
        deltas, requests, new_peers = 
        puts "received #{self.class.name}: #{digest.inspect}"
      end
    end

    class FirstResponseMessage
      attr_reader :digest, :updates

      def initialize(digest, updates)
        super
        @digest, @endpoint_stat = digest, updates
      end

      def dispatch
        puts "received #{self.class.name}: #{digest.inspect} #{updates.inspect}"
      end
    end
    
    class SecondResponseMessage
      attr_reader :updates

      def initialize(updates)
        super
        @updates = updates
      end

      def dispatch
        puts "received #{self.class.name}: #{updates.inspect}"
      end
    end
  end
end
