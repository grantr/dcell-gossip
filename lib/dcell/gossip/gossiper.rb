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
        @scuttle = Scuttle.new(@me, @peers)

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
        peers[@address]
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
        #puts "sending to #{peer.address}: #{@scuttle.digest.inspect}"
        peer.send_message RequestMessage.new(@address, @scuttle.digest)
      end

      def handle_request(message)
        deltas, requests, new_peers = @scuttle.scuttle(message.digest)
        handle_new_peers(new_peers)
        peers[message.endpoint].send_message(FirstResponseMessage.new(@address, requests, deltas))
      end

      def handle_first_response(message)
        @scuttle.update_known_state(message.updates)
        peers[message.endpoint].send_message(SecondResponseMessage.new(@scuttle.fetch_deltas(message.digest)))
      end

      def handle_second_response(message)
        @scuttle.update_known_state(message.updates)
      end

      def handle_new_peers(new_peers)
        new_peers.each do |address|
          peers.add(address)
        end
      end
    end
  end
end
