require "test_helper"

class TagCollectionTest < Rugged::SandboxedTestCase
  def setup
    super
    @repo = sandbox_init("testrepo")
    @tags = Rugged::TagCollection.new(@repo)
  end

  def test_array_access
    assert_kind_of Rugged::TagReference, @tags["refs/tags/test"]
    assert_kind_of Rugged::TagReference, @tags["test"]

    assert_equal @tags["refs/tags/test"], @tags["test"]

    assert_nil @tags["refs/tags/this-does-not-exist"]
  end

  def test_each
    tags = []
    
    @tags.each do |tag|
      tag.is_a?(Rugged::TagReference)
      tags << tag.canonical_name
    end

    assert_equal tags, [
      "refs/tags/packed-tag",
      "refs/tags/e90810b",
      "refs/tags/foo/bar",
      "refs/tags/foo/foo/bar",
      "refs/tags/point_to_blob",
      "refs/tags/test"
    ]
  end

  def test_each_with_pattern
    tags = []
    
    @tags.each("foo/*") do |tag|
      tag.is_a?(Rugged::TagReference)
      tags << tag.canonical_name
    end

    assert_equal tags, ["refs/tags/foo/bar", "refs/tags/foo/foo/bar"]
  end

  def test_delete_with_short_name
    @tags.delete("test")

    assert_nil @tags.find { |tag| tag.canonical_name == "refs/tags/test" }
  end

  def test_delete_with_canonical_name
    @tags.delete("refs/tags/test")

    assert_nil @tags.find { |tag| tag.canonical_name == "refs/tags/test" }
  end

  def test_delete_raises_error_with_nonexistant_name
    assert_raises Rugged::ReferenceError do
      @tags.delete("this-does-not-exist")
    end

    assert_raises Rugged::ReferenceError do
      @tags.delete("refs/tags/this-does-not-exist")
    end
  end

  def test_delete_with_tag
    @tags.delete(@tags["test"])

    assert_nil @tags.find { |tag| tag.canonical_name == "refs/tags/test" }
  end
end


class TagReferenceTest < Rugged::SandboxedTestCase
  def setup
    super
    @repo = sandbox_init("testrepo")
    @tags = Rugged::TagCollection.new(@repo)
  end

  def test_annotation_with_lightweight_tag
    assert_nil @tags["refs/tags/point_to_blob"].annotation
  end

  def test_annotation
    assert_kind_of Rugged::Tag, @tags["refs/tags/packed-tag"].annotation
    assert_equal "This is a test tag\n", @tags["refs/tags/packed-tag"].annotation.message
    assert_equal "b25fa35b38051e4ae45d4222e795f9df2e43f1d1", @tags["refs/tags/packed-tag"].annotation.oid

    assert_kind_of Rugged::Tag, @tags["refs/tags/e90810b"].annotation
    assert_equal "This is a very simple tag.\n", @tags["refs/tags/e90810b"].annotation.message
    assert_equal "7b4384978d2493e851f9cca7858815fac9b10980", @tags["refs/tags/e90810b"].annotation.oid

    assert_equal "b25fa35b38051e4ae45d4222e795f9df2e43f1d1", @tags["refs/tags/foo/bar"].annotation.oid
    assert_equal "b25fa35b38051e4ae45d4222e795f9df2e43f1d1", @tags["refs/tags/foo/foo/bar"].annotation.oid
    assert_equal "b25fa35b38051e4ae45d4222e795f9df2e43f1d1", @tags["refs/tags/test"].annotation.oid
  end

  def test_target_with_lightweight_tag
    assert_kind_of Rugged::Blob, @tags["refs/tags/point_to_blob"].target
    assert_equal "1385f264afb75a56a5bec74243be9b367ba4ca08", @tags["refs/tags/point_to_blob"].target.oid
  end

  def test_target
    assert_kind_of Rugged::Commit, @tags["refs/tags/e90810b"].target
    assert_equal "e90810b8df3e80c413d903f631643c716887138d", @tags["refs/tags/e90810b"].target.oid
  end
end