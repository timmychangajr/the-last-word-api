# Manages game round lifecycle: starting new rounds, resetting state
class GameRoundManager
  MIN_PLAYERS_FOR_ROUND = 2

  def self.all_players_ready?(users)
    users.all? { |u| u["ready"] }
  end

  def self.start_new_round(room, users)
    new_quote = Quote.order("RANDOM()").first&.text || "Success is not final."
    total_count = new_quote.split.size

    reset_users = users.map do |u|
      u.merge({
        "score" => 0,
        "progress" => 0,
        "ready" => true,
        "completed_indices" => [],
        "wins" => u["wins"] || 0
      })
    end

    room.update!(
      winner: nil,
      buffer_array: [],
      target_quote: new_quote,
      total_indices: total_count,
      users: reset_users
    )

    ActionCable.server.broadcast("room_#{room.code}", {
      game_reset: true,
      buffer: [],
      target_quote: new_quote,
      total_indices: total_count,
      users: reset_users,
      score_feedback: {
        word: "NEW ROUND",
        message: "The race has begun!",
        id: Time.now.to_f
      }
    })
  end

  def self.should_start_new_round?(users)
    all_players_ready?(users) && users.length >= MIN_PLAYERS_FOR_ROUND
  end
end
