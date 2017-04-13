require "./parser"
require "./smart_parsing"

module CrDFA
  class RegExp
    @nfa : CrDFA::NFA::State

    def initialize(expression : String)
      @nfa = CrDFA::NFA.create_nfa(
        CrDFA::SmartParsing.flatten_out_quantifications(
          CrDFA::SmartParsing.detangle_character_ranges(
            CrDFA::Parser.parse(expression)
          )
        )
      )
    end

    def =~(string)
      match(string)
    end

    def match(string)
      CrDFA::NFA.match(@nfa, string)
    end
  end
end
