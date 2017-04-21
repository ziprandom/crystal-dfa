module DFA
  module Traverse
    macro included

      alias BlockType = AST::ASTNode -> AST::ASTNode?

      def self.visit(node : AST::WrapperNode, &block : BlockType)
        node.tree = self.visit(node.tree, &block) || node.tree
        block.call(node) || node
      end

      def self.visit(node : AST::ConcatNode, &block : BlockType)
        node.nodes = node.nodes.map do |n|
          visit(n, &block) || n
        end
        block.call(node) || node
      end

      def self.visit(node : AST::AlternationNode, &block : BlockType)
        node.alternatives = node.alternatives.map do |n|
          visit(n, &block) || n
        end
        block.call(node) || node
      end

      def self.visit(node : AST::ASTNode, &block : BlockType)
        block.call(node) || node
      end

    end
  end
end
