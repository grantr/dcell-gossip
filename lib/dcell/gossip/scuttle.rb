module DCell
  module Gossip
    #TODO This class needs to be reworked, it is mostly a direct port from txgossip
    # needs more objects rather than using confusing hash/array structures
    #
    # deltas should have their own class and be sortable
    class Scuttle
      attr_reader :me, :peers

      def initialize(me, peers)
        @me = me
        @peers = peers
      end

      def digest
        @peers.each.inject({}) do |digest, (address, peer)|
          digest[address] = peer.max_version_seen
          digest
        end
      end

      def scuttle(digest)
        deltas_with_peer = []
        requests = {}
        new_peers = []
        
        digest.each do |address, digest_version|
          if !@peers.include?(address)
            requests[address] = 0
            new_peers << address
          else
            peer = @peers[address]
            if peer.max_version_seen > digest_version
              deltas_with_peer << [address, peer.deltas_after_version(digest_version)]
            elsif peer.max_version_seen < digest_version
              requests[address] = peer.max_version_seen
            end
          end
        end

        #TODO what is this line doing?        
        deltas_with_peer.sort_by! { |delta| -delta[1].size }

        #TODO this should really be building objects not hashes and arrays
        deltas = []
        deltas_with_peer.each do |address, peer_deltas|
          peer_deltas.each do |key, value, version|
            deltas << [address, key, value, version]
          end
        end

        [deltas, requests, new_peers]
      end

      def update_known_state(deltas)
        deltas.each do |address, key, value, version|
          @peers[address].update_with_delta(key, value, version)
        end
      end

      def fetch_deltas(requests)
        deltas = []
        requests.each do |address, version|
          peer_deltas = @peers[address].deltas_after_version(version)
          peer_deltas.each do |key, value, version|
            deltas << [address, key, value, version]
          end
        end
        deltas
      end
    end
  end
end
