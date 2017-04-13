module CrDFA
  module Traverse
    macro included

      def self.visit(node : WrapperNode, &block : ASTNode -> ASTNode?)
        node.tree = self.visit(node.tree, &block) || node.tree
        block.call(node) || node
      end

      def self.visit(node : ConcatNode, &block : ASTNode -> ASTNode?)
        node.nodes = node.nodes.map do |n|
          visit(n, &block) || n
        end
        block.call(node) || node
      end

      def self.visit(node : AlternationNode, &block : ASTNode -> ASTNode?)
        node.alternatives = node.alternatives.map do |n|
          visit(n, &block) || n
        end
        block.call(node) || node
      end

      def self.visit(node : ASTNode, &block : ASTNode -> ASTNode?)
        block.call(node) || node
      end

    end
  end
end
