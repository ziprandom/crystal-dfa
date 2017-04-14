require "../src/crDFA"
require "benchmark"

rx1, rx2 = nil, nil
expression = "(x+x+)+y"
string = "xxxxxxxxxxxxxy"

puts
puts %{building "#{expression}" with Regex (PCRE)}
puts Benchmark.measure { rx1 = Regex.new(expression) }
rx1 = rx1.not_nil!
puts %{building "#{expression}" with RegExp (own impl}
puts Benchmark.measure { rx2 = DFA::RegExp.new(expression) }
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
