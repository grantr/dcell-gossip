module DCell
  module Gossip
    class Peers
      attr_accessor :me, :peers

      def initialize(me)
        @me = me
        add(me)
      end

      def peers
        @peers ||= {}
      end

      def add(addressesses)
        puts "adding: #{addressesses.inspect}"
        Array(addressesses).each do |address|
          puts "inside loop: #{address.inspect}"
          peers[address] ||= Peer.new(address) unless peers[address]
        end
      end

      def live
        peers.collect { |address, peer| peer if peer.alive? && address != @me }.compact
      end

      def dead
        peers.collect { |address, peer| peer if !peer.alive? && address != @me }.compact
      end
      
      def [](address)
        peers[address]
      end

      def each(&block)
        peers.each(&block)
      end
    end
  end
end
