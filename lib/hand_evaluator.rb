class PokerHand
  def hand
      @hand
  end

  def arr_sorted_ranks
      @arr_sorted_ranks
  end
  
  def has_sequence
      @has_sequence
  end
  
  def same_suit
      @same_suit
  end
  
  def hash_counter_ranks
      @hash_counter_ranks
  end
  
  def arr_most_repeated_rank #[key, value] = [rank, count]
      @arr_most_repeated_rank
  end
  
  def arr_next_most_repeated_rank #[key, value] = [rank, count]
      @arr_next_most_repeated_rank
  end

  def get_hand_ranks(hand) # Convert hands to a num/rank separate array
      card_ranks = Array.new # only rank array
      hand.each{ |card| # populate the array with only ranks
          num = case card[0]
              when "A" then 14
              when "K" then 13
              when "Q" then 12
              when "J" then 11
              when "T" then 10
              else card[0].to_i
          end
          card_ranks.push(num)
      }
      return card_ranks
  end

  def initialize(hand)
      @hand = hand
      @arr_sorted_ranks = get_hand_ranks(@hand);
      @arr_sorted_ranks.sort! #sort the ranks, increasing order
      @has_sequence = true; # all cards have seq?
      @same_suit = true; # all cards have same suit?
      @hash_counter_ranks = Hash.new(0) #how many cards have the same rank

      @arr_sorted_ranks.each_with_index { |cardRank, index|
          if @has_sequence && index>0 && @arr_sorted_ranks[index-1] != cardRank-1 then
              @has_sequence = false;
          end
          if @same_suit && index>0 && @hand[index-1][1] != @hand[index][1] then
              @same_suit = false;
          end
          @hash_counter_ranks[cardRank] += 1
      }
      #to be used when calculating the strength & un-ties
      @arr_most_repeated_rank = @hash_counter_ranks.max_by { |key,value| value } #[key, value] = [rank, count]
      @hash_counter_ranks[@arr_most_repeated_rank[0]] = 0;
      @arr_next_most_repeated_rank  = @hash_counter_ranks.max_by { |key,value| value } #[key, value] = [rank, count]
      @hash_counter_ranks[@arr_most_repeated_rank[0]] = @arr_most_repeated_rank[1];
  end
end

