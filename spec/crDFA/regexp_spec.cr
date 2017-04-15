# coding: utf-8
require "../spec_helper"

describe DFA::RegExp do
  it "matches a string against a simple regex" do
    rex = DFA::RegExp.new "x(a|b)+"
    rex.match("xaaabbbbaaab").should eq true
  end

  it "matches a string against a more complex regex" do
    rex = /"[a-z]{2,4}"|x+/.cr
    rex.match(%{"ha"}).should eq true
    rex.match(%{"haa"}).should eq true
    rex.match(%{"haaa"}).should eq true
    rex.match(%{"haaaA"}).should eq false
    rex.match(%{"haaaa"}).should eq false
    rex.match(%{xxxxxxxxxxxxxxx}).should eq true
  end

  it "matches a string against a character class" do
    rex = /"[a-zö]+"/.cr
    rex.match(%{"haaa"}).should eq true
    rex.match(%{"haaa"}).should eq true
    rex.match(%{"ö"}).should eq true
    rex.match(%{"haaaA"}).should eq false
    rex.match(%{"123"}).should eq false
    rex.match(%{"AM"}).should eq false
  end

  it "matches a string against a character more complex class" do
    rex = /"[a-zA-Dö]+"/.cr
    rex.match(%{"haaaABCö"}).should eq true
    rex.match(%{"haaaAGCö"}).should eq false
  end

  it "matches a string against a negative character class with one range" do
    rex = /"[^a-z]+"/.cr
    rex.match(%{"123"}).should eq true
    rex.match(%{"AM"}).should eq true
    rex.match(%{"haaaß"}).should eq false
    rex.match(%{"haaaA"}).should eq false
  end

  it "matches a string against a negative character class containing more ranges" do
    rex = DFA::RegExp.new "[^0-9A-Za-z]"
    rex.match("1").should eq false
    rex.match("A").should eq false
    rex.match("a").should eq false
    rex.match("<").should eq true
  end

  it "matches a string against a negative character class containing more ranges" do
    rex = DFA::RegExp.new "[^aD<]"
    rex.match("1").should eq true
    rex.match("A").should eq true
    rex.match("a").should eq false
    rex.match("D").should eq false
    rex.match("<").should eq false
  end

  it "matches a string against a negative character class containing single literals" do
    rex = DFA::RegExp.new "[^a-zABC]"
    rex.match("a").should eq false
    rex.match("A").should eq false
    rex.match("B").should eq false
    rex.match("C").should eq false
    rex.match("D").should eq true
    rex.match("1").should eq true
    rex.match("ß").should eq true
  end

  it "matches a negative character class containing multiple ranges and single literals" do
    rex = DFA::RegExp.new "[^a-zA-Z35]"
    rex.match("g").should eq false
    rex.match("C").should eq false
    rex.match("3").should eq false
    rex.match("5").should eq false
    rex.match("4").should eq true
    rex.match("1").should eq true
  end


  it "matches special characters whitespace" do
    rex = /[\s]+/.cr
    rex.match("                ").should eq true
    rex.match("                \n").should eq false
  end

  it "matches \\w" do
    rex = /\w+/.cr
    rex.match("hey").should eq true
    rex.match("JoLo").should eq true
    rex.match("!JoLo").should eq false
    rex.match("JoL1").should eq false
  end

  it "matches \\W" do
    rex = /\W+/.cr
    rex.match("12ß-.;_:").should eq true
    rex.match("JoLo").should eq false
  end

  it "matches \\d" do
    rex = /[\dö]+/.cr
    rex.match("12000").should eq true
    rex.match("12000ö").should eq true
    rex.match("12000e").should eq false
    rex.match("12000;").should eq false
  end

  it "matches \\D" do
    rex = /\D+/.cr
    rex.match("lots'of chars that are no digits").should eq true
    rex.match("lots'of chars that are n0 digits").should eq false
  end

  it "can be created from a system regex" do
    /\s+hallo\s*/.cr.match("  hallo ").should eq true
  end

  it "works with a regexp I actually use" do
    rx = /"([^"\\]|\\.)*"/.cr
    string = %{"hi, \\"this\\" is a test"}

    rx.match(string).should eq true
  end
end
