require 'rubygems'
require 'bundler'
Bundler.setup

require 'dcell/gossip'

port = ARGV[0]
raise "port is required first argument" unless port

seed_ports = ARGV[1, ARGV.size]
seeds = seeds ? seeds.collect { |s| "tcp://127.0.0.1:#{s}"} : [] 
DCell::Gossip.setup("tcp://127.0.0.1:#{port}", :seeds => seeds)

DCell::Gossip.run
