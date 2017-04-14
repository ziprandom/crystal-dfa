require "../spec_helper"

describe DFA::NFA do
  describe "Creation of an NFA from a Parsetree" do
    it "creates a state for a LiteralNode" do
      ast = DFA::LiteralNode.new("a").as(DFA::ASTNode)
      expected = l_state('a').tap &.out = match_state
      DFA::NFA.create_nfa(ast).should eq expected
    end

    it "creates a state for a ConcateNode" do
      it "works for the binary case" do
        ast = DFA::ConcatNode.new [
          DFA::LiteralNode.new("a").as(DFA::ASTNode),
          DFA::LiteralNode.new("b").as(DFA::ASTNode),
        ]

        expected = l_state('a').tap &.out = l_state('b').tap &.out = match_state
        DFA::NFA.create_nfa(ast).should eq expected
      end

      it "works for more than one element in the concatenation" do
        ast = DFA::ConcatNode.new [
          DFA::LiteralNode.new("a").as(DFA::ASTNode),
          DFA::LiteralNode.new("b").as(DFA::ASTNode),
          DFA::LiteralNode.new("c").as(DFA::ASTNode),
        ]

        expected = l_state('a').tap &.out = l_state('b').tap &.out = l_state('c').tap &.out = match_state
        DFA::NFA.create_nfa(ast).should eq expected
      end
    end

    it "creates a state for an AlternationNode" do
      it "works for the binary case" do
        ast = DFA::AlternationNode.new [
          DFA::LiteralNode.new("a").as(DFA::ASTNode),
          DFA::LiteralNode.new("b").as(DFA::ASTNode),
        ]

        expected = split_state(
          l_state('a').tap &.out = match_state,
          l_state('b').tap &.out = match_state,
        )

        DFA::NFA.create_nfa(ast).should eq expected
      end

      it "works for more than one element in the alternation" do
        ast = DFA::AlternationNode.new [
          DFA::LiteralNode.new("a").as(DFA::ASTNode),
          DFA::LiteralNode.new("b").as(DFA::ASTNode),
          DFA::LiteralNode.new("c").as(DFA::ASTNode),
        ]

        expected = split_state(
          l_state('a').tap &.out = match_state,
          split_state(
            l_state('b').tap &.out = match_state,
            l_state('c').tap &.out = match_state
          )
        )

        DFA::NFA.create_nfa(ast).should eq expected
      end

      it "creates a state for a QSTMNode(?) Zero-or-One" do
        ast = DFA::QSTMNode.new(
          DFA::LiteralNode.new("a").as(DFA::ASTNode)
        )

        expected = split_state(
          l_state('a').tap &.out = match_state,
          match_state
        )

        DFA::NFA.create_nfa(ast).should eq expected
      end

      it "creates a state for a StarNode(*) Zero-or-More" do
        ast = DFA::StarNode.new(
          DFA::LiteralNode.new("a").as(DFA::ASTNode)
        )

        a = l_state('a')
        a.out = split_state(a, match_state)
        expected = split_state(a, match_state)

        DFA::NFA.create_nfa(ast).should eq expected
      end

      it "creates a state for a PlusNode(*) One-or-More" do
        ast = DFA::PlusNode.new(
          DFA::LiteralNode.new("a").as(DFA::ASTNode)
        )

        expected = (a = l_state('a')).tap &.out = split_state(a, match_state)

        DFA::NFA.create_nfa(ast).should eq expected
      end

      it "creates a state for a CharacterClassNode([a-z]) One-or-More" do
        it "creates a state for the simple range case [a-z]" do
          ast = DFA::CharacterClassNode.new(false, Array(String).new, [("a".."z")])
          expected = r_state('a', 'z')

          DFA::NFA.create_nfa(ast).should eq expected
        end
      end
    end
  end

  describe "Matching of an Input String against an NFA" do
    it "matches a simple Literal" do
      ast = DFA::LiteralNode.new("a").as(DFA::ASTNode)
      nfa = DFA::NFA.create_nfa(ast)
      DFA::NFA.match(nfa, "a").should eq true
      DFA::NFA.match(nfa, "b").should eq false
    end

    it "matches a concatenation of simple Literals" do
      ast = DFA::ConcatNode.new [
        DFA::LiteralNode.new("a").as(DFA::ASTNode), DFA::LiteralNode.new("a").as(DFA::ASTNode),
      ]
      nfa = DFA::NFA.create_nfa(ast)
      DFA::NFA.match(nfa, "aa").should eq true
      DFA::NFA.match(nfa, "ab").should eq false
    end

    it "matches a alternation of simple Literals" do
      ast = DFA::AlternationNode.new [
        DFA::LiteralNode.new("a").as(DFA::ASTNode),
        DFA::LiteralNode.new("b").as(DFA::ASTNode),
      ]
      nfa = DFA::NFA.create_nfa(ast)
      DFA::NFA.match(nfa, "a").should eq true
      DFA::NFA.match(nfa, "b").should eq true
      DFA::NFA.match(nfa, "c").should eq false
    end

    it "matches a alternation of simple Literals" do
      ast = DFA::StarNode.new DFA::LiteralNode.new("a").as(DFA::ASTNode)
      nfa = DFA::NFA.create_nfa(ast)
      DFA::NFA.match(nfa, "").should eq true
      DFA::NFA.match(nfa, "a").should eq true
      DFA::NFA.match(nfa, "aa").should eq true
      DFA::NFA.match(nfa, "aaaaaaa").should eq true
      DFA::NFA.match(nfa, "aaaaaaab").should eq false
    end
  end
end
