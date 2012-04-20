require 'celluloid'
require 'celluloid/zmq'

Celluloid::ZMQ.init

require 'dcell/gossip/server'
require 'dcell/gossip/failure_detector'
require 'dcell/gossip/versioned_attribute'
require 'dcell/gossip/peer'
require 'dcell/gossip/peers'
require 'dcell/gossip/messages'
require 'dcell/gossip/gossiper'

module DCell
  module Gossip
    class << self
      attr_accessor :address, :seeds

      def setup(address, options={})
        @address = address
        @seeds = Array(options[:seeds])
        nil
      end

      def run
        DCell::Gossip::Group.run
      end

      def run!
        DCell::Gossip::Group.run!
      end
    end

    class Group < Celluloid::Group
      supervise Gossiper, :as => :gossiper
      supervise Server
    end
  end
end
