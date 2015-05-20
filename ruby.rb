require 'socket'
require 'set'

words = File.foreach('/usr/share/dict/words')

WORDS_ALREADY_PLAYED = Set.new

def can_play_word(board, word)
  return false if WORDS_ALREADY_PLAYED.include?(word)
  result = []
  result_word = ""
  board = board.gsub(/ /, "").chars
  can_play = word.length > 3 && word.chars.all? do |c|
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
    when "ping" then
      s.puts "pong\n"
    when "; name ?\n" then
      s.puts "artistsAndRepertoire"
    when /(?:opponent: move:[0-9,]* \(([a-z]+)\))? ; move ((?:[a-z]{5} ){5})((?:[0-2]{5} ){5})\?\n/
      p "opponent's move: #{$1}"
      p "[vs #{opponent}] board: #{$2} state: #{$3}"
      WORDS_ALREADY_PLAYED << $1 unless $1.nil? or $1.empty?
      words.each do |word|
        word = word.chomp.downcase
        if (move = can_play_word($2, word))
          p "sending back: #{move}"
          s.puts move
          break
        end
      end
  end

end

