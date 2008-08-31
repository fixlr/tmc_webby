require 'fileutils'
require 'date'
require 'ostruct'

module ArchivesHelper
  
  ARCHIVES_ROOT = File.join(File.dirname(__FILE__), '..', 'output', 'archives')

  def archives_list
  	strips = @pages.find(:all, :in_directory => 'images/strips').reject {|s| s.url =~ /^\./}
    strips.sort! {|a,b| a.filename <=> b.filename}
    list   = ArchivesList.new

    for a_strip in strips

      # Create individual pages for each archived strip
      page = create_strip_page_for(a_strip)
      page << image_for(a_strip)
      page << previous_link_for(page, strips)
      page << next_link_for(page, strips)
      
      Logging::Logger[self].info "creating output#{page.url}"
      page.save_to_archives!

      # Add a list item to the archive list
      list << page
    end
    "#{list}"
  end

  private
  def create_strip_page_for(strip)
    page = StripPage.new(strip)

    # TODO: Decide whether I can update only the pages that need to be 
    #   updated.  e.g.: New strips + previous + next (to add strip nav)
    #
    # if File.exist? File.join(ARCHIVES_ROOT, page.filename)
    #   return nil
    # else
      return page
    # end
  end
  
  def li_and_a_for(page)
    %(<li><a href="#{page.url}">#{page.filename}</a></li>\n)
  end

# TODO:  Find a better way to determine whether this is the first or last
#   strip in the archives.
# TODO:  Make url for previous_link_for and next_link_for actually point
#   to the previous and next pages.  Right now it points to the current page.
  
  def previous_link_for(page, strips)
    (page.date == strips.first.filename) ? '' : %(<li><a href="#{page.url}">Previous</a></li>)
  end

  def next_link_for(page, strips)
    (page.date == strips.last.filename) ? '' : %(<li><a href="#{page.url}">Next</a></li>)
  end
  
  def image_for(strip)
    %(<p id="comic">
        <img src="#{strip.url}" height="250" width="750" />
      </p>)
  end
  
  
  class StripPage
    attr_reader :filename

    def initialize(strip)
      @filename = "#{strip.filename}.html"
      @content  = ''
      @page     = OpenStruct.new({:title => strip.filename})
    end

    def date
      @filename.split('.').first
    end

    def path
      File.join(ARCHIVES_ROOT, @filename)
    end
    
    def url
      "/archives/#{@filename}"
    end

    def <<(s)
      @content << s
    end

    def save_to_archives!
      template = ERB.new(File.read(File.dirname(__FILE__) + '/../layouts/default.rhtml'))
      File.open(self.path, 'w') do |out|
        out << template.result(binding)
      end
    end
  end
  
  class ArchivesList
    def initialize
      @content = '<ol>'
    end
    
    def <<(page)
      @content << %(<li><a href="#{page.url}">#{page.filename}</a></li>\n)
    end
    
    def to_s
      "#{@content}</ol>"
    end
  end
      
end

Webby::Helpers.register(ArchivesHelper)
