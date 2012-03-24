module DCell
  module Gossip
    class Heart < Struct.new(:version, :generation)

      def initialize(generation = 0, version = 0)
        super
      end

      def beat!
        #TODO thread unsafe
        @version += 1
      end
    end
  end
end
