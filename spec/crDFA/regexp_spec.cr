# coding: utf-8
require "../spec_helper"

describe DFA::RegExp do
  it "matches a string against a simple regex" do
    rex = DFA::RegExp.new "x(a|b)+"
    rex.match("xaaabbbbaaab").should eq true
  end

  it "matches a string against a more complex regex" do
    rex = DFA::RegExp.new %{"[a-z]{2,4}"|x+}
    rex.match(%{"ha"}).should eq true
    rex.match(%{"haa"}).should eq true
    rex.match(%{"haaa"}).should eq true
    rex.match(%{"haaaA"}).should eq false
    rex.match(%{"haaaa"}).should eq false
    rex.match(%{xxxxxxxxxxxxxxx}).should eq true
  end

  it "matches a string against a character class" do
    rex = DFA::RegExp.new %{"[a-zö]+"}
    rex.match(%{"haaa"}).should eq true
    rex.match(%{"haaa"}).should eq true
    rex.match(%{"ö"}).should eq true
    rex.match(%{"haaaA"}).should eq false
    rex.match(%{"123"}).should eq false
    rex.match(%{"AM"}).should eq false
  end

  it "matches a string against a character more complex class" do
    rex = DFA::RegExp.new %{"[a-zA-Dö]+"}
    rex.match(%{"haaaABCö"}).should eq true
    rex.match(%{"haaaAGCö"}).should eq false
  end

  it "matches a string against a negative character class" do
    rex = DFA::RegExp.new %{"[^a-z]+"}
    rex.match(%{"123"}).should eq true
    rex.match(%{"AM"}).should eq true
    rex.match(%{"haaaß"}).should eq false
    rex.match(%{"haaaA"}).should eq false
  end

end
