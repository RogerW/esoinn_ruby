#!/usr/bin/ruby

require 'rubygems'

class ESOINN

  def initialize(dimensions, max_age, iter_threshold, c1, c2 )
    @vertex = Array.new
    @edges = Hash.new

    @dimensions = dimensions
    @max_age = max_age
    @iter_threshold = iter_threshold
    @c1 = c1
    @c2 = c2

  end

  def process(input_signal)
    return false if input_signal.length != @dimensions

    add_signal(input_signal)
  end

  private

  def add_signal(input_signal)
    if @vertex.length < 2
      @vertex.push {weight: input_signal, class_id: -1, density: 0, num_of_signals: 0, s: 0}
      return true
    end

    findWinners
  end

  def find_winners(input_signal)
    first_win_dist = 4611686018427387904
    second_win_dist = 4611686018427387904
    first_win = -1
    second_win = -1
    @vertex.each_with_index do |vert, index|
      dist = distance(input_signal, vert[:weight])

      if dist < first_win_dist
        second_win = first_win
        second_win_dist = first_win_dist
        first_win = index
        first_win_dist = dist
      elsif dist < second_win_dist
        second_win = index
        second_win_dist = dist
      end
    end

    [first_win, second_win]
  end

  def distance(first_point, second_point)
    i = 0
    sum = 0
    while i < @dimensions
      sum += (first_point[i] - second_point[i]) ** 2
    end

    Math.sqrt sum
  end

  def is_with_in_threshold(input_signal, first_win, second_win)
    return false if distance(input_signal, @vertex[first_win][:weight]) > get_similarity_threshold(first_win)
    return false if distance(input_signal, @vertex[second_win][:weight]) > get_similarity_threshold(second_win)

    true
  end

  def get_similarity_threshold(vertex_num)
    dist = 4611686018427387904
    
  end
end
