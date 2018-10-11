module DFA
  module AST
    class ASTNode; end

    class LiteralNode < ASTNode
      getter :value

      def initialize(@value : Char); end

      def to_s
        @value.to_s
      end
    end

    class ConcatNode < ASTNode
      property :nodes

      def initialize(@nodes : Array(ASTNode)); end

      def to_s
        @nodes.map(&.to_s).join
      end
    end

    class WrapperNode < ASTNode
      property :tree

      def initialize(@tree : ASTNode); end

      def tree_to_s
        [LiteralNode, CharacterClassNode, GroupNode].includes?(@tree.class) ? @tree.to_s : "(#{tree.to_s})"
      end
    end

    class AlternationNode < ASTNode
      property :alternatives

      def initialize(@alternatives : Array(ASTNode)); end

      def to_s
        @alternatives.map(&.to_s).join("|")
      end
    end

    class GroupNode < WrapperNode
      def to_s
        "(" + @tree.to_s + ")"
      end
    end

    class StarNode < WrapperNode
      def to_s
        "#{tree_to_s}*"
      end
    end

    class PlusNode < WrapperNode
      def to_s
        "#{tree_to_s}+"
      end
    end

    class QSTMNode < WrapperNode
      def to_s
        "#{tree_to_s}?"
      end
    end

    class QuantifierNode < WrapperNode
      getter :exact, :min, :max

      def initialize(
        @tree : ASTNode, @exact : Int32?,
        @min : Int32? = nil, @max : Int32? = nil
      ); end

      def to_s
        if @exact
          "#{tree_to_s}{#{@exact}}"
        elsif @min && @max
          "#{tree_to_s}{#{@min},#{@max}}"
        else
          "#{tree_to_s}{#{@min},}"
        end
      end
    end

    class CharacterRangeNode < ASTNode
      getter :from, :to

      def initialize(@from : Char, @to : Char); end
    end

    class CharacterClassNode < ASTNode
      setter :source
      getter :negate, :ranges, :characters

      def initialize(
        @negate : Bool, @characters : Array(String),
        @ranges : Array(Range(Char, Char)),
        @source : String = ""
      )
        unless @characters.size > 0 || @ranges.size > 0
          raise "empty character class!"
        end
      end

      def to_s
        r_to_s = @ranges.sort_by(&.begin).map do |r|
          r.begin != r.end ? "#{r.begin}-#{r.end}" : "#{r.begin}"
        end.join
        c_to_s = characters.join
        "[" + (negate ? "^" : "") + r_to_s + c_to_s + "]"
      end
    end
  end
end
