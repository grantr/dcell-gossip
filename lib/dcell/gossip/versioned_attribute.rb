module DCell
  module Gossip
    class VersionedAttribute < Struct.new(:value, :version)
    end
  end
end
