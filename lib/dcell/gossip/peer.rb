module DCell
  module Gossip
    class Peer
      include Celluloid::ZMQ
      # include Celluloid::FSM

      module Messaging
        # Obtain the node's 0MQ socket
        def socket
          return @socket if @socket

          @socket = Celluloid::ZMQ::PushSocket.new
          begin
            @socket.connect addr
          rescue IOError
            @socket.close
            @socket = nil
            raise
          end

          @socket
        end

        def finalize
          @socket.close if @socket
        end

        def send_message(message)
          begin
            message = Marshal.dump(message)
          rescue => ex
            abort ex
          end

          socket << message
        end

        def self.included(base)
          base.send(:alias_method, :<<, :send_message)
        end

      end
      include Messaging

      HEARTBEAT_KEY = '__heartbeat__'

      attr_reader :addr
      attr_reader :timestamp
      attr_reader :attributes

      #TODO add transitions that notify
      # default_state :dead
      # state :alive

      def initialize(addr)
        @addr = addr
        @heart_beat_version = 0

        @detector = FailureDetector.new
        @max_version_seen = 0
        
        @attributes = {}

        # attach self #TODO stack error
        @alive = false
      end

      def alive?
        @alive
        state == :alive
      end

      def mark_alive
        @alive = true
        # transition :alive
      end

      def mark_dead
        @alive = false
        # transition :dead
      end

      #TODO why is @heart_beat_version a separate variable?
      def beat_heart
        @heart_beat_version += 1
        update_local(HEARTBEAT_KEY, @heart_beat_version)
      end

      def update_local(k, v)
        @max_version_seen += 1
        set_key(k, v, @max_version_seen)
      end

      def update_with_delta(k, v, n)
        if n > @max_version_seen
          @max_version_seen = n
          set_key(k, v, n)
          
          if is_heartbeat_key?(k)
            @detector.add(Time.now.to_i)
          end
        end
      end

      def is_heartbeat_key?(key)
        key == HEARTBEAT_KEY
      end

      #TODO make @attributes a VersionedValue hash
      def set_key(key, value, n)
        @attributes[key] = [value, n]
        #TODO value changed notify
      end

      def deltas_after_version(lowest_version)
        deltas = []
        @attributes.each do |key, (value, version)|
          if version > lowest_version
            deltas << [key, value, version]
          end
        end
        deltas.sort_by { |d| d[2] }
      end

      def check
        if @detector.suspicious?
          mark_dead
        else
          mark_alive
        end
      end

    end

  end
end
