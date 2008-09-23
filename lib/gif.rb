class GIF
  attr_reader :width, :height
  
  def initialize(file)
    @width, @height = IO.read(file)[6..10].unpack('SS')
  end
end

