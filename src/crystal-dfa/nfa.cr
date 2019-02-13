# coding: utf-8
require "./traverse"

# Constructing an NFA for our RegEx implementation
# based on
# https://swtch.com/~rsc/regexp/regexp1.html &
# http://stackoverflow.com/a/25832898
#
module DFA
  module NFA
    include Traverse

    module ClassMethods
      # Match State -> fin
      private def matchstate
        State.new(MATCH)
      end

      private def add_state(list : Array(State), state : State, listid : Int32)
        return unless state && state.lastlist != listid
        state.lastlist = listid
        if state.c == SPLIT
          add_state(list, state.out.as(State), listid)
          add_state(list, state.out1.as(State), listid)
        else
          list << state
        end
      end

      private def step(clist, c, nlist, listid)
        nlist.clear
        i = 0
        while i < clist.size
          s = clist[i]
          if intersect_segments(s.c, c)
            add_state(nlist, s.out.as(NFA::State), listid)
          end
          i += 1
        end
        {clist, nlist}
      end

      private def intersect_segments(s1, s2)
        min = s1[0] < s2[0] ? s1 : s2
        max = (min == s1) ? s2 : s1

        if min[1] < max[0]
          return nil
        else
          {max[0],
           min[1] < max[1] ? min[1] : max[1]}
        end
      end
    end

    extend ClassMethods

    MATCH = {-1, -1}
    SPLIT = {-2, -2}

    def self.match(start : State, string : String)
      i, listid, clist, nlist, size, c = -1, 0, [] of State, [] of State, string.size, ' '
      add_state(clist, start.clone, listid)
      while (i += 1) < size
        c = string[i]
        step(clist, {c.ord, c.ord}, nlist, listid += 1)
        t = clist; clist = nlist; nlist = t
      end
      clist.any? &.c.== MATCH
    end

    def self.create_nfa(ast : AST::ASTNode)
      nfa = Array(Fragment).new
      symbols = Array(Tuple(Int32, Int32)).new
      # iterate the ast tree starting
      # from the leafs going up to the
      # wrapping nodes
      visit(ast) do |node|
        case node
        when AST::QuantifierNode
        when AST::PlusNode
          e1 = nfa.pop
          state = State.new(SPLIT, e1.start)
          patch(e1.out, state)
          nfa.push Fragment.new e1.start, [state.outp1]
        when AST::StarNode
          e1 = nfa.pop
          state = State.new(SPLIT)
          state.out = e1.start
          patch(e1.out, state)
          nfa.push Fragment.new state, [state.outp1]
        when AST::QSTMNode
          e = nfa.pop
          state = State.allocate.tap { |s| s.c = SPLIT; s.out = e.start }
          nfa.push Fragment.new(state, e.out + [state.outp1])
        when AST::AlternationNode
          (node.alternatives.size - 1).times do
            e2 = nfa.pop
            e1 = nfa.pop
            state = State.new(SPLIT, e1.start, e2.start)
            nfa.push Fragment.new state, e1.out + e2.out
          end
        when AST::ConcatNode
          (node.nodes.size - 1).times do
            e2 = nfa.pop
            e1 = nfa.pop
            patch(e1.out, e2.start)
            nfa.push Fragment.new e1.start, e2.out
          end
        when AST::LiteralNode
          ord = node.to_s[0].ord
          sym = {ord, ord}
          symbols.push sym
          state = State.new(sym)
          nfa.push Fragment.new state, [state.outp]
          # A CharacterClass Node is a Literalnode as we
          # store literal values as {begin, end} anyway
        when AST::CharacterClassNode
          r = node.ranges.first
          sym = {r.begin.ord, r.end.ord}
          symbols.push sym
          state = State.new(sym)
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
        @lastlist : Int32? = nil
      ); end

      def outp
        pointerof(@out)
      end

      def outp1
        pointerof(@out1)
      end

      def <=>(other)
        object_id <=> other.object_id
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
