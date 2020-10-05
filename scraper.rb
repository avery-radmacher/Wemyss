require 'eat'

class String
    def to_HtmlSubsection
        return HtmlSubsection.new self
    end
end

class HtmlSubsection
    def initialize texts = nil
        @subtexts = []
        if texts.kind_of? Array
            @subtexts = texts
        elsif texts.kind_of? String
            @subtexts << texts.to_s
        end
    end
    
    def get_block pattern, occurence = -1
        newSubtexts = []
        @subtexts.each {|subtext|
            subtext.scan(pattern) {|block|
                if occurence == 1 || occurence == -1
                    newSubtexts << block
                end
                if occurence != -1
                    occurence -= 1
                end
            }
        }
        return HtmlSubsection.new newSubtexts
    end

    def get_title
        if @subtexts.length == 0; return ""; end
        match = @subtexts[0].match(/\<a.*?\>(.*?)\<\/a\>/)
        return match[1] || ""
    end

    def get_author
        if @subtexts.length == 0; return ""; end
        match = @subtexts[0].match(/\<article.*?\>/) || [""]
        match = match[0].match(/hentry.*?author.*? /) || [""]
        return match[0].gsub(/hentry.*?author-| |(.)/, '\1').gsub("-", " ") || ""
    end

    def get_text
        text = ""
        @subtexts.each {|subtext|
            subtext.scan(/\<p.*?\>.*?\<\/p\>/) {|paragraph|
                text += paragraph.gsub(/\<\/?(p|strong|em|br|a|span).*?\/?\>/, "") + "\n"
            }
        }
        return text
            .gsub(/“|”/, '"')
            .gsub(/‘|’/, "'")
            .gsub(/\n+/, "\n\n")
            .gsub(/(&nbsp;| )+/, " ")
            .gsub(/[^a-zA-Z0-9,:;'"\.\!\?\@\#\$\%\&\*\-\+\=\/\{\}\[\]\(\)\n]/, " ")
    end

    def get_html
        return @subtexts
    end
end

class BagpipeArticle
    def initialize link
        @link = link
    end

    def get_data
        source = eat(@link).to_HtmlSubsection
        article = source.get_block(/\<article class=.*?\<\/article\>/m)
        @author = article.get_author
        @title = article.get_title
        @text = article.get_block(/\<div class="sqs-block-content"\>.*?\<\/div\>/m).get_text
    end

    def print_data
        puts @title
        puts "by #{@author}\n\n"
        puts @text
    end
end

class LinkScraper
    def initialize links
        @listLinks = links
    end

    def set_min_date date
        @minDate = get_date date
    end

    def get_date string, errDate = '1970/1/1'
        match = string.match(/\d{4}\/\d\d?\/\d\d?/)
        date = match[0] || errDate
        date = date.gsub(/\/(\d)\//, '/0\1/').gsub(/\/(\d)\Z/, '/0\1')
        return date
    end

    def scrape
        @links = []
        @listLinks.each do |listLink|
            eat(listLink).to_HtmlSubsection
                .get_block(/\<ul class="archive-item-list"\>.*?\<\/ul/m)    # filter to monthly lists
                .get_block(/(?<=\<a href=")[^"]*/)                          # filter to article links
                .get_html
                .each do |linkTail|
                    if !@minDate || @minDate <= get_date(linkTail)
                        @links << 'https://www.bagpipeonline.com' + linkTail
                    end
                end
        end
    end

    def test
        @links.each do |link|
            puts link
        end
    end
end

# 'https://www.bagpipeonline.com/news/2020/9/15/policy-overview-of-presidential-candidates'
# 'https://www.bagpipeonline.com/opinions/2020/9/12/prevent-a-twindemic-get-a-vaccine'
# article = BagpipeArticle.new(ARGV[0] || 'https://www.bagpipeonline.com/news/2015/3/31/dr-whitebro-tempts-students-with-art-again')
# article.get_data
# article.print_data
scraper = LinkScraper.new(['https://www.bagpipeonline.com/news-archive'])
scraper.set_min_date '2020/3/28'
scraper.scrape
scraper.test
