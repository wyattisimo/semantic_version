semantic_version
================

A utility for comparing semantic version numbers (see: http://semver.org).

### Usage

Initialize a new SemanticVersion object with `SemanticVersion.new()` or `SemanticVersion[]`.

SemanticVersion objects have an `is` method for comparing against strings or other SemanticVersion objects.

__Available operators for use with the `is` method:__

* `eq` or `equal_to` returns true if versions are equivalent; false otherwise
* `lt` or `less_than` returns true if SemanticVersion is less than comparison version; false otherwise
* `lte` or `less_than_or_equal_to` returns true if SemanticVersion is less than or equal to comparison version; false otherwise
* `gt` or `greater_than` returns true if SemanticVersion is greater than comparison version; false otherwise
* `gte` or `greater_than_or_equal_to` returns true if SemanticVersion is greater than or equal to comparison version; false otherwise
* `between` returns true if SemanticVersion falls between two comparison versions; false otherwise
* `within` returns true if SemanticVersion falls within the range of two comparison versions (inclusive); false otherwise
* `any_of` returns true if SemanticVersion is equivalent to any of the versions in a list; false otherwise

__Examples:__

```ruby
version_a = SemanticVersion.new("1.0")
version_b = SemanticVersion.new("2.0")
version_a.is less_than: version_b                                  #=> true

SemanticVersion["2.5.0"].is eq: "2.5"                              #=> true

SemanticVersion["2.5.0"].is gt: "2.5.0-beta"                       #=> true

SemanticVersion["3.2.0-beta"].is gt: "3.2.0-alpha", lt: "3.2.0-rc" #=> true

SemanticVersion["5.6.2"].is between: ["5.6.0", "5.6.4"]            #=> true

SemanticVersion["2.2.48"].is any_of: ["2.2.2", "2.2.48", "3.8.0"]  #=> true

SemanticVersion["1.0.0-rc+1234"].is eq: "1.0.0-rc+6789"            #=> true
```
