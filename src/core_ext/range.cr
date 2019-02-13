module IntersectionMethods(T)
  # Takes an Array of Ranges and returns an
  # Array of Ranges that cover the same elements
  # and are guaranteed not to overlap
  def self.disjoin(elements : Array(self))
    return elements if elements.size < 2
    element = elements.pop
    elements.reduce([element]) do |disjunct, element|
      disjunct + disjunct.reduce([element]) do |memo, dj|
        memo.map { |e| e - dj }.flatten
      end
    end.uniq
  end

  macro included

    def disjoin(other : self)
      [other] + (self - other)
      #[self] + (other - self)
    end
  end

  def minus_impl(other : self)
    bs, es = self
    bo, eo = other
    # disjoint
    if bo > es || bs > eo
      [self]
    elsif self != other && bo >= bs && eo <= es
      # other included in self
      if eo == es
        [{bs, bo - 1}]
      elsif bo == bs
        [{bo + 1, es}]
      else
        [{bs, bo - 1}, {eo + 1, es}]
      end
    elsif self == other || (bs >= bo && es <= eo)
      # self included in other
      # or both the same
      Array(T).new
    elsif bo >= bs
      [{bs, bo - 1}]
    else # if bs >= bo
      [{eo + 1, es}]
    end
  end
end

struct Tuple(T)
  include IntersectionMethods(T)

  def -(other : self)
    minus_impl(other)
  end
end

struct Range(B, E)
  include IntersectionMethods(Range(B, E))

  # returns an Array of one or two elements
  # containing all of selfs elements that
  # are not in other
  def -(other : self)
    bs, es = self.begin, self.exclusive? ? self.end.pred : self.end
    bo, eo = other.begin, other.exclusive? ? other.end.pred : other.end
    (({bs, es}) - ({bo, eo})).map { |r| (r[0]..r[1]) }
  end
end
