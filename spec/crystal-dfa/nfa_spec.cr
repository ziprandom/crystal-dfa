require "../spec_helper"

describe DFA::NFA do
  describe "Creation of an NFA from a Parsetree" do
    it "creates a state for a LiteralNode" do
      ast = DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode)
      expected = l_state('a').tap &.out = match_state
      DFA::NFA.create_nfa(ast).should eq expected
    end

    describe "creates a state for a ConcateNode" do
      it "works for the binary case" do
        ast = DFA::AST::ConcatNode.new [
          DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode),
          DFA::AST::LiteralNode.new('b').as(DFA::AST::ASTNode),
        ]

        expected = l_state('a').tap &.out = l_state('b').tap &.out = match_state
        DFA::NFA.create_nfa(ast).should eq expected
      end

      it "works for more than one element in the concatenation" do
        ast = DFA::AST::ConcatNode.new [
          DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode),
          DFA::AST::LiteralNode.new('b').as(DFA::AST::ASTNode),
          DFA::AST::LiteralNode.new('c').as(DFA::AST::ASTNode),
        ]

        expected = l_state('a').tap &.out = l_state('b').tap &.out = l_state('c').tap &.out = match_state
        DFA::NFA.create_nfa(ast).should eq expected
      end
    end

    describe "creates a state for an AlternationNode" do
      it "works for the binary case" do
        ast = DFA::AST::AlternationNode.new [
          DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode),
          DFA::AST::LiteralNode.new('b').as(DFA::AST::ASTNode),
        ]

        expected = split_state(
          l_state('a').tap &.out = match_state,
          l_state('b').tap &.out = match_state,
        )

        DFA::NFA.create_nfa(ast).should eq expected
      end

      it "works for more than one element in the alternation" do
        ast = DFA::AST::AlternationNode.new [
          DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode),
          DFA::AST::LiteralNode.new('b').as(DFA::AST::ASTNode),
          DFA::AST::LiteralNode.new('c').as(DFA::AST::ASTNode),
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
        ast = DFA::AST::QSTMNode.new(
          DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode)
        )

        expected = split_state(
          l_state('a').tap &.out = match_state,
          match_state
        )

        DFA::NFA.create_nfa(ast).should eq expected
      end

      it "creates a state for a StarNode(*) Zero-or-More" do
        ast = DFA::AST::StarNode.new(
          DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode)
        )

        a = l_state('a')
        a.out = split_state(a, match_state)
        expected = split_state(a, match_state)

        DFA::NFA.create_nfa(ast).should eq expected
      end

      it "creates a state for a PlusNode(*) One-or-More" do
        ast = DFA::AST::PlusNode.new(
          DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode)
        )

        expected = (a = l_state('a')).tap &.out = split_state(a, match_state)

        DFA::NFA.create_nfa(ast).should eq expected
      end

      describe "creates a state for a CharacterClassNode([a-z]) One-or-More" do
        it "creates a state for the simple range case [a-z]" do
          ast = DFA::AST::CharacterClassNode.new(false, Array(String).new, [('a'..'z')])
          expected = r_state('a', 'z')

          DFA::NFA.create_nfa(ast).should eq expected
        end

        # ^[a-z] => [''...'a']|[('z'.succ)..MAX_CODEPOINT]
        # it "creates a split state for the negative character range case [^a-z]" do
        #   ast = DFA::AST::CharacterClassNode.new(true, Array(String).new, [('a'..'z')])
        #   expected = split_state(
        #     r_state(0.unsafe_chr, 'a'.pred),
        #     r_state('z'.succ, (Char::MAX_CODEPOINT-1).unsafe_chr)
        #   )
        #   DFA::NFA.create_nfa(ast).should eq expected
        # end

      end
    end
  end

  describe "Matching of an Input String against an NFA" do
    it "matches a simple Literal" do
      ast = DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode)
      nfa = DFA::NFA.create_nfa(ast)
      DFA::NFA.match(nfa, "a").should eq true
      DFA::NFA.match(nfa, "b").should eq false
    end

    it "matches a concatenation of simple Literals" do
      ast = DFA::AST::ConcatNode.new [
        DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode), DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode),
      ]
      nfa = DFA::NFA.create_nfa(ast)
      DFA::NFA.match(nfa, "aa").should eq true
      DFA::NFA.match(nfa, "ab").should eq false
    end

    it "matches a alternation of simple Literals" do
      ast = DFA::AST::AlternationNode.new [
        DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode),
        DFA::AST::LiteralNode.new('b').as(DFA::AST::ASTNode),
      ]
      nfa = DFA::NFA.create_nfa(ast)
      DFA::NFA.match(nfa, "a").should eq true
      DFA::NFA.match(nfa, "b").should eq true
      DFA::NFA.match(nfa, "c").should eq false
    end

    it "matches a alternation of simple Literals" do
      ast = DFA::AST::StarNode.new DFA::AST::LiteralNode.new('a').as(DFA::AST::ASTNode)
      nfa = DFA::NFA.create_nfa(ast)
      DFA::NFA.match(nfa, "").should eq true
      DFA::NFA.match(nfa, "a").should eq true
      DFA::NFA.match(nfa, "aa").should eq true
      DFA::NFA.match(nfa, "aaaaaaa").should eq true
      DFA::NFA.match(nfa, "aaaaaaab").should eq false
    end

    it "matches a character class" do
      ast = DFA::AST::CharacterClassNode.new false, [] of String, [('a'..'z')]
      nfa = DFA::NFA.create_nfa(ast)
      DFA::NFA.match(nfa, "a").should eq true
      DFA::NFA.match(nfa, "b").should eq true
      DFA::NFA.match(nfa, "z").should eq true
      DFA::NFA.match(nfa, "A").should eq false
      DFA::NFA.match(nfa, "12").should eq false
    end

    # it "matches a negative character class" do
    #   ast = DFA::AST::CharacterClassNode.new true, [] of String, [('a'..'z')]
    #   nfa = DFA::NFA.create_nfa(ast)
    #   DFA::NFA.match(nfa, "a").should eq false
    #   DFA::NFA.match(nfa, "b").should eq false
    #   DFA::NFA.match(nfa, "z").should eq false
    #   DFA::NFA.match(nfa, "A").should eq true
    #   DFA::NFA.match(nfa, "2").should eq true
    # end

  end
end
