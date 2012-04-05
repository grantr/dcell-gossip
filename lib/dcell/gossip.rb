require 'celluloid'
require 'celluloid/zmq'

Celluloid::ZMQ.init

require 'dcell/gossip/server'
require 'dcell/gossip/failure_detector'
require 'dcell/gossip/peer'
require 'dcell/gossip/scuttle'
require 'dcell/gossip/messages'
require 'dcell/gossip/gossiper'


module DCell
  module Gossip
    DEFAULT_PORT = 7787

    class << self
      attr_accessor :addr

      def setup(addr)
        @addr = addr
        
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
