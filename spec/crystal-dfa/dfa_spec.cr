require "../spec_helper"

describe DFA::DFA do
  describe "Creation of a DFA from an NFA through power set construction" do
    pending "creates a state for a LiteralNode" do
      # expression = "([a-z]|[a-d])[a,d]?(x|y)"
      expression = "(a|b)c"
      rex = DFA::RegExp.new expression
      DFA::DFA.fromNFA(rex.nfa).should eq "This very awesome DFA"
    end
  end
end
