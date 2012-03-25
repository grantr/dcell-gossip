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
        @server = Server.new(self)
        @peers = {}
        @seeds = options[:seeds] || [] #TODO create peers for seeds
        @scuttle = Scuttle.new(@me, @peers)
      end

      def run
        @me.beat_heart
        gossip!
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
        digest = @scuttle.digest
        peer.send_message RequestMessage.new(digest)
      end

      def handle_message(message)
        case message.class #TODO yuck!
        when RequestMessage
          deltas, requests, new_peers = @scuttle.scuttle(message.digest)
          handle_new_peers(new_peers)
        when FirstResponseMessage
        when SecondResponseMessage
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
      #####

    #   def make_random_gossip_digests
    #     generation = 0
    #     max_version = 0

    #     #TODO shuffle
    #     endpoint_state_map.to_a.shuffle.collect do |endpoint, state|
    #       if state
    #         generation = state.generation
    #         max_version = max_endpoint_state_version(state)
    #       end
    #       Digest.new(endpoint, generation, max_version)
    #     end
    #   end

    #   def gossip_to_live_member(digests)
    #     if live_endpoints.empty?
    #       false
    #     else
    #       send_gossip(digests, live_endpoints)
    #     end
    #   end

    #   def gossip_to_unreachable_member(digests)
    #     unless unreachable_endpoints.empty?
    #       probability = unreachable_endpoints.size / (live_endpoints.size + 1).to_f
    #       if rand < probability
    #         send_gossip(digests, unreachable_endpoints)
    #       end
    #     end
    #   end
    # 
    #   def gossip_to_seed(digests)
    #     unless seeds.empty?
    #       # return if it's just us
    #       return if size == 1 && seeds.include?(DCell.addr)

    #       if live_endpoints.empty?
    #         send_gossip(digests, seeds)
    #       else
    #         probability = seeds.size / (live_endpoints.size + unreachable_endpoints.size).to_f
    #         if rand <= probability
    #           send_gossip(digests, seeds)
    #         end
    #       end
    #     end
    #   end

    #   def send_gossip(digests, endpoints)
    #     return false if endpoints.empty?

    #     #TODO send_message
    #     #TODO sample
    #     send_message GossipDigestSynMessage.new(digests), endpoints.sample
    #   end

    #   def status_check
    #     now = Time.now.to_f

    #     endpoint_state_map.each do |endpoint, state|
    #       next if endpoint == DCell.addr

    #       failure_detector.interpret(endpoint)
    #       if state
    #         duration = state.timestamp
    #         expire_time = get_expire_time_for_endpoint(endpoint)
    #         
    #         if !state.alive? && now > expire_time
    #           evict_from_membership(endpoint)
    #         end
    #       end
    #     end
    #   end

    #   def evict_from_membership(endpoint)
    #     unreachable_endpoints.delete(endpoint)
    #     endpoint_state_map.remove(endpoint)

    # end
#   end
# end
