require 'minitest/autorun'
require './../lib/feedrrr'

describe RSS::Feedrrr do

  def setup
    @url = "http://crossfitedmonton.ca"
  end

  it "should return blank data on an invalid hostname" do
    feed = RSS::Feedrrr.new('http://crossfitedmontonfoo.ca/feed/', fields: [:link, :title, :description]).get
    assert_operator feed.size, :==, 0
  end

  it "should make full HTTP requests" do
    feed = RSS::Feedrrr.new('http://crossfitedmonton.ca/feed/', fields: [:link, :title, :description]).get
    assert_operator feed.size, :>, 0
  end

  it 'should follow redirects' do
    feed = RSS::Feedrrr.new('http://crossfitedmonton.ca/feed', fields: [:link, :title, :description]).get
    assert_operator feed.size, :>, 0
  end

  it 'should try different urls if an xml content type is not returned' do
    feeder = RSS::Feedrrr.new('http://crossfitedmonton.ca',
                            fields: [:link, :title, :description],
                            alt_paths: [:wod, :wods, :workouts, :feed])
    feed = feeder.get
    assert_operator feed.size, :>, 0
  end

  it "should return a blank array if no items exist" do
    feed = RSS::Feedrrr.new("", fields: [:link, :title, :description])
    assert_equal 0, feed.get.size
  end

  it "should parse the rss feed" do
    since = Date.parse("2012-01-01")
    file = File.open("data/feed.xml")
    feed = RSS::Feedrrr.new(file, fields: [:link, :title, :description])
    rss = feed.get(since)

    assert_match %r{http://crossfitEdmonton.ca/2012/11/29/friday-nov-30-2012}, rss.first[:link]
    assert_match %r{AMRAP in 20 mins 1 Rope climb 3 Manmakers}, rss.first[:description]
    assert_match %r{Friday Nov 30 2012}, rss.first[:title]
  end

  it "should return only the items since specified" do
    since = Date.parse("2012-11-29")
    file = File.open("data/feed.xml")
    feed = RSS::Feedrrr.new(file, fields: [:link, :title, :description])
    rss = feed.get(since)

    assert_equal 2, rss.size
  end

  it "should obtain last 60 days workouts if no *since* param is passed to the get method" do
    rss = <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0"
        xmlns:content="http://purl.org/rss/1.0/modules/content/"
        xmlns:wfw="http://wellformedweb.org/CommentAPI/"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:atom="http://www.w3.org/2005/Atom"
        xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
        xmlns:slash="http://purl.org/rss/1.0/modules/slash/">

      <channel>
        <title>Crossfit Edmonton</title>
        <atom:link href="http://crossfitEdmonton.ca/feed/" rel="self" type="application/rss+xml" />
          <item>
            <title>Friday Nov 30 2012</title>
            <link>http://crossfitEdmonton.ca/2012/11/29/friday-nov-30-2012/</link>
            <comments>http://crossfitEdmonton.ca/2012/11/29/friday-nov-30-2012/#comments</comments>
            <pubDate>#{Date.today}</pubDate>
            <dc:creator>Suzanne Bougs</dc:creator>
            <category><![CDATA[WOD]]></category>
            <guid isPermaLink="false">http://xfitedmonton.wpengine.com/?p=8986</guid>
            <description><![CDATA[&#160; AMRAP in 20 mins 1 Rope climb 3 Manmakers 35/20 lbs db's 5 Sandbag get ups 10 K2Es]]></description>
            <content:encoded><![CDATA[ Details here ]]></content:encoded>
            <wfw:commentRss>http://crossfitEdmonton.ca/2012/11/29/friday-nov-30-2012/feed/</wfw:commentRss>
            <slash:comments>0</slash:comments>
          </item>
          <item>
            <title>Thursday Nov 29 2012</title>
            <link>http://crossfitEdmonton.ca/2012/11/28/thursday-nov-29-2012/</link>
            <comments>http://crossfitEdmonton.ca/2012/11/28/thursday-nov-29-2012/#comments</comments>
            <pubDate>#{Date.today - 59}</pubDate>
            <dc:creator>Suzanne Bougs</dc:creator>
            <category><![CDATA[WOD]]></category>
            <guid isPermaLink="false">http://xfitedmonton.wpengine.com/?p=8985</guid>
            <description><![CDATA[&#160; Jerk 10&#215;1 (Find a heavy single) AMRAP in 8 mins 10 Pull up 8 Power clean 135/95 L2 Complete in as few sets as possible 50 Pull ups 30 Power cleans 135/95]]></description>
            <content:encoded><![CDATA[ Details here ]]></content:encoded>
            <wfw:commentRss>http://crossfitEdmonton.ca/2012/11/28/thursday-nov-29-2012/feed/</wfw:commentRss>
            <slash:comments>0</slash:comments>
          </item>
          <item>
            <title>Thursday Nov 29 2012</title>
            <link>http://crossfitEdmonton.ca/2012/11/28/thursday-nov-29-2012/</link>
            <comments>http://crossfitEdmonton.ca/2012/11/28/thursday-nov-29-2012/#comments</comments>
            <pubDate>#{Date.today - 61}</pubDate>
            <dc:creator>Suzanne Bougs</dc:creator>
            <category><![CDATA[WOD]]></category>
            <guid isPermaLink="false">http://xfitedmonton.wpengine.com/?p=8985</guid>
            <description><![CDATA[&#160; Jerk 10&#215;1 (Find a heavy single) AMRAP in 8 mins 10 Pull up 8 Power clean 135/95 L2 Complete in as few sets as possible 50 Pull ups 30 Power cleans 135/95]]></description>
            <content:encoded><![CDATA[ Details here ]]></content:encoded>
            <wfw:commentRss>http://crossfitEdmonton.ca/2012/11/28/thursday-nov-29-2012/feed/</wfw:commentRss>
            <slash:comments>0</slash:comments>
          </item>
        </channel>
      </rss>
    EOF

    feed = RSS::Feedrrr.new(rss, fields: [:link, :title, :description])
    assert_equal 2, feed.get.size
  end
end
