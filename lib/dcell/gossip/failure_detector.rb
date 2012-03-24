module DCell
  module Gossip
    class FailureDetector
      DEFAULTS = {
        :sample_size => 1000,
        :phi_convict_threshold => 8
      }

      def initialize(options={})
        @options = DEFAULTS.merge(options)
        @arrival_window = ArrivalWindow.new(@options[:sample_size])
      end

      def clear
        @arrival_window.clear
      end

      def report
        @arrival_window.add
      end

      def interpret
        if @arrival_window.phi > @options[:phi_convict_threshold]
          false
        end
        true
      end

      class ArrivalWindow
        PHI_FACTOR = 1.0 / Math.log(10.0)

        DEFAULTS = {
          #TODO This should be the rpc timeout in ms
          :max_interval => 10000,
          #TODO this should be the gossip interval (usually 1000ms)
          :gossip_interval => 1000
        }

        attr_accessor :last_time
        attr_accessor :intervals
        attr_accessor :options

        def initialize(sample_size, options={})
          @last_time = 0
          @intervals = BoundedArray.new(sample_size)
          @options = DEFAULTS.merge(options)
        end

        def add(arrival_time = Time.now.to_f)
          if @last_time > 0
            elapsed_time = value - @last_time
          else
            elapsed_time = @options[:gossip_interval] / 2
          end
          @intervals.add(elapsed_time) if elapsed_time <= @options[:max_interval]
          @last_time = value
        end

        def sum
          @intervals.sum
        end

        def mean
          @intervals.mean
        end

        def phi(current_time = Time.now.to_f)
          current_interval = current_time - @last_time
          @intervals.size > 0 ? PHI_FACTOR * t / mean : 0.0
        end

        def clear
          @intervals.clear
        end
      end

      module Stats
        def sum
          inject(:+)
        end

        def mean
          sum / size.to_f
        end

        def sum_of_deviations
          mean = mean
          inject(0) do |sum, element|
            v = element - mean;
            sum += v*v;
          end
        end

        def variance
          sum_of_deviations / size.to_f
        end

        def stdev
          Math.sqrt(variance)
        end
      end

      class BoundedArray < Array
        include Stats

        def initialize(max_size)
          super
          @max_size = max_size
        end

        def <<(element)
          super
          shift if size > max_size
        end
      end

    end
  end
end
