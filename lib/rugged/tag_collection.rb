module Rugged
  class TagCollection
    include Enumerable

    def initialize(repo)
      @repo = repo
    end

    # Returns the tag with the specified name
    def [](name)
      name = "refs/tags/#{name}" unless name.start_with?("refs/tags/")
      return unless ref = Rugged::Reference.lookup(@repo, name)
      Rugged::TagReference.new(@repo, ref, name)
    end

    def each
      Rugged::Tag.each(@repo) do |name|
        if tag = self[name]
          yield tag
        end
      end
    end

    def create(name, target, force = false)
      Rugged::Tag.create :name => name, :target => target, :force => force
      self[name]
    end

    def delete(*tags_or_names)
      tags_or_names.each do |tag_or_name|
        tag_or_name = tag_or_name.name if tag_or_name.kind_of?(Rugged::Tag)
        Ruggged::Tag.delete(@repo, tag_or_name)
      end
    end
  end
end

module Rugged
  class TagReference
    attr_reader :canonical_name

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