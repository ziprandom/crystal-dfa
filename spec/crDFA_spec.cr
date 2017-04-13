require "./spec_helper"
describe CrDFA do
  # TODO: Write tests

  it "works" do
    false.should eq(false)
  end

  describe CrDFA::V1::Expression do
    it "matches against the simplest literal match regex" do
      expression = CrDFA::V1::Expression.new("a")
      expression.match("a").should eq({0, "a"})
    end

    it "doesn't match a wrong string against the simplest literal match regex" do
      CrDFA::V1::Expression.new("a").match("bb").should eq(false)
    end

    it "matches against multiple literals" do
      expression = CrDFA::V1::Expression.new("ababab")
      expression.match("ababab").should eq({0, "ababab"})
      expression.match("bababa").should eq(false)
    end

    it "matches later in the string if necessary" do
      CrDFA::V1::Expression.new("aabcde").match("aaabcde").should eq({1, "aabcde"})
    end

    it "matches the one-ore-more(+) operator" do
      expression = CrDFA::V1::Expression.new("a+")
      expression.match("caaaabb").should eq({1, "aaaa"})
      CrDFA::V1::Expression.new("a+b+").match("caaabb").should eq({1, "aaabb"})
      CrDFA::V1::Expression.new("a+b+").match("bbb").should eq(false)
    end

    it "matches the zero-or-more(*) operator" do
      CrDFA::V1::Expression.new("a*b*").match("aaa").should eq({0, "aaa"})
      CrDFA::V1::Expression.new("a*b*").match("bbb").should eq({0, "bbb"})
      CrDFA::V1::Expression.new("a*b*").match("aaabb").should eq({0, "aaabb"})
      CrDFA::V1::Expression.new("a*b*c").match("aaabb").should eq(false)
      CrDFA::V1::Expression.new("a*b*c").match("aaabbc").should eq({0, "aaabbc"})
    end

    it "matches the zero-or-one(?) operator" do
      expression = CrDFA::V1::Expression.new("ba?b")
      expression.match("bab").should eq({0, "bab"})
      expression.match("bb").should eq({0, "bb"})
      expression.match("baab").should eq(false)
    end

    it "matches groups '(..)'" do
      expression = CrDFA::V1::Expression.new("a(ab)+b(cd)?")
      expression.match("aabababb").should eq({0, "aabababb"})
      expression.match("aabababbcd").should eq({0, "aabababbcd"})
      expression.match("abcd").should eq(false)
    end

    it "even matches nested groups '(..)'" do
      expression = CrDFA::V1::Expression.new("a(ab(cd)+)?")
      expression.match("aabcdcd").should eq({0, "aabcdcd"})
    end

    it "even matches nested groups '(..)'" do
      expression = CrDFA::V1::Expression.new("a(ab(cd)+)?")
      expression.match("aabcdcd").should eq({0, "aabcdcd"})
      expression.match("aabcdab").should eq({0, "aabcd"})
      expression.match("bcb").should eq(false)
    end

    it "even matches charactergroups '[..]'" do
      expression = CrDFA::V1::Expression.new("[^a-z]+")
      puts expression.to_graph
      expression.match("1234").should eq({0, "1234"})
      expression.match("123a").should eq({0, "123"})
      expression.match("a").should eq(false)
    end

    it "even matches or '|'" do
      expression = CrDFA::V1::Expression.new("(ab|cd|ef|hallo)")
      puts expression.to_graph
      expression.match("ab").should eq({0, "ab"})
      expression.match("cd").should eq({0, "cd"})
      expression.match("ef").should eq({0, "ef"})
      expression.match("hallo").should eq({0, "hallo"})
    end

    it "does more complex stuff" do
      expression = CrDFA::V1::Expression.new("a*b+c*")
      expression.match("aaabbc").should eq({0, "aaabbc"})
      expression.match("bbc").should eq({0, "bbc"})
      expression.match("xxxxbb").should eq({4, "bb"})
    end

    it "does even more complex stuff" do
      expression = CrDFA::V1::Expression.new("xx(ab|cd|ef|hallo)*")
      puts CrDFA::V1::Expression.new("(ab|cd)*").to_graph
      expression.match("xxhallocdefabnonsense").should eq({0, "xxhallocdefab"})
      expression.match("xx").should eq({0, "xx"})
      expression.match("xxhallohallohallo").should eq({0, "xxhallohallohallo"})
    end

    pending "has performance" do
      expression_string = "(x+x+)+y"
      expression = CrDFA::V1::Expression.new(expression_string)
      regex = Regex.new(expression_string)
      expression.match("xxxxxxxxxxxxxy").should eq({0, "xxxxxxxxxxxxxy"})

      Benchmark.ips do |x|
        x.report("mine") { expression.match("xxxxxxxxxxxxxy", true) }
        x.report("rex") { regex.match("xxxxxxxxxxxxxy") }
      end
    end

    pending "has performance" do
      expression_string = "((a+b+)+a+b+)+"
      expression = CrDFA::V1::Expression.new(expression_string)
      regex = Regex.new(expression_string)
      expression.match("abab").should eq({0, "abab"})

      Benchmark.ips do |x|
        x.report("mine") { expression.match("ababab") }
        x.report("rex") { regex.match("ababab") }
      end
    end
  end
end
