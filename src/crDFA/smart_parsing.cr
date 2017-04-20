# coding: utf-8
require "./traverse"

module DFA
  # implements some parse tree optimizations as described in
  # http://people.wku.edu/guangming.xing/thompsonnfa.pdf
  # chapter 3
  module SmartParsing
    include Traverse

    def self.optimize(tree : ASTNode)
      optimize_combined(tree)
    end

    def self.detangle_character_ranges(tree)
      visit(tree) do |node|
        case node
        when CharacterClassNode
          c_ranges = node.characters.map { |c| (c[0]..c[0]) }
          all_ranges = IntersectionMethods.disjoin(c_ranges + node.ranges).sort_by(&.begin)

          if node.as(CharacterClassNode).negate
            all_ranges = invert_disjunct_character_range_sets(all_ranges)
          end

          options = all_ranges.map { |r| CharacterClassNode.new(false, [] of String, [r]).as(ASTNode) }
          options.size > 1 ? AlternationNode.new(options) :
            options.first
        end
      end
    end

    private def self.invert_disjunct_character_range_sets(ranges)
      ranges.map_with_index do |r, index|
        case index
        when 0 then
          (0.unsafe_chr..r.begin.pred)
        else
          prev = ranges[index-1]
          next if prev.end.succ == r.begin
          (prev.end.succ..r.begin.pred)
        end.as(Range(Char, Char)?)
      end.compact.flatten + [
        (ranges.last.end.succ..Char::MAX_CODEPOINT.unsafe_chr)
      ]
    end

    def self.flatten_out_quantifications(tree)
      visit(tree) do |node|
        case node
        when QuantifierNode
          min, max, exact = node.min, node.max, node.exact
          cnode = node.as(QuantifierNode)
          if exact && exact > 0
            c = exact.times.to_a.map { cnode.tree }
            ConcatNode.new c.not_nil!
          elsif min && min > 0 && max && max > 0
            ConcatNode.new(
              min.times.to_a.map { cnode.tree }.not_nil! +
              (max - min).times.to_a.map { QSTMNode.new(cnode.tree) }
            )
          elsif min && min > 0
            ConcatNode.new(
              (min > 1 ? (min - 1).times.to_a.map { cnode.tree }.not_nil! : [] of ASTNode) << PlusNode.new cnode.tree
            )
          end
        end
      end
    end

    def self.optimize_combined(tree)
      visit(tree) do |node|
        case node
        when GroupNode
          # (A) => A
          node.tree
        when StarNode
          case node.tree
          when StarNode
            # A** => A*
            node.tree
          when AlternationNode
            # (A*|B*)* => (A|B)*
            # (A*|B)* => (A|B)*
            ntree = node.tree.as(AlternationNode)
            if ntree.alternatives.any?(&.is_a? StarNode)
              StarNode.new AlternationNode.new(
                ntree.alternatives.map { |a| a.is_a?(StarNode) ? a.tree : a }
              )
            end
          when ConcatNode
            ntree = node.tree.as(ConcatNode)
            if ntree.nodes.all?(&.is_a? StarNode)
              # (A*B*)* => (A|B)*
              StarNode.new AlternationNode.new(
                ntree.nodes.map &.as(StarNode).tree
              )
            end
          end
        end
      end
    end
  end
end
