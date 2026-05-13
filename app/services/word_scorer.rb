# Calculates points and feedback for word submissions
class WordScorer
  def self.calculate_score(word, user, target)
    progress = user["progress"]
    official = target[progress]

    # 1. Perfect Match
    if word == official
      if !user["completed_indices"].include?(progress)
        # Base score: 2x word length
        return [ (official.length * 2), true, "First time!" ]
      else
        # Reclaim score: 1 point
        return [ 1, true, "Reclaimed!" ]
      end
    end

    # 2. Casing Error
    if word.downcase == official.downcase
      return [ -3, false, "Capitalization!" ]
    end

    # 3. Sequencing Errors
    if target.map(&:downcase).include?(word.downcase)
      [ -5, false, "Wrong sequence" ]
    else
      [ -10, false, "Not in quote" ]
    end
  end
end
