# coding: utf-8
require "./traverse"

module DFA
  # implements some parse tree optimizations as described in
  # http://people.wku.edu/guangming.xing/thompsonnfa.pdf
  # chapter 3
  module SmartParsing
    include DFA::Traverse

    def self.optimize(tree : ASTNode)
      optimize_combined(tree)
    end

    def self.detangle_character_ranges(tree)
      visit(tree) do |node|
        case node
        when DFA::CharacterClassNode
          # no negation support atm
          split_ranges = node.ranges.map do |r|
            DFA::CharacterClassNode.new(false, Array(String).new, [r])
          end
          split_literals = node.characters.reject do |s|
            # remove characters that are already
            # included in a range
            node.ranges.any? &.includes? s
          end.map do |s|
            DFA::LiteralNode.new(s)
          end
          DFA::AlternationNode.new(split_ranges + split_literals)
        end
      end
    end

    def self.flatten_out_quantifications(tree)
      visit(tree) do |node|
        case node
        when DFA::QuantifierNode
          min, max, exact = node.min, node.max, node.exact
          cnode = node.as(DFA::QuantifierNode)
          if exact && exact > 0
            c = exact.times.to_a.map { cnode.tree }
            DFA::ConcatNode.new c.not_nil!
          elsif min && min > 0 && max && max > 0
            DFA::ConcatNode.new(
              min.times.to_a.map { cnode.tree }.not_nil! +
              (max - min).times.to_a.map { DFA::QSTMNode.new(cnode.tree) }
            )
          elsif min && min > 0
            DFA::ConcatNode.new(
              (min > 1 ? (min - 1).times.to_a.map { cnode.tree }.not_nil! : [] of ASTNode) << DFA::PlusNode.new cnode.tree
            )
          end
        end
      end
    end

    def self.optimize_combined(tree)
      visit(tree) do |node|
        case node
        when DFA::GroupNode
          # (A) => A
          node.tree
        when DFA::StarNode
          case node.tree
          when DFA::StarNode
            # A** => A*
            node.tree
          when DFA::AlternationNode
            # (A*|B*)* => (A|B)*
            # (A*|B)* => (A|B)*
            ntree = node.tree.as(DFA::AlternationNode)
            if ntree.alternatives.any?(&.is_a? DFA::StarNode)
              DFA::StarNode.new DFA::AlternationNode.new(
                ntree.alternatives.map { |a| a.is_a?(DFA::StarNode) ? a.tree : a }
              )
            end
          when DFA::ConcatNode
            ntree = node.tree.as(DFA::ConcatNode)
            if ntree.nodes.all?(&.is_a? DFA::StarNode)
              # (A*B*)* => (A|B)*
              DFA::StarNode.new DFA::AlternationNode.new(
                ntree.nodes.map &.as(DFA::StarNode).tree
              )
            end
          end
        end
      end
    end
  end
end