class HandEvaluator
  def get_hand_strength(poker_hand) #the strength is equivalent to the type of hand
      #match /classify / give strength to hand
      if poker_hand.has_sequence && poker_hand.same_suit then #striaght flush
          return 9
      elsif poker_hand.arr_most_repeated_rank[1] == 4 #four of a kind
          return 8
      elsif poker_hand.arr_most_repeated_rank[1] == 3 && poker_hand.arr_next_most_repeated_rank[1] == 2 # full house
          return 7
      elsif poker_hand.same_suit #flush
          return 6
      elsif poker_hand.has_sequence #straight
          return 5
      elsif poker_hand.arr_most_repeated_rank[1] == 3 && poker_hand.arr_next_most_repeated_rank[1] <= 1#three of a kind
          return 4
      elsif poker_hand.arr_most_repeated_rank[1] == 2 && poker_hand.arr_next_most_repeated_rank[1] == 2#two pair
          return 3
      elsif  poker_hand.arr_most_repeated_rank[1] == 2 #one pair
          return 2
      else  #high card
          return 1
      end
  end

  #return 1 if A is bigger, 2 if B and 0 if equal
  def getBiggest(numA, numB)
      if numA > numB
          return 1
      elsif numA < numB
          return 2
      else #same number
          return 0
      end
  end

  def returnMax(numA, numB)
      if numA > numB
          return numA
      else #numA < numB && same numbers
          return numB
      end
  end

  def returnMin(numA, numB)
      if numA > numB
          return numB
      else #numA < numB && same numbers
          return numA
      end
  end

  #return 1 if hand1 is the winner, 2 if hand2 wins and 0 if theres still a tie
  def handleTie(poker_hand1, poker_hand2, hand_type)
      winner = 0
      case hand_type #the logic used for a tie varies with the type of hand
          when 9 , 5 then #straight flush or flush
              winner = getBiggest(poker_hand1.arr_sorted_ranks.last, poker_hand2.arr_sorted_ranks.last)
          when 6 || 1 then #flush or high card
              i=4 #length of hand
              while (i >= 0)
                  winner = getBiggest(poker_hand1.arr_sorted_ranks[i], poker_hand2.arr_sorted_ranks[i])
                  if winner == 0
                      i -= 1
                  else
                      return winner
                  end
              end
          when 8||7 then #four of a kind or full house
              winner = getBiggest(poker_hand1.arr_most_repeated_rank[0], poker_hand2.arr_most_repeated_rank[0])
              if winner == 0 #compare with next rank or kicker
                  winner = getBiggest(poker_hand1.arr_most_repeated_rank[0], poker_hand1.arr_most_repeated_rank[0])
              end
          when 4,2 then #three of a kind or one pair
              winner = getBiggest(poker_hand1.arr_most_repeated_rank[0], poker_hand2.arr_most_repeated_rank[0])
              if winner == 0 #compare with unrelated cards
                  unrelated_ranks1 = poker_hand1.arr_sorted_ranks.select{ |cardRank|  poker_hand1.hash_counter_ranks[cardRank] == 1}
                  unrelated_ranks2 = poker_hand2.arr_sorted_ranks.select{ |cardRank|  poker_hand2.hash_counter_ranks[cardRank] == 1}
                  
                  i = unrelated_ranks1.length-1 #length of hand
                  while (i >= 0)
                      winner = getBiggest(unrelated_ranks1[i], unrelated_ranks2[i])
                      if winner == 0
                          i -= 1
                      else
                          return winner
                      end
                  end
              end
          else #3, two pair 
              #compare with higgest pair
              highest_repeated_rank1 = returnMax(poker_hand1.arr_most_repeated_rank[0], poker_hand1.arr_next_most_repeated_rank[0])
              highest_repeated_rank2 = returnMax(poker_hand2.arr_most_repeated_rank[0], poker_hand2.arr_next_most_repeated_rank[0])
              winner = getBiggest(highest_repeated_rank1, highest_repeated_rank2)
              if winner == 0 #compare with next pair
                  lowest_repeated_rank1 = returnMin(poker_hand1.arr_most_repeated_rank[0], poker_hand1.arr_next_most_repeated_rank[0])
                  lowest_repeated_rank2 = returnMin(poker_hand2.arr_most_repeated_rank[0], poker_hand2.arr_next_most_repeated_rank[0])
                  winner = getBiggest(lowest_repeated_rank1, lowest_repeated_rank2)
                  if winner == 0 #compare with kicker
                      winner = getBiggest(poker_hand1.hash_counter_ranks.key(1), poker_hand2.hash_counter_ranks.key(2))
                  end
              end
          end
      return winner
  end

  def return_stronger_hand(hand1, hand2)
      poker_hand1 = PokerHand.new(hand1)
      poker_hand2 = PokerHand.new(hand2)

      strength1 = get_hand_strength(poker_hand1)
      strength2 = get_hand_strength(poker_hand2)

      if strength1 > strength2 then
          return poker_hand1.hand;
      elsif strength1 < strength2
          return poker_hand2.hand;
      else # tie
          winner = handleTie(poker_hand1, poker_hand2, strength1)
          if winner == 1
              return poker_hand1.hand
          elsif winner == 2
              return poker_hand2.hand
          else
              return winner
          end
      end
  end
end

# MAIN - with example usage
hand_1 = %w(2S 2D AH 3S 5S)
hand_2 = %w(2H 2C KH 5H 9C)
print HandEvaluator.new.return_stronger_hand(hand_1, hand_2) # => ["2S", "2D", "AH", "3S", "5S"]
