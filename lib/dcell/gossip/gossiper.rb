module DCell
  module Gossip
    
    class Gossiper
      include Celluloid

      DEFAULT_GOSSIP_INTERVAL = 1
      attr_accessor :gossip_interval

      attr_reader :address
      attr_accessor :peers, :seeds

      def initialize
        @gossip_interval = DEFAULT_GOSSIP_INTERVAL
        @address = Gossip.address
        @peers = Peers.new(@address)
        @seeds = Array(Gossip.seeds)
        @peers.add(@seeds)

        run!
      end

      def run
        me.beat_heart
        gossip
        @gossip_timer = after(gossip_interval) { run }
      end

      def gossip
        gossiped_to_seed = gossip_to_live? ? gossip_to(peers.live.sample) : false

        gossip_to(peers.dead.sample) if gossip_to_dead?

        if !gossiped_to_seed || peers.live.size < seeds.size
          gossip_to(peers[seeds.sample]) if gossip_to_seed?
        end

        check_peers
      end

      def me
        peers[address]
      end

      def gossip_to_live?
        !peers.live.empty?
      end

      def gossip_to_dead?
        !peers.dead.empty? && rand < peers.dead.size / (peers.live.size + 1).to_f
      end

      def gossip_to_seed?
        rand <= seeds.size / (peers.live.size + peers.dead.size).to_f
      end

      def check_peers
        peers.each { |address, peer| peer.check }
      end

      def gossip_to(peer)
        peer.send_message RequestMessage.new(@address, peers.digest)
      end

      def handle_request(message)
        deltas, requests = peers.unpack(message.digest)
        peers[message.reply_to].send_message(FirstResponseMessage.new(address, requests, deltas))
      end

      def handle_first_response(message)
        peers.update(message.updates)
        peers[message.reply_to].send_message(SecondResponseMessage.new(peers.fetch_deltas(message.digest)))
      end

      def handle_second_response(message)
        peers.update(message.updates)
      end
    end
  end
end
