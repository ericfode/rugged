module Rugged
  class TagCollection
    include Enumerable

    def initialize(repo)
      @repo = repo
    end

    # Returns the tag with the specified name
    def [](name)
      Rugged::TagReference.find(@repo, name)
    end

    # Public: Iterate over a repo's tags.
    #
    # Yields a Rugged::TagReference for each tag that is found in
    # the associated repository. 
    #
    # Examples
    #
    #   each { |tag| puts tag.canonical_name }
    #
    #   each("v1.*").count
    #
    # Returns an Enumerator if no block was given, or nothing.
    def each(pattern = '')
      return enum_for(:each, pattern) unless block_given?

      Rugged::Tag.each(@repo, pattern) do |name|
        if tag = self[name]
          yield tag
        end
      end
    end

    def create(name, target, force = false)
      Rugged::Tag.create :name => name, :target => target, :force => force
      self[name]
    end

    def delete(tag_or_name)
      if tag_or_name.kind_of?(Rugged::TagReference)
        name = Rugged::TagReference.short_name(tag_or_name.canonical_name)
      else
        name = Rugged::TagReference.short_name(tag_or_name)
      end

      Rugged::Tag.delete(@repo, name)
    end
  end
end

module Rugged
  class TagReference < Rugged::Reference
    def self.find(repo, name)
      lookup(repo, canonical_name(name))
    end

    def self.short_name(name)
      name.sub(%r{^refs/tags/}, "")
    end

    def self.canonical_name(name)
      !name.start_with?("refs/tags/") ? "refs/tags/#{name}" : name
    end

    def canonical_name
      self.name
    end

    def ==(other)
      other.kind_of?(Rugged::TagReference) &&
        self.canonical_name == other.canonical_name
    end

    def annotation
      object = Rugged::Object.lookup(@owner, self.target_object)
      object.kind_of?(Rugged::Tag) ? object : nil
    end

    def annotated?
      !!annotation
    end

    alias_method 'target_object', 'target'

    def target
      object = Rugged::Object.lookup(@owner, self.target_object)
      object.kind_of?(Rugged::Tag) ? object.target : object
    end
  end
end