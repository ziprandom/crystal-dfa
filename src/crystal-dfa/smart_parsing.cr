# coding: utf-8
require "./traverse"

module DFA
  # implements some parse tree optimizations as described in
  # http://people.wku.edu/guangming.xing/thompsonnfa.pdf
  # chapter 3
  module SmartParsing
    include Traverse

    def self.optimize(tree : AST::ASTNode)
      optimize_combined(tree)
    end

    def self.detangle_character_ranges(tree)
      visit(tree) do |node|
        case node
        when AST::CharacterClassNode
          c_ranges = node.characters.map { |c| (c[0]..c[0]) }
          all_ranges = IntersectionMethods.disjoin(c_ranges + node.ranges).sort_by(&.begin)

          if node.as(AST::CharacterClassNode).negate
            all_ranges = invert_disjunct_character_range_sets(all_ranges)
          end

          options = all_ranges.map { |r| AST::CharacterClassNode.new(false, [] of String, [r]).as(AST::ASTNode) }
          options.size > 1 ? AST::AlternationNode.new(options) : options.first
        end
      end
    end

    private def self.invert_disjunct_character_range_sets(ranges)
      ranges.map_with_index do |r, index|
        case index
        when 0
          (0.unsafe_chr..r.begin.pred)
        else
          prev = ranges[index - 1]
          next if prev.end.succ == r.begin
          (prev.end.succ..r.begin.pred)
        end.as(Range(Char, Char)?)
      end.compact.flatten + [
        (ranges.last.end.succ..Char::MAX_CODEPOINT.unsafe_chr),
      ]
    end

    def self.flatten_out_quantifications(tree)
      visit(tree) do |node|
        case node
        when AST::QuantifierNode
          min, max, exact = node.min, node.max, node.exact
          cnode = node.as(AST::QuantifierNode)
          if exact && exact > 0
            c = exact.times.to_a.map { cnode.tree }
            AST::ConcatNode.new c.not_nil!
          elsif min && min > 0 && max && max > 0
            AST::ConcatNode.new(
              min.times.to_a.map { cnode.tree }.not_nil! +
              (max - min).times.to_a.map { AST::QSTMNode.new(cnode.tree) }
            )
          elsif min && min > 0
            AST::ConcatNode.new(
              (min > 1 ? (min - 1).times.to_a.map { cnode.tree }.not_nil! : [] of AST::ASTNode) << AST::PlusNode.new cnode.tree
            )
          end
        end
      end
    end

    def self.optimize_combined(tree)
      visit(tree) do |node|
        case node
        when AST::GroupNode
          # (A) => A
          node.tree
        when AST::StarNode
          case node.tree
          when AST::StarNode
            # A** => A*
            node.tree
          when AST::AlternationNode
            # (A*|B*)* => (A|B)*
            # (A*|B)* => (A|B)*
            ntree = node.tree.as(AST::AlternationNode)
            if ntree.alternatives.any?(&.is_a? AST::StarNode)
              AST::StarNode.new AST::AlternationNode.new(
                ntree.alternatives.map { |a| a.is_a?(AST::StarNode) ? a.tree : a }
              )
            end
          when AST::ConcatNode
            ntree = node.tree.as(AST::ConcatNode)
            if ntree.nodes.all?(&.is_a? AST::StarNode)
              # (A*B*)* => (A|B)*
              AST::StarNode.new AST::AlternationNode.new(
                ntree.nodes.map &.as(AST::StarNode).tree
              )
            end
          end
        end
      end
    end
  end
end
