#!/usr/bin/ruby

require 'rubygems'
require 'rgl/adjacency'
require 'rgl/implicit.rb'
require 'rgl/connected_components'
require_relative 'node'

class ESOINN
  attr_accessor :dimensions, :max_age, :iter_threshold, :c1, :c2
  attr_reader :graph

  def initialize(dimensions = 2, max_age = 30, iter_threshold = 50, c1 = 0.001, c2 = 1.0)
    @graph = RGL::AdjacencyGraph[]

    @age_edges = {}

    @dimensions = dimensions
    @max_age = max_age
    @iter_threshold = iter_threshold
    @c1 = c1
    @c2 = c2

    @iteration_count = 1
  end

  def process(input_signal)
    return false if input_signal.length != @dimensions

    add_signal(input_signal)
  end

  def classify
    mark_classes
  end

  def find_class(input_signal)
    find_winners input_signal
  end

  private

  def add_signal(input_signal)
    if @graph.length < 2
      @graph.add_vertex(Node.new input_signal, -1, 0, 0, 0)
      return true
    end

    winners = find_winners input_signal
    unless with_in_threshold? input_signal, winners[0], winners[1]
      @graph.add_vertex(Node.new input_signal, -1, 0, 0, 0)
      return true
    end

    increment_edges_age winners[0]
    if add_edge? winners[0], winners[1]
      edge = RGL::Edge::UnDirectedEdge[winners[0], winners[1]]
      @graph.add_edge(edge.source, edge.target)
      @age_edges[edge] = 0
    else
      edge = RGL::Edge::UnDirectedEdge[winners[0], winners[1]]
      @graph.remove_edge(winners[0], winners[1])
      @age_edges.remove edge
    end

    update_density(winners[0])
    update_weights(winners[0], input_signal)
    delete_old_edges

    update_class_labels if @iteration_count % @iter_threshold == 0
    @iteration_count += 1

    true
  end

  def increment_edges_age(vertex)
    @graph.edges.each do |edge|
      @age_edges[edge] += 1 if edge.source == vertex || edge.target == vertex
    end
  end

  def find_winners(input_signal)
    first_win_dist = 4_611_686_018_427_387_904
    second_win_dist = 4_611_686_018_427_387_904
    first_win = {}
    second_win = {}
    @graph.each_vertex do |vertex|
      dist = distance(input_signal, vertex.weight)

      if dist < first_win_dist
        second_win = first_win
        second_win_dist = first_win_dist
        first_win = vertex
        first_win_dist = dist
      elsif dist < second_win_dist
        second_win = vertex
        second_win_dist = dist
      end
    end

    [first_win, second_win]
  end

  def distance(first_point, second_point)
    i = 0
    sum = 0
    while i < @dimensions
      sum += (first_point[i] - second_point[i])**2
      i += 1
    end

    Math.sqrt sum
  end

  def with_in_threshold?(input_signal, first_win, second_win)
    return false if distance(input_signal, first_win.weight) > get_similarity_threshold(first_win)
    return false if distance(input_signal, second_win.weight) > get_similarity_threshold(second_win)

    true
  end

  def update_weights(winner, input_signal)
    @graph.adjacent_vertices(winner) do |neighbor|
      neighbor.weight.map!.with_index { |x, i| x + 1.0 / 100 * neighbor.num_of_signals * (input_signal[i] - x) }
    end

    winner.weight.map!.with_index { |x, i| x + 1.0 / winner.num_of_signals * (input_signal[i] - x) }
  end

  def get_similarity_threshold(vertex)
    dist = 4_611_686_018_427_387_904

    if @graph.out_degree(vertex) == 0
      @graph.each_vertex do |v|
        if v != vertex
          dist_temp = distance(v.weight, vertex.weight)
          dist = dist_temp if dist < dist_temp
        end
      end
    else
      dist = -1

      @graph.each_adjacent vertex do |v|
        dist_temp = distance(v.weight, vertex.weight)
        dist = dist_temp if dist > dist_temp
      end
    end

    dist
  end

  def add_edge?(first_winner, second_winner)
    if first_winner.class_id == -1 || second_winner.class_id == -1
      true
    elsif first_winner.class_id == second_winner.class_id
      true
    elsif first_winner.class_id != second_winner.class_id && merge_classes?(first_winner, second_winner)
      true
    else
      false
    end
  end

  def merge_classes?(first_winner, second_winner)
    class_id_a = first_winner.class_id
    mean_a = mean_density(class_id_a)
    max_a = max_density(class_id_a)
    threshold_a = density_threshold(mean_a, max_a)

    class_id_b = second_winner.class_id
    mean_b = mean_density(class_id_b)
    max_b = max_density(class_id_b)
    threshold_b = density_threshold(mean_b, max_b)

    min_ab = [first_winner.density, second_winner.density].min
    return true if min_ab > threshold_a * max_a && min_ab > threshold_b * max_b

    false
  end

  def mean_density(class_id)
    return 0 if class_id == -1

    density = 0
    cnt = 0
    @graph.each_vertex do |vertex|
      if vertex.class_id == class_id
        density += vertex.density
        cnt += 1
      end
    end

    density / cnt
  end

  def max_density(class_id)
    density = -4_611_686_018_427_387_904

    @graph.each_vertex do |vertex|
      if vertex.class_id == class_id && vertex.density > density
        density = vertex.density
      end
    end

    density
  end

  def density_thershold(mean_density, max_density)
    if mean_density * 2 >= max_density
      return 0
    elsif mean_density * 3 >= max_density && max_density > mean_density * 2
      return 0.5
    else
      return 1
    end
  end

  def update_density(vertex)
    m_distance = mean_distance vertex

    vertex.num_of_signals += 1
    vertex.s += (1 / ((1 + m_distance)**2))
    vertex.density = (vertex.s / vertex.num_of_signals)
  end

  def delete_old_edges
    @age_edges.each do |edge, age|
      if age > @max_age
        @age_edges.delete edge
        @graph.remove_edge(edge.source, edge.target)
      end
    end
  end

  def mean_distance(vertex)
    m_distance = 0
    cnt = 0
    @graph.each_vertex do |v|
      if v != vertex
        m_distance += distance(vertex.weight, v.weight)
        cnt += 1
      end
    end

    m_distance / cnt
  end

  def update_class_labels
    mark_classes
    # partition_classes
    delete_noise_vertex
  end

  def delete_noise_vertex
    @graph.vertices.each do |vertex|
      mean = mean_density vertex.class_id
      edges = @graph.out_degree vertex

      if (edges == 2 && vertex.density < @c1 * mean) ||
         (edges == 1 && vertex.density < @c2 * mean) ||
         (edges == 0)
        @graph.edges_filtered_by { |u, v| (u == vertex) || (v == vertex) }.edges.each do |edge|
          @graph.remove_edge edge.source, edge.target
        end
        @graph.remove_vertex vertex

      end
    end
  end

  def partition_classes
    @graph.each_edge do |edge|
      if edge.source.class_id != edge.target.class_id

      end
    end
  end

  def mark_classes
    @graph.each_vertex do |v|
      v.class_id = -1
    end
    class_id = 0

    groups = []
    @graph.each_connected_component { |c| groups << c }
    groups.each do |group|
      group.each do |vertex|
        vertex.class_id = class_id
      end
      class_id += 1
    end
  end
end
