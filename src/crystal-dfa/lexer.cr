module DFA
  alias Token = {type: Symbol, value: Char?}

  class Lexer
    IDENTIFIERS = {
      '('  => :LPAREN,
      ')'  => :RPAREN,
      '['  => :LBRACK,
      ']'  => :RBRACK,
      '{'  => :LCURLY,
      '}'  => :RCURLY,
      '+'  => :PLUS,
      '-'  => :MINUS,
      '*'  => :ASTERISK,
      '?'  => :QSTM,
      '|'  => :PIPE,
      '^'  => :NEGATE,
      '\\' => :ESCAPE,
      '.'  => :DOT,
    }

    @pos = 0

    getter :pos, :string

    def initialize(@string : String); end

    def lookahead
      return nil if @pos >= @string.size
      _next = (@string[@pos])
      token = if (type = IDENTIFIERS[_next]?)
                Token.new(type: type, value: nil)
              else
                Token.new(type: :LITERAL, value: _next)
              end
    end

    def next_token
      token = lookahead
      @pos += 1
      token
    end
  end
end
