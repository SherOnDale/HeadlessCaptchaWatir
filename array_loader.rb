class FieldMapper
  attr_accessor :fields, :input_file

  def initialize(filename)
    @fields = Hash.new
    @input_file = filename
  end

  def load_elements
    File.foreach(@input_file) do |line|
      next if line.begin_with "#" or line.empty?
      element = line.chomp.split(",")
      @fields << element
    end
  end
end
