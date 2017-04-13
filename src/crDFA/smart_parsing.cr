# coding: utf-8
require "./traverse"

module CrDFA
  # implements some parse tree optimizations as described in
  # http://people.wku.edu/guangming.xing/thompsonnfa.pdf
  # chapter 3
  module SmartParsing
    include CrDFA::Traverse

    def self.optimize(tree : ASTNode)
      optimize_combined(tree)
    end

    def self.detangle_character_ranges(tree)
      visit(tree) do |node|
        case node
        when CrDFA::CharacterClassNode
          # no negation support atm
          split_ranges = node.ranges.map do |r|
            CrDFA::CharacterClassNode.new(false, Array(String).new, [r])
          end
          split_literals = node.characters.reject do |s|
            # remove characters that are already
            # included in a range
            node.ranges.any? &.includes? s
          end.map do |s|
            CrDFA::LiteralNode.new(s)
          end
          CrDFA::AlternationNode.new(split_ranges + split_literals)
        end
      end
    end

    def self.flatten_out_quantifications(tree)
      visit(tree) do |node|
        case node
        when CrDFA::QuantifierNode
          min, max, exact = node.min, node.max, node.exact
          cnode = node.as(CrDFA::QuantifierNode)
          if exact && exact > 0
            c = exact.times.to_a.map { cnode.tree }
            CrDFA::ConcatNode.new c.not_nil!
          elsif min && min > 0 && max && max > 0
            CrDFA::ConcatNode.new(
              min.times.to_a.map { cnode.tree }.not_nil! +
              (max - min).times.to_a.map { CrDFA::QSTMNode.new(cnode.tree) }
            )
          elsif min && min > 0
            CrDFA::ConcatNode.new(
              (min > 1 ? (min - 1).times.to_a.map { cnode.tree }.not_nil! : [] of ASTNode) << CrDFA::PlusNode.new cnode.tree
            )
          end
        end
      end
    end

    def self.optimize_combined(tree)
      visit(tree) do |node|
        case node
        when CrDFA::GroupNode
          # (A) => A
          node.tree
        when CrDFA::StarNode
          case node.tree
          when CrDFA::StarNode
            # A** => A*
            node.tree
          when CrDFA::AlternationNode
            # (A*|B*)* => (A|B)*
            # (A*|B)* => (A|B)*
            ntree = node.tree.as(CrDFA::AlternationNode)
            if ntree.alternatives.any?(&.is_a? CrDFA::StarNode)
              CrDFA::StarNode.new CrDFA::AlternationNode.new(
                ntree.alternatives.map { |a| a.is_a?(CrDFA::StarNode) ? a.tree : a }
              )
            end
          when CrDFA::ConcatNode
            ntree = node.tree.as(CrDFA::ConcatNode)
            if ntree.nodes.all?(&.is_a? CrDFA::StarNode)
              # (A*B*)* => (A|B)*
              CrDFA::StarNode.new CrDFA::AlternationNode.new(
                ntree.nodes.map &.as(CrDFA::StarNode).tree
              )
            end
          end
        end
      end
    end
  end
end
