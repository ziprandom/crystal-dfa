require "./parser"
require "./smart_parsing"

module DFA
  class RegExp
    getter :nfa, :dfa

    @nfa : NFA::State
    @dfa : DFA::DState

    def initialize(expression : String)
      @nfa = NFA.create_nfa(
        SmartParsing.flatten_out_quantifications(
          SmartParsing.detangle_character_ranges(
            Parser.parse(expression)
          )
        )
      )
      @dfa = DFA.fromNFA @nfa
    end

    def =~(string)
      match(string)
    end

    def match(string, use_dfa = true, full_match = true)
      use_dfa ? DFA.match(@dfa, string, full_match) : NFA.match(@nfa, string)
    end
  end
end
