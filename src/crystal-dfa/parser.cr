# coding: utf-8
require "./lexer"
require "./nodes"
require "../core_ext/*"

module DFA
  class Parser
    Precedence = {
      PIPE:     1,
      LITERAL:  2,
      MINUS:    3,
      PLUS:     5,
      QSTM:     6,
      ASTERISK: 7,
      LCURLY:   8,
      ESCAPE:   9,
    }

    PREFIX_PARSLETS = {
      :LITERAL => NameParslet.new,
      :LPAREN  => GroupParslet.new,
      :LBRACK  => CharacterClassParslet.new,
      :ESCAPE  => SpecialCharacterClassParslet.new,
      :DOT     => AnyCharacterParslet.new,
    }

    INFIX_PARSLETS = {
      :LITERAL  => ConcatParslet.new(Precedence[:LITERAL]),
      :ESCAPE   => ConcatParslet.new(Precedence[:LITERAL]),
      :DOT      => ConcatParslet.new(Precedence[:LITERAL]),
      :LPAREN   => ConcatParslet.new(Precedence[:LITERAL]),
      :LBRACK   => ConcatParslet.new(Precedence[:LITERAL]),
      :PLUS     => QuantifierParslet(AST::PlusNode).new(Precedence[:PLUS]),
      :QSTM     => QuantifierParslet(AST::QSTMNode).new(Precedence[:QSTM]),
      :ASTERISK => QuantifierParslet(AST::StarNode).new(Precedence[:ASTERISK]),
      :PIPE     => AlternationParslet.new(Precedence[:PIPE]),
      :MINUS    => CharacterRangeParslet.new(Precedence[:MINUS]),
      :LCURLY   => CurlyQuantifierParslet.new(Precedence[:LCURLY]),
    }

    ANY_CHAR_RANGES   = [0.unsafe_chr..Char::MAX_CODEPOINT.unsafe_chr]
    WHITESPACE_RANGES = [' '..' ']
    TAB_RANGES        = ['\t'..'\t']
    CR_RANGES         = ['\r'..'\r']
    WORD_RANGES       = ['a'..'z', 'A'..'Z']
    NOT_WORD_RANGES   = [0.unsafe_chr..'`', '{'..'@', '['..Char::MAX_CODEPOINT.unsafe_chr]
    DIGIT_RANGES      = ['0'..'9']
    NON_DIGIT_RANGES  = [10.unsafe_chr..Char::MAX_CODEPOINT.unsafe_chr]

    def initialize(string)
      @lexer = Lexer.new(string)
    end

    def self.parse(string, optimize = true)
      ast = self.new(string).parse
      if ast && optimize
        SmartParsing.optimize(ast).not_nil!
      else
        ast
      end
    end

    def parse : AST::ASTNode
      parseExpression.not_nil!
    rescue e
      raise ParseException.new(e.message || "error", @lexer.pos, @lexer.string)
    end

    def parseExpression(precedence : Int32 = 0) : AST::ASTNode?
      token = consume

      return unless token

      prefix = (PREFIX_PARSLETS[token[:type]]?) ||
               raise "couldn't parse #{token}"

      left = prefix.parse(self, token)

      while (precedence < getPrecedence)
        _token = peek
        break unless _token

        infix = (INFIX_PARSLETS[_token[:type]]?)
        break unless infix

        left = infix.parse(self, left, _token)
      end

      left
    end

    private def getPrecedence
      if (_peek = peek) && (_p = INFIX_PARSLETS[_peek[:type]]?)
        _p.precedence
      else
        0
      end
    end

    def consume
      @lexer.next_token
    end

    def peek
      @lexer.lookahead
    end

    def consume(_type : Symbol)
      _next = consume
      unless _next && _next[:type] == _type
        raise "expected `#{Lexer::IDENTIFIERS.key_for?(_type) || _type}` got `#{_next}`"
      end
      _next
    end

    class ParseException < Exception
      def initialize(@message : String, @pos : Int32, @source : String); end

      def to_s
        <<-error
         #{@message}

         /#{@source}/
         -#{(@pos - 1).times.map { '-' }.join}^
       error
      end
    end

    #
    # Parslet Definitions
    #

    abstract class PrefixParslet
      abstract def parse(parser : Parser2, token : Token) : AST::ASTNode
    end

    abstract class InfixParslet
      getter :precedence

      abstract def parse(parser : Parser2, left : AST::ASTNode, token : Token) : AST::ASTNode

      def initialize(@precedence = 0); end
    end

    class NameParslet < PrefixParslet
      def parse(parser, token)
        AST::LiteralNode.new(token[:value].not_nil!)
      end
    end

    class AnyCharacterParslet < PrefixParslet
      def parse(parser, token)
        AST::CharacterClassNode.new(false, Array(String).new, ANY_CHAR_RANGES)
      end
    end

    class SpecialCharacterClassParslet < PrefixParslet
      def parse(parser, token)
        _next = parser.consume
        raise "unexpected end of input" unless _next

        value = _next[:type] == :LITERAL ? _next[:value] : # translate specia characters back to
        # their string representation because
        # we won't interprete them inside a
        # characterclass
