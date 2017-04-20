# crystal-dfa

A Regex syntax parser, and Thompson NFA to DFA transformer and matcher based on Russ Cox's article ["Regular Expression Matching Can Be Simple And Fast"](https://swtch.com/~rsc/regexp/regexp1.html) with parse tree simplifications from Guangming Xings paper [Minimized Thompson NFA - Chapter 3](http://people.wku.edu/guangming.xing/thompsonnfa.pdf).

Currently implemented Regex syntax:

* literals and concatenation `ab`
* quantifiers `*`, `+`, `?` and alternation `|`
* groupings `a(ab)` (no capturing)
* quantifiers `{2,4}`, `{2}`, `{4,}`
* character classes `[^a-bK-Lxyß]`
* special character classes `.`, `\s`, `\t`, `\r`, `\d`, `\w`, `\W`, `\D`

Performance still lacks behind PCRE slightly though :/

```
$ crystal run --release benchmark/compare.cr

building "(?-imsx:(x+x+)+y)" with Regex (PCRE)
  0.000000   0.000000   0.000000 (  0.000073)
building "(?-imsx:(x+x+)+y)" with RegExp (own impl
  0.000000   0.000000   0.000000 (  0.000139)

matching "xxxxxxxxxxxxxy" a first time with Regex (PCRE)
  0.000000   0.000000   0.000000 (  0.000033)
rx1.match(string) # => #<Regex::MatchData "xxxxxxxxxxxxxy" 1:"xxxxxxxxxxxxx">

matching "xxxxxxxxxxxxxy" a first time with RegExp (own impl
  0.000000   0.000000   0.000000 (  0.000021)
rx2.match(string) # => true

     Regex (PCRE) matching : xxxxxxxxxxxxxy   2.03M (492.16ns) (± 5.69%)       fastest
RegExp (own impl) matching : xxxxxxxxxxxxxy   1.49M (671.43ns) (± 2.51%)  1.36× slower
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
