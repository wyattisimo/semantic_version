class SemanticVersion
  include Comparable

  SINGLE_OPERATORS = {
    eq:  [0],
    lt:  [-1],
    lte: [-1, 0],
    gt:  [1],
    gte: [1, 0],
    equal_to:                 [0],
    less_than:                [-1],
    less_than_or_equal_to:    [-1, 0],
    greater_than:             [1],
    greater_than_or_equal_to: [1, 0]
  }.freeze

  RANGE_OPERATORS = {
    between: [],
    within:  [],
    any_of:  []
  }.freeze

  OPERATORS = SINGLE_OPERATORS.merge(RANGE_OPERATORS).freeze

  attr_reader :number_components, :prerelease_components

  # Instantiates a new SemanticVersion.
  #
  # @param [String] version: A semantic version (see http://semver.org).
  #
  def self.[](version)
    self.new(version)
  end

  # Instantiates a new SemanticVersion.
  #
  # @param [String] version: A semantic version (see http://semver.org).
  #
  def initialize(version)
    parse_components(version)
  end

  # Compares this SemanticVersion with one or more other version numbers.
  #
  # @param [Hash] assertions: A hash where keys are OPERATORS and values are operands in the form of semantic versions.
  #
  # @return True if all assertions are true, false otherwise.
  #
  def is(comparison)
    comparison.each_pair do |operator, other_version|
      unless OPERATORS.keys.include? operator
        raise ArgumentError.new("unrecognized operator `#{operator}'")
      end

      if RANGE_OPERATORS.keys.include? operator
        unless other_version.is_a?(Array) && other_version.length >= 2
          raise ArgumentError.new("range operand must be an array containing at least two elements")
        end

        result = if operator == :between
          is gt: other_version[0], lt: other_version[1]
        elsif operator == :within
          is gte: other_version[0], lte: other_version[1]
        elsif operator == :any_of
          other_version.map {|v| is eq: v }.any?
        else
          false
        end

        return false unless result == true

      else
        return false unless OPERATORS[operator].include?(self <=> other_version)

      end
    end

    return true
  end

  # Compares this SemanticVersion with another version.
  #
  # @param [SemanticVersion or String] other_version
  #
  # @return 0 if equal, 1 if greater than, -1 if less than.
  #
  def <=>(other_version)
    other_version = self.class.new(other_version)

    result = 0

    # Compare version number components.

    (0..[@number_components.count, other_version.number_components.count].max-1).each do |i|
      a = @number_components[i]
      b = other_version.number_components[i]

      result = if !a.nil? && b.nil?
        a == 0 ? 0 : 1
      elsif a.nil? && !b.nil?
        b == 0 ? 0 : -1
      else
        a <=> b
      end

      break unless result == 0
    end

    if result == 0
      if @prerelease_components.empty? && !other_version.prerelease_components.empty?
        result = 1
      elsif !@prerelease_components.empty? && other_version.prerelease_components.empty?
        result = -1
      end
    end

    # Compare pre-release components.

    if result == 0
      (0..[@prerelease_components.count, other_version.prerelease_components.count].max-1).each do |i|
        break unless result == 0

        a = @prerelease_components[i]
        b = other_version.prerelease_components[i]

        result = if !a.nil? && b.nil?
          1
        elsif a.nil? && !b.nil?
          -1
        elsif a.class == b.class
          a <=> b
        else
          a.to_s <=> b.to_s
        end
      end
    end

    return result
  end

  def ==(other_version)
    is eq: other_version
  end

  def >(other_version)
    is gt: other_version
  end

  def >=(other_version)
    is gte: other_version
  end

  def <(other_version)
    is lt: other_version
  end

  def <=(other_version)
    is lte: other_version
  end

  # Parses the given value into version components.
  #
  # @param [String] version: A string representation of a semantic version (see http://semver.org).
  #
  # @return An array [number_components, prerelease_components, build_metadata], where `number_components` is an array
  #         of the number components [MAJOR, MINOR, PATCH], `prerelease_components` is an array of the prerelease
  #         components, and `build_metadata` is, like, you know, the build metadata.
  #
  private def parse_components(version_string)
    @number_components, extensions = version_string.to_s.split('-', 2)
    @prerelease_components, @build_metadata = extensions.to_s.split('+', 2)

    @number_components = @number_components.to_s.split('.').map(&:to_i)
    @prerelease_components = @prerelease_components.to_s.split('.').map {|c| c == c.to_i.to_s ? c.to_i : c }

    return [@number_components, @prerelease_components, @build_metadata]
  end

  # Returns the string representation of the "MAJOR.MINOR.PATCH" version part.
  #
  def number
    @number_components.empty? ? nil : @number_components.join('.')
  end

  # Returns the major version number.
  #
  def major
    @number_components[0]
  end

  # Returns the minor version number.
  #
  def minor
    @number_components[1]
  end

  # Returns the patch number.
  #
  def patch
    @number_components[2]
  end

  # Returns the string representation of the pre-release version part.
  #
  def prerelease
    @prerelease_components.empty? ? nil : @prerelease_components.join('.')
  end

  # Returns the build.
  #
  def build
    @build_metadata
  end

  # Returns the string representation of the version.
  #
  def to_s
    "#{number}#{prerelease.nil? ? "" : "-#{prerelease}"}#{build.nil? ? "" : "+#{build}"}"
  end

end
