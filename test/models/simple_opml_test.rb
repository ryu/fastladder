require "test_helper"

class SimpleOpmlTest < ActiveSupport::TestCase
  test "generates valid OPML structure" do
    opml = SimpleOpml.new
    xml = opml.to_xml

    assert_includes xml, '<?xml version="1.0" encoding="utf-8"?>'
    assert_includes xml, '<opml version="1.0">'
    assert_includes xml, '<title>Subscriptions</title>'
    assert_includes xml, '</opml>'
  end

  test "adds outline with hash" do
    opml = SimpleOpml.new
    opml << { title: "Test Feed", xml_url: "http://example.com/feed.xml" }
    xml = opml.to_xml

    assert_includes xml, 'title="Test Feed"'
    assert_includes xml, 'xmlUrl="http://example.com/feed.xml"'
  end

  test "adds outline object" do
    opml = SimpleOpml.new
    outline = SimpleOpml::Outline.new(title: "Test Feed", xml_url: "http://example.com/feed.xml")
    opml << outline
    xml = opml.to_xml

    assert_includes xml, 'title="Test Feed"'
  end

  test "escapes HTML entities in attributes" do
    opml = SimpleOpml.new
    opml << { title: "Feed <with> \"special\" & 'chars'" }
    xml = opml.to_xml

    assert_includes xml, "&lt;"
    assert_includes xml, "&gt;"
    assert_includes xml, "&quot;"
    assert_includes xml, "&amp;"
  end

  test "outline children? returns false when empty" do
    outline = SimpleOpml::Outline.new(title: "Test")

    assert_not outline.children?
  end

  test "outline children? returns true with nested outlines" do
    parent = SimpleOpml::Outline.new(title: "Folder")
    child = SimpleOpml::Outline.new(title: "Feed", xml_url: "http://example.com/feed.xml")
    parent << child

    assert_predicate parent, :children?
  end

  test "self-closing tag for outline without children" do
    outline = SimpleOpml::Outline.new(title: "Feed")
    xml = outline.to_xml

    assert_includes xml, "/>"
    assert_not_includes xml, "</outline>"
  end

  test "closing tag for outline with children" do
    parent = SimpleOpml::Outline.new(title: "Folder")
    child = SimpleOpml::Outline.new(title: "Feed")
    parent << child
    xml = parent.to_xml

    assert_includes xml, "</outline>"
  end

  test "outline attributes use camelCase" do
    outline = SimpleOpml::Outline.new(html_url: "http://example.com", xml_url: "http://example.com/feed.xml")
    xml = outline.to_xml

    assert_includes xml, 'htmlUrl='
    assert_includes xml, 'xmlUrl='
  end

  test "includes dateCreated in header" do
    opml = SimpleOpml.new
    xml = opml.to_xml

    assert_match(%r{<dateCreated>.+</dateCreated>}, xml)
  end
end
