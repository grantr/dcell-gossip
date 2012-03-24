module DCell
  module Gossip
    class VersionedValue < Struct.new(:value, :version)
    end
  end
end
