require "../src/crystal-dfa"
require "benchmark"

rx1 = nil
rx2 = nil
expression = /(?:x+x+)+y/
string = "xxxxxxxxxxxxxy"
# expression = /"([^"\\]|\\.)*"/
# string = %{"hi, \\"this\\" is a test"}
# expression = /(a?){10}a{10}/
# string = "aaaaaaaaaa"
# expression = /(?:(?:http[s]?|ftp):\/)?\/?(?:[^:\/\s]+)(?:(?:\/\w+)*\/)(?:[\w\-\.]+[^#?\s]+)(?:.*)?(?:#[\w\-]+)?/
# string = "http://stackoverflow.com/questions/20767047/how-to-implement-regular-expression-nfa-with-character-ranges"
puts
puts %{building "#{expression}" with Regex (PCRE)}
puts Benchmark.measure { rx1 = Regex.new(expression.source) }
rx1ok = rx1.not_nil!

puts %{building "#{expression}" with RegExp (own impl}
puts Benchmark.measure { rx2 = DFA::RegExp.new(expression.source) } # rx1ok.cr }
rx2ok = rx2.not_nil!

puts
puts %{matching "#{string}" a first time with Regex (PCRE)}
puts Benchmark.measure { rx1ok.match string }
pp rx1ok.match string
puts
puts %{matching "#{string}" a first time with RegExp (own impl}
puts Benchmark.measure { rx2ok.match string }
pp rx2ok.match string
puts

Benchmark.measure { rx1ok.match string }
Benchmark.measure { rx2ok.match string }

Benchmark.ips do |x|
  x.report("Regex (PCRE) matching : #{string}") { rx2ok.match string }
  x.report("RegExp (own impl) matching : #{string}") { rx2ok.match string }
end
puts
