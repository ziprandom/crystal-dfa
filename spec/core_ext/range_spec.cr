require "../spec_helper"

describe Range do
  describe "#-" do
    it "substracts a disjoint Range from another one" do
      a, b = ('a'..'c'), ('e'..'f')
      (a - b).should eq [a]
      (b - a).should eq [b]
    end

    it "substracts an included & surrounding Range from another one" do
      a, b = ('a'..'z'), ('e'..'f')
      (a - b).should eq [('a'..'d'), ('g'..'z')]
      (b - a).should eq [] of Char
      (a - a).should eq [] of Char
    end

    it "substracts a disjoint Range from another one" do
      a, b = ('a'..'f'), ('c'..'i')
      (a - b).should eq [('a'..'b')]
      (b - a).should eq [('g'..'i')]
    end

    it "substracts a disjoint Range from another one" do
      a, b = (1..10), (5..20)
      (a - b).should eq [(1..4)]
      (b - a).should eq [11..20]
    end
  end

  describe "#disjoin" do
    it "disjoins two ranges" do
      a, b = 0..10, 5..15
      a.disjoin(b).sort_by(&.begin).should eq [0..4, 5..15]
    end

    it "disjoins two ranges if which one is included in the other" do
      a, b = 0..10, 5..7
      a.disjoin(b).sort_by(&.begin).should eq [0..4, 5..7, 8..10]
    end
  end

  describe ".disjoin" do
    a, b, c = 0..10, 5..15, 3..30

    it "disjoins an array of length one (aka. does nothing)" do
      IntersectionMethods.disjoin([a]).should eq [a]
    end

    it "disjoins a tiny array of ranges removing any overlaps" do
      IntersectionMethods.disjoin([a, b]).sort_by(&.begin).should eq [0..4, 5..15]
    end

    it "disjoins an array of ranges removing any overlaps" do
      # IntersectionMethods.disjoin([a,b,c]).sort_by(&.begin).should eq [0..2, 5..15, 16..30]
      IntersectionMethods.disjoin([a, b, c]).sort_by(&.begin).should eq [0..2, 3..30]
    end
  end
end
