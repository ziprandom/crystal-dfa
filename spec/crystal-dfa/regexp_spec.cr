# coding: utf-8
require "../spec_helper"

describe DFA::RegExp do
  it "matches a string against a very simple regex" do
    rex = DFA::RegExp.new "[^a-z]"
    rex.match("A").should be_truthy
  end

  it "matches a string against a very simple regex" do
    rex = DFA::RegExp.new "[a-x]+"
    rex.match("xasdasdwiueqhodiuhcoiuw").should be_truthy
  end

  it "matches a string against a very simple regex" do
    rex = DFA::RegExp.new "a{2,4}"
    rex.match("a").should be_falsey
    rex.match("aa").should be_truthy
    rex.match("aa").should be_truthy
    rex.match("aaa").should be_truthy
    rex.match("aaaa").should be_truthy
    rex.match("aaaaa").should be_falsey
  end

  it "matches a string against a simple regex" do
    rex = DFA::RegExp.new "ab"
    rex.match("ab").should be_truthy
  end

  it "matches a string against a simple regex" do
    rex = DFA::RegExp.new "x(a|b)+"
    rex.match("xaaabbbbaaab").should be_truthy
    rex.match("xaaabbbbaaabc").should be_falsey
  end

  it "matches a string against a more complex regex" do
    rex = /"[a-z]{2,4}"|x+/.cr
    rex.match(%{"ha"}).should be_truthy
    rex.match(%{"haa"}).should be_truthy
    rex.match(%{"haaa"}).should be_truthy
    rex.match(%{"haaaA"}).should be_falsey
    rex.match(%{"haaaa"}).should be_falsey
    rex.match(%{xxxxxxxxxxxxxxx}).should be_truthy
  end

  it "does stuff" do
    rex = /[a-z]|x+|a{4}/.cr
    rex.match(%{w}).should be_truthy
    rex.match(%{xxxxxxxxxxxxxxx}).should be_truthy
    rex.match(%{zz}).should be_falsey
    rex.match(%{aaa}).should be_falsey
    rex.match(%{aaaa}).should be_truthy
  end

  it "matches a string against a character class" do
    rex = /"[a-zö]+"/.cr
    rex.match(%{"haaa"}).should be_truthy
    rex.match(%{"haaa"}).should be_truthy
    rex.match(%{"ö"}).should be_truthy
    rex.match(%{"haaaA"}).should be_falsey
    rex.match(%{"123"}).should be_falsey
    rex.match(%{"AM"}).should be_falsey
  end

  it "matches a string against a character more complex class" do
    rex = /"[a-zA-Dö]+"/.cr
    rex.match(%{"haaaABCö"}).should be_truthy
    rex.match(%{"haaaAGCö"}).should be_falsey
  end

  it "matches a string against a negative character class with one range" do
    rex = /"[^a-z]+"/.cr
    rex.match(%{"123"}).should be_truthy
    rex.match(%{"AM"}).should be_truthy
    rex.match(%{"haaaß"}).should be_falsey
    rex.match(%{"haaaA"}).should be_falsey
  end

  it "matches a string against a negative character class containing more ranges" do
    rex = DFA::RegExp.new "[^0-9A-Za-z]"
    rex.match("1").should be_falsey
    rex.match("A").should be_falsey
    rex.match("a").should be_falsey
    rex.match("<").should be_truthy
  end

  it "matches a string against a negative character class containing more ranges" do
    rex = DFA::RegExp.new "[^aD<]"
    rex.match("1").should be_truthy
    rex.match("A").should be_truthy
    rex.match("a").should be_falsey
    rex.match("D").should be_falsey
    rex.match("<").should be_falsey
  end

  it "matches a string against a negative character class containing single literals" do
    rex = DFA::RegExp.new "[^a-zABC]"
    rex.match("a").should be_falsey
    rex.match("A").should be_falsey
    rex.match("B").should be_falsey
    rex.match("C").should be_falsey
    rex.match("D").should be_truthy
    rex.match("1").should be_truthy
    rex.match("ß").should be_truthy
  end

  it "matches a string against a negative character class containing single literals" do
    rex = /[^:\/\s]+/.cr
    rex.match(":").should be_falsey
    rex.match("/").should be_falsey
    rex.match(" ").should be_falsey
    rex.match("ssdfsdfhlkjhwedööü").should be_truthy
    rex.match("ssdfsdfhlkjhwed ööü").should be_falsey
  end

  it "matches a negative character class containing multiple ranges and single literals" do
    rex = DFA::RegExp.new "[^a-zA-Z35]"
    rex.match("g").should be_falsey
    rex.match("C").should be_falsey
    rex.match("3").should be_falsey
    rex.match("5").should be_falsey
    rex.match("4").should be_truthy
    rex.match("1").should be_truthy
  end

  it "matches special characters whitespace" do
    rex = /[\s]+/.cr
    rex.match("                ").should be_truthy
    rex.match("                \n").should be_falsey
  end

  it "matches \\n" do
    rex = /[\n]+/.cr
    rex.match("\n\n\n").should be_truthy
    rex.match("\n\n_\n").should be_falsey
  end

  it "matches \\w" do
    rex = /\w+/.cr
    rex.match("hey").should be_truthy
    rex.match("JoLo").should be_truthy
    rex.match("!JoLo").should be_falsey
    rex.match("JoL1").should be_falsey
  end

  it "matches \\W" do
    rex = /\W+/.cr
    rex.match("12ß-.;_:").should be_truthy
    rex.match("JoLo").should be_falsey
  end

  it "matches \\d" do
    rex = /[\dö]+/.cr
    rex.match("12000").should be_truthy
    rex.match("12000ö").should be_truthy
    rex.match("12000e").should be_falsey
    rex.match("12000;").should be_falsey
  end

  it "matches \\D" do
    rex = /\D+/.cr
    rex.match("lots'of chars that are no digits").should be_truthy
    rex.match("lots'of chars that are n0 digits").should be_falsey
  end

  it "can be created from a system regex" do
    /\s+hallo\s*/.cr.match("  hallo ").should be_truthy
  end

  it "works with a regexp I actually use" do
    rx = /"([^"\\]|\\.)*"/.cr
    string = %{"hi, \\"this\\" is a test"}
    rx.match(string).should be_truthy
  end

  it "works with another regexp I actually use" do
    rx = /((http[s]?|ftp):\/)\/?([^:\/\s]+)((\/\w+)*\/)([\w\-\.]+[^#?\s]+)(.*)?(#[\w\-]+)?/.cr
    string = "https://www.reddit.com/index.html"
    rx.match(string).should be_truthy
  end
end
