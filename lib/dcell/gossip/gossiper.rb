module DCell
  module Gossip
    
    class Gossiper
      include Celluloid

      DEFAULT_GOSSIP_INTERVAL = 1
      attr_accessor :gossip_interval

      attr_reader :addr
      attr_accessor :me, :peers, :seeds

      def initialize
        @gossip_interval = DEFAULT_GOSSIP_INTERVAL
        @addr = Gossip.addr
        @me = Peer.new(@addr)
        @peers = { @addr => @me }
        @seeds = [] #TODO create peers for seeds
        @scuttle = Scuttle.new(@me, @peers)

        run!
      end

      def run
        @me.beat_heart
        gossip
        @gossip_timer = after(gossip_interval) { run }
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
        @peers.collect { |addr, peer| peer if peer.alive? && addr != @addr }.compact
      end

      def dead_peers
        @peers.collect { |addr, peer| peer if !peer.alive? && addr != @addr }.compact
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
        #puts "sending to #{peer.addr}: #{@scuttle.digest.inspect}"
        peer.send_message RequestMessage.new(@addr, @scuttle.digest)
      end

      def handle_request(message)
        deltas, requests, new_peers = @scuttle.scuttle(message.digest)
        handle_new_peers(new_peers)
        @peers[message.endpoint].send_message(FirstResponseMessage.new(@addr, requests, deltas))
      end

      def handle_first_response(message)
        @scuttle.update_known_state(message.updates)
        @peers[message.endpoint].send_message(SecondResponseMessage.new(@scuttle.fetch_deltas(message.digest)))
      end

      def handle_second_response(message)
        @scuttle.update_known_state(message.updates)
      end

      def handle_new_peers(new_peers)
        new_peers.each do |addr|
          @peers[addr] = Peer.new(addr) unless @peers.include?(addr)
        end
      end
    end
  end
end
