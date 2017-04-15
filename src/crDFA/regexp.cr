require "./parser"
require "./smart_parsing"

module DFA
  class RegExp
    getter :nfa
    @nfa : DFA::NFA::State

    def initialize(expression : String)
      @nfa = DFA::NFA.create_nfa(
        DFA::SmartParsing.flatten_out_quantifications(
          DFA::SmartParsing.detangle_character_ranges(
            DFA::Parser.parse(expression)
          )
        )
      )
    end

    def =~(string)
      match(string)
    end

    def match(string)
      DFA::NFA.match(@nfa, string)
    end
  end
end
