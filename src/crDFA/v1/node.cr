module CrDFA
  module V1
    class Node
      property :next, :prev, :name, :position, :group_start

      @name = ""
      @position = 0
      @group_start : Node?
      @next = [] of Node
      @prev = [] of Node

      def initialize(@next = [] of Node); end

      def connect(node : Node)
        unless @next.includes? node
          @next << node
          node.prev << self
        end
      end

      def disconnect(node : Node)
        @next.delete(node)
      end

      def swap_nodes(old : Node, new : Node)
        raise "#{old} wasn't connected to #{self}" unless @next.includes? old
        disconnect(old)
        connect(new)
      end

      def enter?(c : String)
        true
      end

      def size
        0
      end
    end

    class PassThroughNode < Node
      def enter?(c : String)
        true
      end

      def size
        0
      end
    end

    class CharacterClassNode < Node
      def initialize(@negative : Bool, @characters : Array(String), @ranges : Array(Range(String, String))); end

      def enter?(rest : String)
        return false if rest.blank?
        token = rest[0].to_s
        if @negative
          unless @characters.includes?(token) ||
                 @ranges.reduce(false) { |memo, range| break if memo; token.in? range }
            true
          else
            false
          end
        else
          return true if token.in? @characters
          @ranges.each { |range| return true if token.in? range }
          false
        end
      end

      def size
        1
      end
    end

    class LiteralNode < Node
      getter :match

      def initialize(@match : String, @next = [] of Node)
        @name = @match
      end

      def enter?(rest : String)
        rest.starts_with?(@match)
      end

      def size
        @match.size
      end
    end
  end
end
