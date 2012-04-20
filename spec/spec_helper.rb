require 'rubygems'
require 'bundler'
Bundler.setup

require 'dcell/gossip'
Dir['./spec/support/*.rb'].map { |f| require f }

# maybe this should be something the tests set up?
$seed = TestSeed.new
$seed.wait_until_ready

$peer = TestPeer.new
$peer.wait_until_ready

at_exit do
  $seed.stop
  $peer.stop
end
