require "./nfa"

module DFA
  module DFA
    extend NFA::ClassMethods

    alias AtomType = Tuple(Int32, Int32)

    struct DState
      getter :l, :next, :accept
      @accept = false

      def initialize(
        @l : Array(NFA::State),
        @next = Array({AtomType, DState}).new
      )
        @accept = @l.any? &.c.== NFA::MATCH
      end
    end

    class MatchData
      getter :match

      def initialize(@match : String); end
    end

    def self.match(start : NFA::State, string : String)
      dfa = fromNFA(symbols, start)
      self.match(dfa, string)
    end

    def self.match(dfa : DState, string : String, full_match = false)
      match_end, d = -1, dfa
      string.each_char_with_index do |c, i|
        break unless d
        d = d.next.find { |x| x[0][0] <= c.ord <= x[0][1] }.try &.[1]
        match_end = i + 1 if d && d.accept
      end
      full_match ? (d.try &.accept ? MatchData.new(string) : nil) : (match_end > 0 ? MatchData.new(string[0, match_end]) : nil)
    end

    def self.fromNFA(start : NFA::State)
      listid, startlist, dstate_cache = 0, Array(NFA::State).new, Hash(Array(NFA::State), DState).new
      # prepare startstate
      startd = startdstate(start, startlist, dstate_cache, listid)
      states = [startd]
      i = -1
      while (i += 1) < states.size
        state = states[i]
        next_syms = IntersectionMethods.disjoin(state.l.map(&.c).reject(&.[0].< 0).uniq)
        next_syms.each do |symbol|
          t = Array(NFA::State).new
          step(state.l, symbol, t, listid += 1)
          s = state.l.compact_map do |s|
            intersect_segments(s.c, symbol)
          end
          list = t.sort_by(&.c)
          next_state = (dstate_cache[list]?)
          unless next_state
            next_state = dstate_cache[list] = DState.new(list)
            states << next_state
          end
          IntersectionMethods.disjoin(s).sort_by(&.[0]).each do |segment|
            state.next << {segment, next_state}
          end
        end
        state.next.sort_by! &.[0][0]
      end
      startd
    end

    private def self.startdstate(start : NFA::State, list : Array(NFA::State),
                                 dstate_cache : Hash(Array(NFA::State), DState), listid : Int32)
      slist = startlist(start, list, listid)
      dstate_cache[slist] = DState.new(slist)
    end

    private def self.startlist(start : NFA::State, l : Array(NFA::State), listid : Int32)
      add_state(l, start, listid)
      l
    end
  end
end
