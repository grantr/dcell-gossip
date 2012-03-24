module DCell
  module Gossip
    class GossipDigestSynMessage < DCell::Message
      attr_reader :digests

      def initialize(digests)
        super
        @digests = digests
      end
    end

    class GossipDigestAckMessage < DCell::Message
      attr_reader :digests, :endpoint_state

      def initialize(digests, endpoint_state)
        super
        @digests, @endpoint_state = digests, endpoint_state
      end
    end
    
    class GossipDigestAck2Message < DCell::Message
      attr_reader :endpoint_state

      def initialize(endpoint_state)
        super
        @endpoint_state = endpoint_state
    end
  end
end
