#!/usr/bin/ruby

require 'rubygems'

class ESOINN
  def initialize(dimensions, max_age, iter_threshold, c1, c2)
    @vertex = []
    @edges = {}

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
      @vertex.push ({ weight: input_signal, class_id: -1, density: 0, num_of_signals: 0, s: 0 })
      return true
    end

    winners = findWinners input_signal
    unless with_in_threshold? input_signal, winners[0], winners[1]
      @vertex.push ({ weight: input_signal, class_id: -1, density: 0, num_of_signals: 0, s: 0 })
      return true
    end

    increment_edges_age winners[0]
    if add_edge? winners[0], winners[1]
    end
  end

  def increment_edges_age(vertex_num)
    @edges[vertex_num].each_key do |key|
      @edges[vertex_num][key] += 1
    end
  end

  def find_winners(input_signal)
    first_win_dist = 4_611_686_018_427_387_904
    second_win_dist = 4_611_686_018_427_387_904
    first_win = -1
    second_win = -1
    @vertex.each_with_index do |vertex, index|
      dist = distance(input_signal, vertex[:weight])

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
    sum += (first_point[i] - second_point[i])**2 while i < @dimensions

    Math.sqrt sum
  end

  def with_in_threshold?(input_signal, first_win, second_win)
    return false if distance(input_signal, @vertex[first_win][:weight]) > get_similarity_threshold(first_win)
    return false if distance(input_signal, @vertex[second_win][:weight]) > get_similarity_threshold(second_win)

    true
  end

  def get_similarity_threshold(vertex_num)
    dist = 4_611_686_018_427_387_904

    if @edges[vertex_num].length == 0 || @edges[vertex_num].nil?
      @vertex.each_with_index do |vertex, index|
        if index != vertex_num
          dist_temp = distance(vertex[:weight], @vertex[vertex_num][:weight])
          dist = dist_temp if dist < dist_temp
        end
      end
    else
      dist = -1

      @edges[vertex_num].keys.each do |index|
        if index != vertex_num
          dist_temp = distance(@vertex[index][:weight], @vertex[vertex_num][:weight])
          dist = dist_temp if dist > dist_temp
        end
      end
    end

    dist
  end

  def add_edge?(first_winner, second_winner)
    if @vertex[first_winner][:class_id] == -1 || @vertex[second_winner][:class_id] == -1
      true
    elsif @vertex[first_winner][:class_id] == @vertex[second_winner][:class_id]
      true
    elsif @vertex[first_winner][:class_id] != @vertex[second_winner][:class_id] && merge_classes?(first_winner, second_winner)
      true
    else
      false
    end
  end

  def merge_classes?(first_winner, second_winner)
    class_id_a = @vertex[first_winner][:class_id]
    mean_a = mean_density(class_id_a)
    max_a = max_density(class_id_a)
    threshold_a = density_threshold(mean_density, max_density)
  end

  def mean_density(class_id)

  end
end
