module DCell
  module Gossip
    #TODO introduce concept of generation to txgossip-inspired code
    # generation stores when a machine was brought online so you can detect restarts
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
