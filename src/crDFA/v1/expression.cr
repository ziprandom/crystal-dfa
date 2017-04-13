require "./parser"
require "./node"
require "string_scanner"

module CrDFA
  module V1
    class Expression
      class State
        getter :node, :pos

        def initialize(@node : Node, @pos : Int32); end
      end

      @graph : Array(Node)

      def initialize(@expression : String)
        @graph = Parser.parse(@expression)
      end

      def match(string, first = false)
        start_pos = 0
        while start_pos < string.size
          m = _match(string[start_pos..string.size - 1], first)
          if m.is_a?(Tuple)
            return {m[0] + start_pos, m[1]}
          end
          start_pos += 1
        end
        m
      end

      @cached : Hash(SState, Array(Node)) = Hash(SState, Array(Node)).new

      alias SState = Tuple(Node, Array(Char))

      def follow_set(node : Node, c : String)
        # ss = SState.new(node, c)
        # @cached[ss] ||= node.next.select{|x| x.enter?(c) }
        # @cached[ss]
        node.next.select { |x| x.enter?(c) }
      end

      def _match(string, first)
        accepted = Array(Tuple(Int32, String)).new
        current = [State.new(@graph[0], 0)]
        until current.empty?
          buffer = [] of State
          current.each do |state|
            # we found the last state
            if state.node.next.includes? @graph.last
              match = state.pos == 0 ? "" : state.pos == 1 ? string[0].to_s : string[0..state.pos - 1]
              accepted << {
                0, match,
              }
              break if first
            end
            break if state.pos > string.size

            buffer += follow_set(
              state.node,
              string[state.pos..-1]
            ).map { |n| State.new(n, state.pos + n.size) }
          end
          current = buffer
        end
        if accepted.any?
          accepted.reduce { |memo, res| if !memo || res[1].size > memo[1].size
            res
          else
            memo
          end }
        else
          false
        end
      end
    end
  end
end
