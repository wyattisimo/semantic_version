class SemanticVersion

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


  attr_reader :number_components, :prerelease_components, :build_metadata


  # Instantiates a new SemanticVersion.
  #
  # @param [String] version: A semantic version (see http://semver.org).
  #
  def self.[](version)
    self.new(version)
  end


  # Parses the given value into version components.
  #
  # @param [String or SemanticVersion] version: A semantic version (see http://semver.org).
  #
  # @return An array [version_number, prerelease, build_metadata], where `version_number` is an array of the
  #         number components [MAJOR, MINOR, PATCH], `prerelease` is an array of the prerelease components,
  #         and `build_metadata` is, like, you know, the build metadata.
  #
  def self.parse_components(version)
    return version.components if version.is_a? SemanticVersion

    version_number, extensions = version.to_s.split('-', 2)
    prerelease, build_metadata = extensions.to_s.split('+', 2)

    version_number = version_number.to_s.split('.').map(&:to_i)
    prerelease = prerelease.to_s.split('.').map {|c| c == c.to_i.to_s ? c.to_i : c }

    return [version_number, prerelease, build_metadata]
  end


  # Instantiates a new SemanticVersion.
  #
  # @param [String] version: A semantic version (see http://semver.org).
  #
  def initialize(version)
    @number_components, @prerelease_components, @build_metadata = self.class.parse_components(version)
  end


  # Compares this SemanticVersion with one or more other version numbers.
  #
  # @param [Hash] assertions: A hash where keys are OPERATORS and values are operands in the form of semantic versions.
  #
  # @return True if all assertions are true, false otherwise.
  #
  def is(comparison)
    comparison.each_pair do |operator, version|
      unless OPERATORS.keys.include? operator
        raise ArgumentError.new("unrecognized operator `#{operator}'")
      end

      if RANGE_OPERATORS.keys.include? operator
        unless version.is_a?(Array) && version.length >= 2
          raise ArgumentError.new("range operand must be an array containing at least two elements")
        end

        result = if operator == :between
          is gt: version[0], lt: version[1]
        elsif operator == :within
          is gte: version[0], lte: version[1]
        elsif operator == :any_of
          version.map {|v| is eq: v }.any?
        else
          false
        end

        return false unless result == true

      else
        number_components, prerelease_components, _ = self.class.parse_components(version)

        result = 0

        # Compare version number components.

        (0..[@number_components.count, number_components.count].max-1).each do |i|
          a = @number_components[i]
          b = number_components[i]

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
          if @prerelease_components.empty? && !prerelease_components.empty?
            result = 1
          elsif !@prerelease_components.empty? && prerelease_components.empty?
            result = -1
          end
        end

        # Compare pre-release components.

        if result == 0
          (0..[@prerelease_components.count, prerelease_components.count].max-1).each do |i|
            break unless result == 0

            a = @prerelease_components[i]
            b = prerelease_components[i]

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

        return false unless OPERATORS[operator].include? result
      end
    end

    return true
  end


  # Returns the string representation of the "MAJOR.MINOR.PATCH" version part.
  #
  def number
    @number_components.join('.')
  end


  # Returns the string representation of the pre-release version part.
  #
  def prerelease
    @prerelease_components.join('.')
  end


  # Returns the string representation of the version.
  #
  def to_s
    number +
    (@prerelease_components.empty? ? "" : "-#{prerelease}") +
    (@build_metadata.nil? ? "" : "+#{@build_metadata}")
  end

end
