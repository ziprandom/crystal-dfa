# coding: utf-8
require "../spec_helper"

describe CrDFA::RegExp do
  it "matches a string against a simple regex" do
    rex = CrDFA::RegExp.new "x(a|b)+"
    rex.match("xaaabbbbaaab").should eq true
  end

  it "matches a string against a more complex regex" do
    rex = CrDFA::RegExp.new %{"[a-z]{2,4}"|x+}
    rex.match(%{"ha"}).should eq true
    rex.match(%{"haa"}).should eq true
    rex.match(%{"haaa"}).should eq true
    rex.match(%{"haaaA"}).should eq false
    rex.match(%{"haaaa"}).should eq false
    rex.match(%{xxxxxxxxxxxxxxx}).should eq true
  end
end
