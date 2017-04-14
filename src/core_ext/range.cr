struct Range(B, E)

  # Takes an Array of Ranges and returns an
  # Array of Ranges that cover the same elements
  # and are guaranteed not to overlap
  def self.disjoin(ranges : Array(self))
    return ranges if ranges.size < 2
    range = ranges.pop
    ranges.reduce([range]) do |disjunct, range|
      disjunct.map do |disjoint|
        range.disjoin(disjoint)
      end.flatten
    end.uniq
  end

  def disjoin(other : self)
    [self] + (other - self)
  end

  # returns an Array of one or two ranges
  # containing all of selfs elements that
  # are not in other
  def -(other : self)
    bs, es = self.begin, self.exclusive? ? self.end.pred : self.end
    bo, eo = other.begin, other.exclusive? ? other.end.pred : other.end
    # disjoint
    if bo > es || bs > eo
      [self]
    elsif self != other && bo >= bs && eo <= es
      # other included in self
      if eo == es
        [(bs..bo.pred)]
      elsif bo == bs
        [(bo.succ..es)]
      else
        [(bs..bo.pred), (eo.succ..es)]
      end
    elsif self == other || ( bs >= bo && es <= eo )
      # self included in other
      # or both the same
      [] of Range(B,E)
    elsif bo >= bs
      [(bs..bo.pred)]
    else #if bs >= bo
      [(eo.succ..es)]
    end
  end
end
