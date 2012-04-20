# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dcell/gossip/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Grant Rodgers"]
  gem.email         = ["grantr@gmail.com"]
  gem.description   = %q{Gossip protocol using Celluloid and 0MQ}
  gem.summary       = %q{DCell::Gossip is a gossip protocol similar to that used by Cassandra. It is intended as a masterless registry for DCell but does not require DCell to function.}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "dcell-gossip"
  gem.require_paths = ["lib"]
  gem.version       = Dcell::Gossip::VERSION

  gem.add_runtime_dependency "celluloid-zmq"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "dcell" # For shared registry examples
end
