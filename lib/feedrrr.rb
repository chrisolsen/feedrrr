# Feedrrr
#
# Overview:
#   Allows for conversion of RSS feeds to a JSON format
#
# Usage:
#   # Will attempt to fetch from http://some_domain.com and will follow any redirects.
#   # Will return the description, title and pubDate(default).
#   > RSS::Feedrrr.new("http://some_domain.com", fields: [:description, :title]).get
#
#   # Will do the same as the above example, but if no xml data is found at the specified url
#   # it make make additional requests to each of the alternate paths, following any redirects.
#   > RSS::Feedrrr.new("http://some_domain.com", fields: [:description, :title], alt_paths: [:foo, :bar]).get
#
#   # Obtain the last 42 days of records
#   > RSS::Feedrrr.new("http://some_domain.com", fields: [:description, :title]).get( Date.today - 42)

require "net/http"
require "rexml/document"
require 'date'

module RSS
  class Feedrrr

    def initialize input, params={}
      @input      = input
      @alt_paths  = params[:alt_paths] || []
      @fields     = ((params[:fields]  || []) << :pubDate).uniq
    end

    def get since = nil
      since ||= Date.today - 60
      rss = get_rss
      extract rss, since
    end

  private

    def get_rss
      case @input
      when /^http/
        get_via_http(@input)
      when String
        @input
      when File
        File.read(@input)
      end
    end

    def get_via_http url
      uri = URI.parse url
      response = fetch uri
      if !response.xml? || response.invalid_url?
        if response = fetch_alternates(uri)
          response.body
        end
      else
        response.body
      end
    rescue
      nil
    end

    def fetch uri, redirect_count=0
      response = Net::HTTP.get_response uri
      case response
      when Net::HTTPRedirection then
        return response if redirect_count > 5
        fetch(URI.parse(response.redirected_to), redirect_count += 1)
      else
        response
      end
    end

    def fetch_alternates uri
      @alt_paths.each do |path|
        alt_uri = URI.parse "#{uri.scheme}://#{uri.host}/#{path}"
        response = fetch alt_uri
        if response.ok? && response.xml?
          return response
        end
      end
    end

    def extract rss, since
      return [] if rss.nil?
      data = extract_data rss
      filter_by_date data, since
    end

    def filter_by_date parsed_items, since
      filtered_data = []
      parsed_items[:pubDate].each_with_index do |pub_date, index|
        if Date.parse(pub_date) >= since
          field_set = {}
          @fields.each { |f| field_set[f] = parsed_items[f][index] }
          filtered_data << field_set
        end
      end
      filtered_data
    end

    def extract_data rss
      doc = REXML::Document.new rss
      data = init_json_template
      @fields.each do |f|
        doc.elements.each "//rss/channel/item/#{f}" do |elem|
          data[f] << elem.text
        end
      end
      data
    end

    def init_json_template
      template = {}; @fields.each { |f| template[f] = [] }
      template
    end

  end

end

module Net
  class HTTPResponse
    def ok?
      self.code == "200"
    end

    def invalid_url?
      self.code == "404"
    end

    def xml?
      content_types = ['application/xml', 'application/atom+xml', 'text/xml']
      content_types.include? self.content_type
    end

    def redirected_to
      header["Location"] || header["location"]
    end
  end
end
