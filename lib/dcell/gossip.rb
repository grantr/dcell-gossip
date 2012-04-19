require 'celluloid'
require 'celluloid/zmq'

Celluloid::ZMQ.init

require 'dcell/gossip/server'
require 'dcell/gossip/failure_detector'
require 'dcell/gossip/peer'
require 'dcell/gossip/peers'
require 'dcell/gossip/scuttle'
require 'dcell/gossip/messages'
require 'dcell/gossip/gossiper'


module DCell
  module Gossip
    class << self
      attr_accessor :addr, :seeds

      def setup(addr, options={})
        @addr = addr
        @seeds = Array(options[:seeds])
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
