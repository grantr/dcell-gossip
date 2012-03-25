module DCell
  module Gossip
    
    class Gossiper
      include Celluloid

      DEFAULT_GOSSIP_INTERVAL = 1
      attr_accessor :gossip_interval

      attr_reader :addr
      attr_accessor :me, :peers, :seeds

      def initialize(addr, options = {})
        @gossip_interval = options[:gossip_interval] || DEFAULT_GOSSIP_INTERVAL
        @addr = addr
        @me = Peer.new(addr)
        @server = Server.new(addr)
        @peers = {}
        @seeds = options[:seeds] || [] #TODO create peers for seeds
        @scuttle = Scuttle.new(@me, @peers)
      end

      def run
        @me.beat_heart
        gossip
        @gossip_timer = after(gossip_interval) { run }
      end

      def stop
        @gossip_timer.cancel if @gossip_timer
      end

      def gossip
        gossiped_to_seed = gossip_to_live? ? gossip_to(live_peers.sample) : false

        gossip_to(dead_peers.sample) if gossip_to_dead?

        if !gossiped_to_seed || live_peers.size < seeds.size
          gossip_to(seeds.sample) if gossip_to_seed?
        end

        check_peers
      end

      def live_peers
        @peers.collect { |addr, peer| peer if peer.alive? }
      end

      def dead_peers
        @peers.collect { |addr, peer| peer unless peer.alive? }
      end

      def all_peers
        @peers.values + @me
      end

      def gossip_to_live?
        !live_peers.empty?
      end

      def gossip_to_dead?
        !dead_peers.empty? && rand < dead_peers.size / (live_peers.size + 1).to_f
      end

      def gossip_to_seed?
        rand <= seeds.size / (live_peers.size + dead_peers.size).to_f
      end

      def check_peers
        @peers.each { |addr, peer| peer.check }
      end

      def gossip_to(peer)
        peer.send_message RequestMessage.new(digest)
      end

      def handle_message(message)
        case message.class #TODO yuck!
        when RequestMessage
          deltas, requests, new_peers = @scuttle.scuttle(message.digest)
          handle_new_peers(new_peers)
          FirstResponseMessage.new(requests, deltas)
          #TODO reply: need source peer
        when FirstResponseMessage
          @scuttle.update_known_state(message.updates)
          SecondResponseMessage.new(@scuttle.fetch_deltas(message.digest))
          #TODO reply: need source peer


        when SecondResponseMessage
          @scuttle.update_known_state(message.updates)
        end
      end

      def handle_new_peers(new_peers)
        new_peers.each do |addr|
          @peers[addr] = Peer.new(addr) unless @peers.include?(addr)
        end
      end
    end
  end
end
