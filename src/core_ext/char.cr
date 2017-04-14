struct Char
  def in?(collection)
    collection.includes? self
  end

  def alphanum?
    self.in?('a'..'z') || self.in?('A'..'Z') || self.in?('0'..'9')
  end

end
