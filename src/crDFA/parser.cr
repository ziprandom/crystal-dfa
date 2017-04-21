# coding: utf-8
require "./nodes"
require "../core_ext/*"

module DFA
  class Parser
    @group_start_stack = Array(Int32).new
    @character_group_stack = Array(Int32).new
    @ast : Array(AST::ASTNode) = Array(AST::ASTNode).new

    def self.parse(string, optimize = true)
      ast = self.new.parse(string)
      if ast && optimize
        SmartParsing.optimize(ast).not_nil!
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
          @ast = @ast.shift(@group_start_stack.pop) << AST::GroupNode.new(@ast.size > 1 ? AST::ConcatNode.new(@ast) : @ast.first)
        when :ALPHANUM, :MINUS
          value = token[1]
          @ast << AST::LiteralNode.new(value[0])
        when :STAR then @ast << AST::StarNode.new(@ast.pop)
        when :PLUS then @ast << AST::PlusNode.new(@ast.pop)
        when :QSTM then @ast << AST::QSTMNode.new(@ast.pop)
        when :SPECIAL then @ast << self.class.make_special_node(token[1])
        when :LCURLY
          skip, exact, min, max = parse_quantification(index, tokens)
          @ast << AST::QuantifierNode.new(@ast.pop, exact, min, max)
        when :PIPE
          if oring
            set_current_scope_ast(consumeLastOrAlternative(current_scope_ast))
          else
            cast = current_scope_ast.size > 1 ? AST::ConcatNode.new(current_scope_ast) : current_scope_ast.first
            anode = AST::AlternationNode.new([cast])
            oring = true
            set_current_scope_ast([anode.as(AST::ASTNode)])
          end
        end
      end
      if oring
        set_current_scope_ast(consumeLastOrAlternative(current_scope_ast))
      end
      @ast.size > 1 ? AST::ConcatNode.new(@ast) : @ast.first
    end


     ANY_CHAR_RANGES    =  [0.unsafe_chr..Char::MAX_CODEPOINT.unsafe_chr]
     WHITESPACE_RANGES  =  [' '..' ']
     TAB_RANGES         =  ['\t'..'\t']
     CR_RANGES          =  ['\r'..'\r']
     WORD_RANGES        =  ['a'..'z', 'A'..'Z']
     NOT_WORD_RANGES    =  [0.unsafe_chr..'`', '{'..'@', '['..Char::MAX_CODEPOINT.unsafe_chr]
     DIGIT_RANGES       =  ['0'..'9']
     NON_DIGIT_RANGES   =  [10.unsafe_chr..Char::MAX_CODEPOINT.unsafe_chr]


    def self.make_special_node(string)
      ranges = case string
               when "s" then AST::LiteralNode.new(WHITESPACE_RANGES.first.begin)
               when "t" then AST::LiteralNode.new(TAB_RANGES.first.begin)
               when "r" then AST::LiteralNode.new(CR_RANGES.first.begin)
               when "w" then AST::CharacterClassNode.new(false, Array(String).new, WORD_RANGES)
               when "W" then AST::CharacterClassNode.new(true, Array(String).new, WORD_RANGES)
               when "d" then AST::CharacterClassNode.new(false, Array(String).new, DIGIT_RANGES)
               when "D" then AST::CharacterClassNode.new(true, Array(String).new, DIGIT_RANGES)
               else AST::CharacterClassNode.new(false, Array(String).new, ANY_CHAR_RANGES)
               end
    end

    def current_scope_ast
      return @ast unless @group_start_stack.size > 0
      @ast[@group_start_stack.last..-1]
    end

    def set_current_scope_ast(ast)
      if @group_start_stack.size > 0
        prev_ast = @ast.shift(@group_start_stack.last)
        @ast = prev_ast.as(Array(AST::ASTNode)) + ast.as(Array(AST::ASTNode))
      else
        @ast = ast
      end
    end

    private def consumeLastOrAlternative(ast)
      anode = ast.shift.as(AST::AlternationNode)
      anode.alternatives << (ast.size > 1 ? AST::ConcatNode.new(ast) : ast.first).as(AST::ASTNode)
      [anode.as(AST::ASTNode)]
    end

    private def parse_character_class(tokens, string)
      index = -1
      ranges = Array(Range(Char, Char)).new
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
            ranges << (tokens[index][1][0]..tokens[index + 2][1][0])
            index += 2
          else
            characters << tokens[index][1]
          end
        when :SPECIAL
          case tokens[index][1]
          when "s" then characters << WHITESPACE_RANGES.first.begin.to_s
          when "t" then characters << TAB_RANGES.first.begin.to_s
          when "r" then characters << CR_RANGES.first.begin.to_s
          when "w" then ranges += WORD_RANGES
          when "W" then ranges += NOT_WORD_RANGES
          when "d" then ranges += DIGIT_RANGES
          when "D" then ranges += NON_DIGIT_RANGES
          else ranges += ANY_CHAR_RANGES
          end
        when :RBRACK
          break
        end
      end
      node = AST::CharacterClassNode.new(negate, characters, ranges)
      node.source = "[" + string[tokens[0][2]..tokens[index][2]]
      {index, node}
    end

    private def parse_quantification(index, tokens)
      exact, min, max = "", "", ""
      comma, ix = nil, index + 1
      t, v = tokens[ix]
      while [:ALPHANUM, :COMMA].includes? t
        case t
        when :ALPHANUM
          if comma
            max += v
          else
            exact += v
          end
        when :COMMA
          comma = ix
          min = exact
        end
        t, v = tokens[(ix+=1)]
      end
      if comma == ix - 1
        min = exact
      end
      begin
        exact = comma ? nil : exact.to_i
        min = min.blank? ? nil : min.to_i
        max = max.blank? ? nil : max.to_i
      rescue e
        raise "failed parsing the quantification. "
      end
      return ({ix - index, exact.as(Int32?), min.as(Int32?), max.as(Int32?)})
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
                  when "." then {:SPECIAL, s, index}
                  when "\\"
                    index += 1
                    case s = string[index].to_s
                    when "s", "t", "r", "w", "W", "d", "D"
                      {:SPECIAL, s, index-1}
                    else
                      {:ALPHANUM, "#{s}", index - 1}
                    end
                  else
                    {:ALPHANUM, string[index].to_s, index}
                  end
      end
      tokens
    end
  end
end
