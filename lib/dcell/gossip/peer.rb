module DCell
  module Gossip
    class Peer
      attr_accessor :name
      attr_accessor :uri
      attr_accessor :heart

      attr_accessor :state
      attr_reader :timestamp

      def initialize(name, uri = nil, heart = Heart.new)
        @name = name
        @uri = uri || name
        @heart = heart
        @timestamp = Time.now.to_f;
        @alive = true
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
