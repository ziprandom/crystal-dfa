require "../src/crystal-dfa"
require "benchmark"

rx1, rx2 = nil, nil
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
rx1 = rx1.not_nil!
puts %{building "#{expression}" with RegExp (own impl}
puts Benchmark.measure { rx2 = rx1.cr }
rx2 = rx2.not_nil!

puts
puts %{matching "#{string}" a first time with Regex (PCRE)}
puts Benchmark.measure { rx1.match string }
pp rx1.match string
puts
puts %{matching "#{string}" a first time with RegExp (own impl}
puts Benchmark.measure { rx2.match string }
pp rx2.match string
puts

Benchmark.measure { rx1.not_nil!.match string }
Benchmark.measure { rx2.not_nil!.match string }

Benchmark.ips do |x|
  x.report("Regex (PCRE) matching : #{string}") { rx1.not_nil!.match string }
  x.report("RegExp (own impl) matching : #{string}") { rx2.not_nil!.match string }
end
puts
