module DCell
  module Gossip
    #CASSANDRA
    class Digest
      attr_reader :endpoint, :generation, :max_version

      def initialize(endpoint, generation, max_version)
        @endpoint, @generation, @max_version = endpoint, generation, max_version
      end

      def <=>(other)
        if generation != other.generation
          generation - other.generation
        else
          max_version - other.max_version
        end
      end

    end
  end
end
