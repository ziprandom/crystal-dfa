# crystal-dfa [![Build Status](https://api.travis-ci.org/ziprandom/crystal-dfa.svg)](https://travis-ci.org/ziprandom/crystal-dfa)

A Regex syntax parser, and Thompson NFA to DFA transformer and matcher based on Russ Cox's article ["Regular Expression Matching Can Be Simple And Fast"](https://swtch.com/~rsc/regexp/regexp1.html) with parse tree simplifications from Guangming Xings paper [Minimized Thompson NFA - Chapter 3](http://people.wku.edu/guangming.xing/thompsonnfa.pdf).

It is used in [Scanner](https://ziprandom.github.io/cltk/CLTK/Scanner.html) the new lexer implementation of the [Crystal Language Toolkit](https://github.com/ziprandom/cltk) to improve the lexing performance.

Currently implemented Regex syntax:

* literals and concatenation `ab`
* quantifiers `*`, `+`, `?` and alternation `|`
* groupings `a(ab)` (no capturing)
* quantifiers `{2,4}`, `{2}`, `{4,}`
* character classes `[^a-bK-Lxyß]`
* special character classes `.`, `\s`, `\t`, `\r`, `\d`, `\w`, `\W`, `\D`

Performance beats PCRE

```
$ crystal run --release benchmark/compare.cr

building "(?-imsx:(?:x+x+)+y)" with Regex (PCRE)
  0.000000   0.000000   0.000000 (  0.000111)
building "(?-imsx:(?:x+x+)+y)" with RegExp (own impl
  0.000000   0.000000   0.000000 (  0.000205)

matching "xxxxxxxxxxxxxy" a first time with Regex (PCRE)
  0.000000   0.000000   0.000000 (  0.000035)
rx1.match(string) # => #<Regex::MatchData "xxxxxxxxxxxxxy">

matching "xxxxxxxxxxxxxy" a first time with RegExp (own impl
  0.000000   0.000000   0.000000 (  0.000027)
rx2.match(string) # => #<DFA::DFA::MatchData:0x55adf4afcd00
                        @match="xxxxxxxxxxxxxy">

     Regex (PCRE) matching : xxxxxxxxxxxxxy   2.25M (443.56ns) (± 8.61%)  3.92× slower
RegExp (own impl) matching : xxxxxxxxxxxxxy   8.83M (113.24ns) (±11.62%)       fastest
```

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crystal-dfa:
    github: ziprandom/crystal-dfa
```

## Usage

```crystal
require "crystal-dfa"

rex = DFA::RegExp.new "(crystal|ruby) (just )?looks like (crystal|ruby)!"

rex.match("crystal just looks like ruby!") # => #<DFA::DFA::MatchData:0x556758a89d00
                                           #     @match=
                                           #      "crystal just looks like ruby!">

rex.match("ruby looks like crystal!") # => #<DFA::DFA::MatchData:0x556758a89aa0
                                      #     @match=
                                      #      "ruby looks like crystal!">

rex.match("python just looks like crystal!") # => nil

rex = DFA::RegExp.new "crystal"

rex.match("crystal-lang !!", true, false) # => #<DFA::DFA::MatchData:0x556758a8e3a0
                                          #     @match=
                                          #      "crystal">
```

## Contributing

1. Fork it ( https://github.com/ziprandom/crystal-dfa/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [ziprandom](https://github.com/ziprandom)  - creator, maintainer
