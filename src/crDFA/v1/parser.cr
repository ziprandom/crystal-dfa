require "./node"
require "string_scanner"

module CrDFA
  module V1
    class Parser
      def self.parse(tokens : String, or_alternatives_parsing = false)
        scanner = StringScanner.new(tokens)
        stack = [Node.new.tap &.name = "Start"]
        dangling = Array(Node).new

        while (current = scanner.peek(1))
          scanner.offset += 1
          case current.not_nil!
          when "*"
            if stack.last.group_start
              stack.last.connect(stack.last.group_start.not_nil!)
              dangling << stack[stack.index(stack.last.group_start.not_nil!).not_nil! - 1]
            else
              stack.last.connect(stack.last)
              dangling << stack[-2]
            end
          when "+"
            stack.last.connect(stack.last.group_start ? stack.last.group_start.not_nil! : stack.last)
            # /abs|cda|def/
          when "|"
            if or_alternatives_parsing
              scanner.offset -= 1
              break
            else
              branch_stack = parse(scanner.rest, true)
              branch_start = branch_stack.shift
              branch_end = branch_stack.pop
              branch_stack.last.disconnect(branch_end)
              stack.first.connect(branch_stack.first)
              dangling << branch_stack.last
              dangling << stack.last
              stack += branch_stack
              scanner.offset += branch_end.position
            end
          when "["
            advance, node = parse_character_class(scanner.rest)
            stack.last.connect node
            dangling.each { |d| node.connect(d) }
            stack << node
            scanner.offset += advance
          when "?"
            if stack.last.group_start
              dangling << stack[stack.index(stack.last.group_start.not_nil!).not_nil! - 1]
            else
              dangling << stack[-2]
            end
          when ")" # finding ) means we finish recursive parsing of a group
            if or_alternatives_parsing
              scanner.offset -= 1
              break
            end
            inner_end = PassThroughNode.new.tap { |n| n.position = scanner.offset + 1; n.name = "End" }
            stack.last.connect(inner_end)
            dangling.each { |d| d.connect(inner_end) }
            stack << inner_end
            return stack
          when "("
            group_stack = parse(scanner.rest)
            #          group_stack.first.next.map { |n| stack.last.connect(n) }
            #          group_stack.shift
            #          group_end = group_stack.pop
            #          group_stack.last.disconnect(group_end)
            #          dangling = dangling + group_end.next
            dangling.each &.connect(group_stack.first)
            stack.last.connect(group_stack.first)
            stack += group_stack
            stack.last.group_start = group_stack.first
            scanner.offset += stack.last.position - 1
          when .in?("a".."z"), .in?("A".."Z"), .in?("0".."9")
            match = current
            # search forward for alphanums that are followed by alhpanums or ()[]|
            # to widen the caracter match group: ->a->b->c-> ==> ->abc->
            while starts_with_alphanum_and_next_alphanum_or_separation(scanner.rest)
              match = match + scanner.rest[0]
              scanner.offset += 1
            end
            node = LiteralNode.new(match).tap do |n|
              stack.last.next << n if stack.size > 0
            end
            stack.last.connect(node) if stack.size > 0
            dangling.each(&.connect(node))
            dangling.clear
            stack << node
          else raise "unexpected token encountered: #{current}"
          end

          break if scanner.eos?
        end
        accept = PassThroughNode.new.tap(&.name = "End").tap(&.position = scanner.offset)
        dangling.each(&.connect(accept)) # && dangling.clear
        stack.last.connect(accept)
        stack = optimize stack
        stack << accept
        stack
      end

      private def self.optimize(stack)
        stack.each do |node|
          if node.is_a? PassThroughNode &&
             node.next.find { |n| !n.is_a? PassThroughNode } &&
             node.prev.find { |n| !n.is_a? PassThroughNode }
          end
        end
        stack
      end

      private def self.parse_character_class(tokens)
        i = 0
        negate = tokens[0] == '^' ? true : false
        ranges = [] of Range(String, String)
        chars = [] of String
        while (current = tokens[i].to_s) != "]"
          if current.alphanum?
            if tokens[i + 1] == '-'
              raise "caracter class substraction is not supported" unless tokens[i + 2].alphanum?
              ranges << (current..tokens[i + 2].to_s)
              i += 3
            else
              chars << current
              i += 1
            end
          else
            i += 1
          end
        end
        {i + 1, CharacterClassNode.new(negate, chars, ranges).tap { |n| n.name = "[" + tokens[0..i] }}
      end

      private def self.starts_with_alphanum_and_next_alphanum_or_separation(text : String)
        return false if text.blank?
        c = text[0]
        if c.alphanum? && (
             text.size == 1 ||
             text[1].alphanum? ||
             text[1].to_s.in? "()[]|"
           )
          true
        else
          false
        end
      end

      # extract all the edges in the graph
      private def self.edges(nodes : Array(Node))
        incomming = Hash(Node, Array(Node)).new(Array(Node).new)
        outgoing = Hash(Node, Array(Node)).new(Array(Node).new)
        nodes.each do |node|
          node.next.each do |node2|
            outgoing[node] += [node2]
            incomming[node2] += [node]
          end
        end
        {outgoing, incomming}
      end
    end
  end
end
