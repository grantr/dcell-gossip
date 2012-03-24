module DCell
  module Gossip
    class Gossiper
      include Celluloid

      INTERVAL = 1000

      attr_accessor :live_endpoints, :unreachable_endpoints
      attr_accessor :seeds
      attr_accessor :endpoint_state_map # addr => endpoint_state
      attr_accessor :expire_time_endpoint_map
      attr_accessor :just_removed_endpoints

      def run
        gossip
        after(INTERVAL) { run }
      end

      def gossip
        # beat local heart
        endpoint_state_map[DCell.addr].heart.beat!

        # get some digests
        digests = make_random_gossip_digests
        
        unless digests.empty?
          # gossip to a random live endpoint
          gossiped_to_seed = gossip_to_live_member(digests)

          # gossip to unreachable member
          gossip_to_unreachable_member(digests)

          if (!gossiped_to_seed || live_endpoints.size < seeds.size)
            gossip_to_seed(digests)
          end

          check_status
        end
      end



      def make_random_gossip_digests
        generation = 0
        max_version = 0

        #TODO shuffle
        endpoint_state_map.to_a.shuffle.collect do |endpoint, state|
          if state
            generation = state.generation
            max_version = max_endpoint_state_version(state)
          end
          Digest.new(endpoint, generation, max_version)
        end
      end

      def gossip_to_live_member(digests)
        if live_endpoints.empty?
          false
        else
          send_gossip(digests, live_endpoints)
        end
      end

      def gossip_to_unreachable_member(digests)
        unless unreachable_endpoints.empty?
          probability = unreachable_endpoints.size / (live_endpoints.size + 1).to_f
          if rand < probability
            send_gossip(digests, unreachable_endpoints)
          end
        end
      end
    
      def gossip_to_seed(digests)
        unless seeds.empty?
          # return if it's just us
          return if size == 1 && seeds.include?(DCell.addr)

          if live_endpoints.empty?
            send_gossip(digests, seeds)
          else
            probability = seeds.size / (live_endpoints.size + unreachable_endpoints.size).to_f
            if rand <= probability
              send_gossip(digests, seeds)
            end
          end
        end
      end

      def send_gossip(digests, endpoints)
        return false if endpoints.empty?

        #TODO send_message
        #TODO sample
        send_message GossipDigestSynMessage.new(digests), endpoints.sample
      end

      def status_check
        now = Time.now.to_f

        endpoint_state_map.each do |endpoint, state|
          next if endpoint == DCell.addr

          failure_detector.interpret(endpoint)
          if state
            duration = state.timestamp
            expire_time = get_expire_time_for_endpoint(endpoint)
            
            if !state.alive? && now > expire_time
              evict_from_membership(endpoint)
            end
          end
        end
      end

      def evict_from_membership(endpoint)
        unreachable_endpoints.delete(endpoint)
        endpoint_state_map.remove(endpoint)

    end
  end
end
