require "../spec_helper"

describe CrDFA::NFA do
  describe "Creation of an NFA from a Parsetree" do
    it "creates a state for a LiteralNode" do
      ast = CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode)
      expected = l_state('a').tap &.out = match_state
      CrDFA::NFA.create_nfa(ast).should eq expected
    end

    it "creates a state for a ConcateNode" do
      it "works for the binary case" do
        ast = CrDFA::ConcatNode.new [
          CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode),
          CrDFA::LiteralNode.new("b").as(CrDFA::ASTNode),
        ]

        expected = l_state('a').tap &.out = l_state('b').tap &.out = match_state
        CrDFA::NFA.create_nfa(ast).should eq expected
      end

      it "works for more than one element in the concatenation" do
        ast = CrDFA::ConcatNode.new [
          CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode),
          CrDFA::LiteralNode.new("b").as(CrDFA::ASTNode),
          CrDFA::LiteralNode.new("c").as(CrDFA::ASTNode),
        ]

        expected = l_state('a').tap &.out = l_state('b').tap &.out = l_state('c').tap &.out = match_state
        CrDFA::NFA.create_nfa(ast).should eq expected
      end
    end

    it "creates a state for an AlternationNode" do
      it "works for the binary case" do
        ast = CrDFA::AlternationNode.new [
          CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode),
          CrDFA::LiteralNode.new("b").as(CrDFA::ASTNode),
        ]

        expected = split_state(
          l_state('a').tap &.out = match_state,
          l_state('b').tap &.out = match_state,
        )

        CrDFA::NFA.create_nfa(ast).should eq expected
      end

      it "works for more than one element in the alternation" do
        ast = CrDFA::AlternationNode.new [
          CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode),
          CrDFA::LiteralNode.new("b").as(CrDFA::ASTNode),
          CrDFA::LiteralNode.new("c").as(CrDFA::ASTNode),
        ]

        expected = split_state(
          l_state('a').tap &.out = match_state,
          split_state(
            l_state('b').tap &.out = match_state,
            l_state('c').tap &.out = match_state
          )
        )

        CrDFA::NFA.create_nfa(ast).should eq expected
      end

      it "creates a state for a QSTMNode(?) Zero-or-One" do
        ast = CrDFA::QSTMNode.new(
          CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode)
        )

        expected = split_state(
          l_state('a').tap &.out = match_state,
          match_state
        )

        CrDFA::NFA.create_nfa(ast).should eq expected
      end

      it "creates a state for a StarNode(*) Zero-or-More" do
        ast = CrDFA::StarNode.new(
          CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode)
        )

        a = l_state('a')
        a.out = split_state(a, match_state)
        expected = split_state(a, match_state)

        CrDFA::NFA.create_nfa(ast).should eq expected
      end

      it "creates a state for a PlusNode(*) One-or-More" do
        ast = CrDFA::PlusNode.new(
          CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode)
        )

        expected = (a = l_state('a')).tap &.out = split_state(a, match_state)

        CrDFA::NFA.create_nfa(ast).should eq expected
      end

      it "creates a state for a CharacterClassNode([a-z]) One-or-More" do
        it "creates a state for the simple range case [a-z]" do
          ast = CrDFA::CharacterClassNode.new(false, Array(String).new, [("a".."z")])
          expected = r_state('a', 'z')

          CrDFA::NFA.create_nfa(ast).should eq expected
        end
      end
    end
  end

  describe "Matching of an Input String against an NFA" do
    it "matches a simple Literal" do
      ast = CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode)
      nfa = CrDFA::NFA.create_nfa(ast)
      CrDFA::NFA.match(nfa, "a").should eq true
      CrDFA::NFA.match(nfa, "b").should eq false
    end

    it "matches a concatenation of simple Literals" do
      ast = CrDFA::ConcatNode.new [
        CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode), CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode),
      ]
      nfa = CrDFA::NFA.create_nfa(ast)
      CrDFA::NFA.match(nfa, "aa").should eq true
      CrDFA::NFA.match(nfa, "ab").should eq false
    end

    it "matches a alternation of simple Literals" do
      ast = CrDFA::AlternationNode.new [
        CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode),
        CrDFA::LiteralNode.new("b").as(CrDFA::ASTNode),
      ]
      nfa = CrDFA::NFA.create_nfa(ast)
      CrDFA::NFA.match(nfa, "a").should eq true
      CrDFA::NFA.match(nfa, "b").should eq true
      CrDFA::NFA.match(nfa, "c").should eq false
    end

    it "matches a alternation of simple Literals" do
      ast = CrDFA::StarNode.new CrDFA::LiteralNode.new("a").as(CrDFA::ASTNode)
      nfa = CrDFA::NFA.create_nfa(ast)
      CrDFA::NFA.match(nfa, "").should eq true
      CrDFA::NFA.match(nfa, "a").should eq true
      CrDFA::NFA.match(nfa, "aa").should eq true
      CrDFA::NFA.match(nfa, "aaaaaaa").should eq true
      CrDFA::NFA.match(nfa, "aaaaaaab").should eq false
    end
  end
end
