class String
  def in?(collection)
    collection.includes? self
  end

  def alphanum?
    letters = self.split("")
    letters.each do |letter|
      unless letter.in?("a".."z") || letter.in?("A".."Z") || letter.in?("0".."9")
        return false
      end
      return true
    end
  end
end
