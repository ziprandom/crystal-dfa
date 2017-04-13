# coding: utf-8
require "./nodes"
require "../core_ext/*"

module CrDFA
  class Parser
    @group_start_stack = Array(Int32).new
    @character_group_stack = Array(Int32).new
    @ast : Array(ASTNode) = Array(ASTNode).new

    def self.parse(string, optimize = true)
      ast = self.new.parse(string)
      if ast && optimize
        CrDFA::SmartParsing.optimize(ast).not_nil!
      else
        ast
      end
    end

    def parse(string)
      oring = false
      tokens = tokenize(string)
      skip = 0
      tokens.each_with_index do |token, index|
        if skip > 0
          skip -= 1; next
        end
        case token[0]
        when :LBRACK
          skip, node = parse_character_class(tokens[index + 1..-1], string)
          @ast << node
        when :LPAR
          # remember where the current group begins
          @group_start_stack << @ast.size
          # skip non capturing group markup
          if string[token[2] + 1..token[2] + 2] == "?:"
            skip = 2
          end
        when :RPAR
          if oring
            set_current_scope_ast(consumeLastOrAlternative(current_scope_ast))
            oring = false
          end
          @ast = @ast.shift(@group_start_stack.pop) << GroupNode.new(@ast.size > 1 ? ConcatNode.new(@ast) : @ast.first)
        when :ALPHANUM
          value = token[1]
          @ast << LiteralNode.new(value)
        when :STAR then @ast << StarNode.new(@ast.pop)
        when :PLUS then @ast << PlusNode.new(@ast.pop)
        when :QSTM then @ast << QSTMNode.new(@ast.pop)
        when :LCURLY
          skip, exact, min, max = parse_quantification(index, tokens)
          @ast << QuantifierNode.new(@ast.pop, exact, min, max)
        when :PIPE
          if oring
            set_current_scope_ast(consumeLastOrAlternative(current_scope_ast))
          else
            cast = current_scope_ast.size > 1 ? ConcatNode.new(current_scope_ast) : current_scope_ast.first
            anode = AlternationNode.new([cast])
            oring = true
            set_current_scope_ast([anode.as(ASTNode)])
          end
        end
      end
      if oring
        set_current_scope_ast(consumeLastOrAlternative(current_scope_ast))
      end
      @ast.size > 1 ? ConcatNode.new(@ast) : @ast.first
    end

    def current_scope_ast
      return @ast unless @group_start_stack.size > 0
      @ast[@group_start_stack.last..-1]
    end

    def set_current_scope_ast(ast)
      if @group_start_stack.size > 0
        prev_ast = @ast.shift(@group_start_stack.last)
        @ast = prev_ast.as(Array(ASTNode)) + ast.as(Array(ASTNode))
      else
        @ast = ast
      end
    end

    private def consumeLastOrAlternative(ast)
      anode = ast.shift.as(AlternationNode)
      anode.alternatives << (ast.size > 1 ? ConcatNode.new(ast) : ast.first).as(ASTNode)
      [anode.as(ASTNode)]
    end

    private def parse_character_class(tokens, string)
      index = -1
      ranges = Array(Range(String, String)).new
      negate = false
      characters = Array(String).new
      while (index += 1) && index < tokens.size
        case tokens[index][0]
        when :ROF
          if index == 0
            negate = true
          end
        when :ALPHANUM, :QSTM, :COMMA, :PLUS
          if tokens[index + 1][0] == :MINUS && tokens[index + 2][0] == :ALPHANUM
            ranges << (tokens[index][1]..tokens[index + 2][1])
            index += 2
          else
            characters << tokens[index][1]
          end
        when :RBRACK
          break
        end
      end
      node = CharacterClassNode.new(negate, characters, ranges)
      node.source = "[" + string[tokens[0][2]..tokens[index][2]]
      {index, node}
    end

    private def parse_quantification(index, tokens)
      exact, min, max = nil, nil, nil
      skip = 0
      if tokens[index + 1][0] == :ALPHANUM
        if tokens[index + 2][0] == :RCURLY
          # exact number
          # @ast << QuantifierNode.new(@ast.pop, tokens[index+1][1].to_i)
          exact = tokens[index + 1][1].to_i
          skip = 2
        elsif tokens[index + 2][0] == :COMMA
          if tokens[index + 3][0] == :ALPHANUM && tokens[index + 4][0] == :RCURLY
            # min, max quantifier
            # @ast << QuantifierNode.new(@ast.pop, nil, tokens[index+1][1].to_i, tokens[index+3][1].to_i)
            min, max = tokens[index + 1][1].to_i, tokens[index + 3][1].to_i
            skip = 4
          elsif tokens[index + 3][0] == :RCURLY
            # min quantifier
            # @ast << QuantifierNode.new(@ast.pop, nil, tokens[index+1][1].to_i)
            min = tokens[index + 1][1].to_i
            skip = 3
          end
        else
          raise "expected a number at position #{tokens[index + 1][2]}"
        end
      end
      return {skip, exact, min, max}
    end

    def tokenize(string)
      tokens = Array(Tuple(Symbol, String, Int32)).new
      index = -1
      while (index += 1) < string.size
        tokens << case s = string[index].to_s
        when "(" then {:LPAR, s, index}
        when ")" then {:RPAR, s, index}
        when "[" then {:LBRACK, s, index}
        when "]" then {:RBRACK, s, index}
        when "{" then {:LCURLY, s, index}
        when "}" then {:RCURLY, s, index}
        when "," then {:COMMA, s, index}
        when "|" then {:PIPE, s, index}
        when "*" then {:STAR, s, index}
        when "+" then {:PLUS, s, index}
        when "-" then {:MINUS, s, index}
        when "?" then {:QSTM, s, index}
        when "^" then {:ROF, s, index}
        when "\\"
          index += 1
          {:ALPHANUM, "\\#{string[index]}", index - 1}
        else
          {:ALPHANUM, string[index].to_s, index}
        end
      end
      tokens
    end
  end
end
