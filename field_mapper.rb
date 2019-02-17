class FieldMapper
  attr_accessor :field_mappings, :csv_file

  def initialize(filename)
    @field_mappings = Hash.new
    @csv_file = filename || "field_mappings.csv"
  end

  def load_elements
    File.foreach(@csv_file) do |line|
      next if line.begin_with "#" or line.empty?
      key,value = line.chomp.split(",")
      @field_mappings[key] = value.to_sym
    end
  end
end
