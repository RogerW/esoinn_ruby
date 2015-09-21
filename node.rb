class Node
  attr_accessor :weight, :class_id, :density, :num_of_signals, :s

  def initialize(weight, class_id, density, num_of_signals, s)
    @weight = weight
    @class_id = class_id
    @density = density
    @num_of_signals = num_of_signals
    @s = s
  end

  def to_s
    "Node: #{self.object_id} " \
    "Weight: #{@weight} Class ID: #{@class_id} " \
    "Dinsity: #{@density} Num Of Signals: #{num_of_signals} S: #{@s}"
  end

end