def match_state
  DFA::NFA::State.new DFA::NFA::MATCH
end

def split_state(a, b)
  DFA::NFA::State.new(DFA::NFA::SPLIT, a, b)
end

def l_state(c : Char)
  r_state(c, c)
end

def r_state(b : Char, e : Char)
  s = DFA::NFA::State.new({b.ord, e.ord}, match_state)
end

class DFA::NFA::State
  def ==(other)
    rec_eql(other)
  end

  # this is not a complete equals method. It goes down the possibly circular
  # dependent rabbit hole and exits only, if it sees the same state for a third
  # time. still it might return a false positive aka. true
  # used only for test purposes anyway
  #
  def rec_eql(other, parent_ids : Array(UInt64) = Array(UInt64).new)
    id = self.object_id
    return false unless other
    return false if c != other.c
    return false if (out == nil && other.out != nil) || other.out == nil && out != nil
    return false if (out1 == nil && other.out1 != nil) || other.out1 == nil && out1 != nil
    return true if parent_ids.select(&.== id).size > 2
    parent_ids << id
    return false unless out == nil || out.not_nil!.rec_eql(other.out, parent_ids)
    return false unless out1 == nil || out1.not_nil!.rec_eql(other.out1, parent_ids)
    true
  end
end
