module Rugged
  class TagCollection
    include Enumerable

    def initialize(repo)
      @repo = repo
    end

    # Returns the tag with the specified name
    def [](name)
      name = canonical_name(name)
      return unless ref = Rugged::Reference.lookup(@repo, name)
      Rugged::TagReference.new(@repo, ref, name)
    end

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
        name = short_name(tag_or_name.canonical_name)
      else
        name = short_name(tag_or_name)
      end

      Rugged::Tag.delete(@repo, name)
    end

    protected

    def short_name(name)
      name.sub(%r{^refs/tags/}, "")
    end

    def canonical_name(name)
      !name.start_with?("refs/tags/") ? "refs/tags/#{name}" : name
    end
  end
end

module Rugged
  class TagReference
    attr_reader :canonical_name
    attr_reader :repository

    def initialize(repo, reference, canonical_name)
      @repo = repo
      @reference = reference
      @canonical_name = canonical_name
    end

    def ==(other)
      other.kind_of?(Rugged::TagReference) &&
        @canonical_name == other.canonical_name
    end

    def annotation
      object = Rugged::Object.lookup(@repo, @reference.target)
      object.kind_of?(Rugged::Tag) ? object : nil
    end

    def annotated?
      !!annotation
    end

    def target
      object = Rugged::Object.lookup(@repo, @reference.target)
      object.kind_of?(Rugged::Tag) ? object.target : object
    end
  end
end