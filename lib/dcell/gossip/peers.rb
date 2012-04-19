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

      def add(addrs)
        puts "adding: #{addrs.inspect}"
        Array(addrs).each do |addr|
          puts "inside loop: #{addr.inspect}"
          peers[addr] ||= Peer.new(addr) unless peers[addr]
        end
      end

      def live
        peers.collect { |addr, peer| peer if peer.alive? && addr != @me }.compact
      end

      def dead
        peers.collect { |addr, peer| peer if !peer.alive? && addr != @me }.compact
      end
      
      def [](addr)
        peers[addr]
      end

      def each(&block)
        peers.each(&block)
      end
    end
  end
end
