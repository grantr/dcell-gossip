module DCell
  module Gossip
    class Server
      include Celluloid::ZMQ

      def initialize(addr)
        @addr   = addr
        @socket = PullSocket.new

        begin
          @socket.bind(@addr)
        rescue IOError
          @socket.close
          raise
        end

        run!
      end

      def run
        while true; handle_message! @socket.read; end
      end

      def finalize
        @socket.close if @socket
      end

      def handle_message(message)
        begin
          message = decode_message message
        rescue InvalidMessageError => ex
          Celluloid::Logger.warn("couldn't decode message: #{ex.class}: #{ex}")
          return
        end

        begin
          @gossiper.handle_message(message)
        rescue Exception => ex
          Celluloid::Logger.crash("DCell::Server: message dispatch failed", ex)
        end
      end

      class InvalidMessageError < StandardError; end # undecodable message

      # Decode incoming messages
      def decode_message(message)
        if message[0..1].unpack("CC") == [Marshal::MAJOR_VERSION, Marshal::MINOR_VERSION]
          begin
            Marshal.load message
          rescue => ex
            raise InvalidMessageError, "invalid message: #{ex}"
          end
        else raise InvalidMessageError, "couldn't determine message format: #{message}"
        end
      end

      # Terminate this server
      # TODO needed?
      def terminate
        @socket.close
        super
      end
    end
  end
end
