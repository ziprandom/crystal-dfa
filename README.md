# crystal-dfa

A Regex syntax parser, and Thompson NFA to DFA transformer and matcher based on Russ Cox's article ["Regular Expression Matching Can Be Simple And Fast"](https://swtch.com/~rsc/regexp/regexp1.html) with parse tree simplifications from Guangming Xings paper [Minimized Thompson NFA - Chapter 3](http://people.wku.edu/guangming.xing/thompsonnfa.pdf).

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
  0.000000   0.000000   0.000000 (  0.000143)
building "(?-imsx:(?:x+x+)+y)" with RegExp (own impl
  0.000000   0.000000   0.000000 (  0.000249)

matching "xxxxxxxxxxxxxy" a first time with Regex (PCRE)
  0.000000   0.000000   0.000000 (  0.000065)
rx1.match(string) # => #<Regex::MatchData "xxxxxxxxxxxxxy">

matching "xxxxxxxxxxxxxy" a first time with RegExp (own impl
  0.000000   0.000000   0.000000 (  0.000036)
rx2.match(string) # => true

     Regex (PCRE) matching : xxxxxxxxxxxxxy   2.46M (406.14ns) (± 7.03%)  2.09× slower
RegExp (own impl) matching : xxxxxxxxxxxxxy   5.14M (194.52ns) (± 6.78%)       fastest
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
```

## Contributing

1. Fork it ( https://github.com/ziprandom/crystal-dfa/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [ziprandom](https://github.com/ziprandom)  - creator, maintainer
