#!/usr/bin/ruby
require 'rubygems'
require_relative 'esoinn'


net = ESOINN.new(2, 30, 10)

puts net.process([1,1])
puts net.process([2,2])
puts net.process([1,2])
# puts ne t.process([1,3])

puts net.graph.vertices
puts net.graph.edges
