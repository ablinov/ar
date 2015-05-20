require 'socket'
require 'set'

words = File.read('/usr/share/dict/words').split("\n").
  select  { |w| w =~ /^[a-z]{3,}$/ }

WORDS_ALREADY_PLAYED = Set.new

def can_play_word(board, word, has_to_contain_letter)
  return false if WORDS_ALREADY_PLAYED.include?(word)
  return false if !has_to_contain_letter.nil? and !word.include?(has_to_contain_letter)
  result = []
  result_word = ""
  board = board.gsub(/ /, "").chars
  can_play = word.length >= 3 && word.chars.all? do |c|
    i = board.index(c)
    if i != nil
      row = i / 5
      col = i % 5
      result << "#{row}#{col}"
      result_word << board[i]
      board[i] = "$"
    end
    i != nil
  end
  if can_play
    WORDS_ALREADY_PLAYED << result_word
    "move:#{result.join(",")} (#{result_word})"
  else
    false
  end
end

s = TCPSocket.new("52.16.6.95", 4123)
while request = s.gets
  p request

  case request
    when /new game vs '(\w+)';/
      opponent = $1
      WORDS_ALREADY_PLAYED.clear
      player_number = nil
    when "ping" then
      s.puts "pong\n"
    when "; name ?\n" then
      s.puts "artistsAndRepertoire2"
    when /(?:opponent: move:[0-9,]* \(([a-z]+)\))? ; move ((?:[a-z]{5} ){5})((?:[0-2]{5} ){5})\?\n/
      opponent_word = $1
      board = $2
      state = $3

      p "opponent's move: #{opponent_word}"
      if player_number.nil?
        if (opponent_word.nil? || opponent_word.empty?)
          player_number = 1
        elsif opponent_word.length >= 3
          player_number = 2
        end
      end

      p "[#{player_number} vs #{opponent}] board: #{board} state: #{state}"
      board_array = board.gsub(/ /, "").chars
      state_array = state.gsub(/ /, "").chars
      has_to_contain_letter = nil
      if state_array.count("0") == 1
        has_to_contain_letter = board_array[state_array.index("0")]
        puts "+=================== winning letter: #{has_to_contain_letter}"
      end
      WORDS_ALREADY_PLAYED << opponent_word unless opponent_word.nil? or opponent_word.empty?
      words.each do |word|
        word = word.chomp.downcase
        if (move = can_play_word(board, word, has_to_contain_letter))
          p "sending back: #{move}"
          s.puts move
          break
        end
      end
  end

end

