module DCell
  module Gossip
    class Peers < Hash
      attr_accessor :me

      def initialize(me)
        @me = me
        add(me)
      end

      def add(addresses)
        Array(addresses).inject(self) do |peers, address|
          peers[address] ||= Peer.new(address) unless peers[address]
          peers
        end
      end

      def live
        collect { |address, peer| peer if peer.alive? && address != @me }.compact
      end

      def dead
        collect { |address, peer| peer if !peer.alive? && address != @me }.compact
      end

      module Scuttle
        def digest
          inject({}) do |digest, (address, peer)|
            digest[address] = peer.max_version_seen
            digest
          end
        end

        def update(deltas)
          deltas.each do |address, delta|
            delta.each do |key, attribute|
              self[address].update(key, attribute.value, attribute.version)
            end
          end
        end

        def fetch_deltas(requests)
          requests.inject({}) do |deltas, (address, version)|
            deltas[address] = self[address].deltas_after(version)
            deltas
          end
        end

        #TODO requests is actually the same as a digest
        def unpack(digest)
          deltas = {}
          requests = {}

          digest.each do |address, digest_version|
            peer = self[address]
            if peer
              # peer already exists, find out who is more current
              if peer.max_version_seen > digest_version
                deltas[address] = peer.deltas_after(digest_version)
              elsif peer.max_version_seen < digest_version
                requests[address] = peer.max_version_seen
              end
            else
              # peer is new, ask for info
              requests[address] = 0
              add(address)
            end
          end

          # sort by peers with most deltas
          deltas = Hash[deltas.sort_by { |address, delta| delta.size }]

          [deltas, requests]
        end
      end
      include Scuttle
    end
  end
end
