module DCell
  module Gossip
    class Peer
      include Celluloid::ZMQ
      include Celluloid::FSM

      #TODO can the socket from this class be aggregated into Peers?
      module Messaging
        # Obtain the node's 0MQ socket
        def socket
          return @socket if @socket

          @socket = Celluloid::ZMQ::PushSocket.new
          begin
            @socket.connect address
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

      attr_reader :address
      attr_reader :timestamp
      attr_reader :attributes
      attr_reader :max_version_seen
      attr_reader :detector

      #TODO add transitions that notify
      default_state :dead
      state :alive do
        Celluloid::Logger.info "#{address} is alive."
      end
      state :dead do 
        Celluloid::Logger.info "#{address} is dead."
      end

      def initialize(address)
        @address = address

        @detector = FailureDetector.new
        @max_version_seen = 0

        beat_heart
        
        attach self
      end

      def attributes
        @attributes ||= {}
      end

      def alive?
        state == :alive
      end

      def mark_alive
        transition :alive
      end

      def mark_dead
        transition :dead
      end

      def beat_heart
        update(HEARTBEAT_KEY, (self[HEARTBEAT_KEY] || 0) + 1)
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

      def [](key)
        attributes.has_key?(key) ? attributes[key].first : nil
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
