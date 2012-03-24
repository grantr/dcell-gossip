module DCell
  module Gossip
    class EndpointState
      # heartbeat_state
      attr_reader :heart, :globals, :timestamp

      def initialize(heart = Heart.new)
        @heart = heart
        @globals = {}
        @timestamp = Time.now.to_f # this is not serialized
        @alive = true # this is not serialized
      end

      def update_timestamp!(timestamp = Time.now.to_f)
        @timestamp = timestamp
      end

      def alive?
        @alive
      end

      def mark_alive!
        @alive = true
      end

      def mark_dead!
        @alive = false
      end
    end
  end
end