Lexer::IDENTIFIERS.key_for(_next[:type])

        case value
        when 's' then AST::LiteralNode.new(WHITESPACE_RANGES.first.begin)
        when 't' then AST::LiteralNode.new(TAB_RANGES.first.begin)
        when 'r' then AST::LiteralNode.new(CR_RANGES.first.begin)
        when 'n' then AST::LiteralNode.new('\n')
        when 'w' then AST::CharacterClassNode.new(false, Array(String).new, WORD_RANGES)
        when 'W' then AST::CharacterClassNode.new(true, Array(String).new, WORD_RANGES)
        when 'd' then AST::CharacterClassNode.new(false, Array(String).new, DIGIT_RANGES)
        when 'D' then AST::CharacterClassNode.new(true, Array(String).new, DIGIT_RANGES)
        else          AST::LiteralNode.new(value.not_nil!)
        end
      end
    end

    class GroupParslet < PrefixParslet
      def parse(parser, token)
        # ignore non capturing group designators
        if (_peek = parser.peek) &&
           _peek[:type] == :QSTM
          parser.consume(:QSTM)
          if (_peek = parser.peek) &&
             _peek[:value] == ':'
            parser.consume(:LITERAL)
          else
            raise "expected ':', found #{_peek}"
          end
        end
        exp = parser.parseExpression
        parser.consume(:RPAREN)
        AST::GroupNode.new exp.not_nil!
      end
    end

    class CharacterRangeParslet < InfixParslet
      def parse(parser, left, token)
        parser.consume(:MINUS)
        right = parser.parseExpression(precedence)

        unless left.is_a?(AST::LiteralNode) && right.is_a?(AST::LiteralNode)
          raise "invalid character range #{left.inspect} #{right.inspect}"
        end

        unless (left.value.lowercase? && right.value.lowercase?) ||
               (left.value.uppercase? && right.value.uppercase?) ||
               (left.value.number? && right.value.number?)
          raise "#{left.value}-#{right.value} is not a valid character range"
        else
          AST::CharacterRangeNode.new(left.value, right.value)
        end
      end
    end

    class CharacterClassParslet < PrefixParslet
      def parse(parser, token)
        negate = (peek = parser.peek) &&
                 (peek[:type] == :NEGATE) &&
                 parser.consume ? true : false
        characters = Array(String).new
        ranges = Array(Range(Char, Char)).new
        additional_ranges = Array(AST::CharacterClassNode).new
        while (peek = parser.peek) && peek[:type] != :RBRACK
          case exp = parser.parseExpression
          when AST::LiteralNode
            characters << exp.value.to_s
          when AST::CharacterRangeNode
            ranges << Range.new(exp.from, exp.to)
          when AST::CharacterClassNode
            additional_ranges << exp
          when AST::ConcatNode
            exp.nodes.each do |node|
              case node
              when AST::LiteralNode
                characters << node.value.to_s
              when AST::CharacterRangeNode
                ranges << Range.new(node.from, node.to)
              when AST::CharacterClassNode
                additional_ranges << node
              else
                characters << exp.to_s
              end
            end
          else
            characters << exp.to_s
          end
        end
        parser.consume(:RBRACK)

        node =
          AST::CharacterClassNode.new(negate, characters, ranges, "")

        if additional_ranges.any?
          AST::AlternationNode.new(
            additional_ranges + [node.as(AST::ASTNode)]
          )
        else
          node
        end
      end
    end

    class ConcatParslet < InfixParslet
      def parse(parser, left : AST::ASTNode, token)
        exp = AST::ConcatNode.new([left.as(AST::ASTNode)])

        _next = parser.parseExpression(Precedence[:LITERAL] - 1).as(AST::ASTNode?)

        case _next
        when AST::ConcatNode
          exp.nodes += _next.nodes
        when AST::ASTNode
          exp.nodes << _next
        end
        exp
      end
    end

    class CurlyQuantifierParslet < InfixParslet
      def parse(parser, left : AST::ASTNode, token)
        parser.consume(:LCURLY)

        values = parse_quantifications(
          parser.parseExpression
        )

        parser.consume(:RCURLY)

        AST::QuantifierNode.new(left, *values)
      end

      def parse_quantifications(value : AST::ASTNode?)
        raise "bad" unless value
        exact, min, max = nil, nil, nil
        if value.is_a? AST::LiteralNode
          exact = value.value.to_i
        elsif (nodes = value.as(AST::ConcatNode)
                .nodes.map &.as(AST::LiteralNode)) &&
              (str = nodes.map(&.value).join) &&
              (commaindex = str.index(","))
          min = str[0...commaindex].to_i
          max = begin
            s = str[commaindex + 1..-1]
            s.size > 0 ? s.to_i : nil
          end
        else
          exact = nodes.map(&.value).join.to_i
        end
        {exact, min, max}
      rescue
        raise "couldn't parse quantifiaction {#{str}}"
      end
    end

    class QuantifierParslet(T) < InfixParslet
      def parse(parser, left : AST::ASTNode, token)
        parser.consume
        T.new(left)
      end
    end

    class AlternationParslet < InfixParslet
      def parse(parser, left : AST::ASTNode, token)
        exp = AST::AlternationNode.new([left.as(AST::ASTNode)])
        while (peek = parser.peek) && (peek[:type] == :PIPE)
          parser.consume
          exp.alternatives << parser.parseExpression(precedence).not_nil!
        end
        exp
      end
    end
  end
end
