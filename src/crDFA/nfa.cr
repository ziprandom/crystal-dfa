# coding: utf-8
require "./traverse"

# Constructing an NFA for our RegEx implementation
# based on
# https://swtch.com/~rsc/regexp/regexp1.html &
# http://stackoverflow.com/a/25832898
#
module DFA
  module NFA
    include DFA::Traverse

    MATCH = {256, 256}
    SPLIT = {257, 257}

    # Match State -> fin
    def self.matchstate
      State.new(MATCH)
    end

    def self.match(start : State, string : String)
      i, listid, clist, nlist = -1, 0, [] of State, [] of State
      add_state(clist, start.clone, listid)
      while (i += 1) < string.size
        c = string[i]
        step(clist, c.as(Char), nlist, listid += 1)
        t = clist; clist = nlist; nlist = t
      end
      !!clist.find { |s| s.c == MATCH }
    end

    def self.step(clist, c, nlist, listid)
      nlist.clear
      i = 0
      while i < clist.size
        s = clist[i]
        o = c.ord
        if s.c[0] <= o && o <= s.c[1]
          add_state(nlist, s.out.as(State), listid)
        end
        i += 1
      end
      {clist, nlist}
    end

    def self.add_state(list : Array(State), state : State, listid : Int32)
      return unless state && state.lastlist != listid
      state.lastlist = listid
      if state.c == SPLIT
        add_state(list, state.out.as(State), listid)
        add_state(list, state.out1.as(State), listid)
      else
        list << state
      end
    end

    def self.create_nfa(ast : DFA::ASTNode)
      nfa = Array(Fragment).new

      # iterate the ast tree starting
      # from the leafs going up to the
      # wrapping nodes
      visit(ast) do |node|
        case node
        when QuantifierNode
        when PlusNode
          e1 = nfa.pop
          state = State.new(SPLIT, e1.start)
          patch(e1.out, state)
          nfa.push Fragment.new e1.start, [state.outp1]
        when StarNode
          e1 = nfa.pop
          state = State.new(SPLIT)
          state.out = e1.start
          patch(e1.out, state)
          nfa.push Fragment.new state, [state.outp1]
        when QSTMNode
          e = nfa.pop
          state = State.allocate.tap { |s| s.c = SPLIT; s.out = e.start }
          nfa.push Fragment.new(state, e.out + [state.outp1])
        when AlternationNode
          (node.alternatives.size - 1).times do
            e2 = nfa.pop
            e1 = nfa.pop
            state = State.new(SPLIT, e1.start, e2.start)
            nfa.push Fragment.new state, e1.out + e2.out
          end
        when ConcatNode
          (node.nodes.size - 1).times do
            e2 = nfa.pop
            e1 = nfa.pop
            patch(e1.out, e2.start)
            nfa.push Fragment.new e1.start, e2.out
          end
        when LiteralNode
          ord = node.to_s[0].ord
          state = State.new({ord, ord})
          nfa.push Fragment.new state, [state.outp]
          # A CharacterClass Node is a Literalnode as we
          # store literal values as {begin, end} anyway
        when CharacterClassNode
          r = node.ranges.first
          state = State.new({r.begin[0].ord, r.end[0].ord})
          nfa.push Fragment.new state, [state.outp]
        end
        nil
      end

      e = nfa.pop
      patch(e.out, matchstate)
      e.start
    end

    class State
      property :c, :out, :out1, :lastlist

      def clone(references : Hash(UInt64, State) = Hash(UInt64, State).new)
        if references[self.object_id]?
          return references[self.object_id]
        else
          n = State.allocate
          n.c = c
          references[self.object_id] = n
          n.out = out ? out.as(State).clone(references) : nil
          n.out1 = out1 ? out1.as(State).clone(references) : nil
          n
        end
      end

      def initialize(
                     @c : {Int32, Int32}, # segments to represent a character
      # a => {97,97}, [a-z] => {97, 122}
                     @out : State? = nil, @out1 : State? = nil,
                     @lastlist : Int32? = nil); end

      def outp
        pointerof(@out)
      end

      def outp1
        pointerof(@out1)
      end
    end

    class Fragment
      property :start, :out

      def initialize(@start : State, @out : Array(Pointer(State?))); end
    end

    private def self.patch(list : Array(Pointer(State?)), state : State)
      list.each do |pointer|
        pointer.value = state
      end
    end
  end
end
