module DCell
  module Registry
    class GossipAdapter

      def initialize(options)
        # Convert all options to symbols :/
        options = options.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }

        @node_registry   = NodeRegistry.new
        @global_registry = GlobalRegistry.new
      end

      class NodeRegistry

        def initialize
        end

        def get(node_id)
        end

        def set(node_id, addr)
        end

        def nodes
        end

        def clear
        end
      end

      def get_node(node_id);       @node_registry.get(node_id) end
      def set_node(node_id, addr); @node_registry.set(node_id, addr) end
      def nodes;                   @node_registry.nodes end
      def clear_nodes;             @node_registry.clear end

      class GlobalRegistry
        def initialize
        end

        def get(key)
        end

        def set(key, value)
        end

        def global_keys
        end

        def clear
        end
      end

      def get_global(key);        @global_registry.get(key) end
      def set_global(key, value); @global_registry.set(key, value) end
      def global_keys;            @global_registry.global_keys end
      def clear_globals;           @global_registry.clear end
    end
  end
end
