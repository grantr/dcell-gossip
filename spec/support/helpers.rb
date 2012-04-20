# For Gem.ruby, and almost certainly already loaded
require 'rubygems'

class TestPeer
  DEFAULT_PORT = "7781"
  DEFAULT_SEED_PORT = "7780"

  def initialize(port=DEFAULT_PORT, seed_ports=[DEFAULT_SEED_PORT])
    @port = port
    @seed_ports = seed_ports
    @pid = Process.spawn Gem.ruby, File.expand_path("../../test_peer.rb", __FILE__), @port, *@seed_ports
  end

  def wait_until_ready
    STDERR.print "Waiting for #{self.class.name}:#{@port} to start up..."

    socket = nil
    30.times do
      begin
        socket = TCPSocket.open("127.0.0.1", @port)
        break if socket
      rescue Errno::ECONNREFUSED
        STDERR.print "."
        sleep 1
      end
    end

    if socket
      STDERR.puts " done!"
      socket.close
    else
      STDERR.puts " FAILED!"
      raise "couldn't connect to #{self.class.name}:#{@port}!"
    end
  end

  def stop
    Process.kill 9, @pid
  rescue Errno::ESRCH
  ensure
    Process.wait @pid rescue nil
  end
end

class TestSeed < TestPeer
  def initialize(port=DEFAULT_SEED_PORT)
    @port = port
    @pid = Process.spawn Gem.ruby, File.expand_path("../../test_peer.rb", __FILE__), @port
  end
  
end
