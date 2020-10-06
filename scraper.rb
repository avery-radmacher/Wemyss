require 'eat'

def consume link
    sleepTime = 0.001
    while
        begin
            return eat link
        rescue HTTPClient::BadResponseError
            $logFile.write "HTTP: Too many HTTP requests; sleeping #{sleepTime}s\n"
            sleep(sleepTime)
            sleepTime *= 2
        rescue HTTPClient::ReceiveTimeoutError
            $logFile.write "HTTP: Timeout error, retrying in 0.005s\n"
            sleep(0.005)
        end
    end
end

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
        source = consume(@link).to_HtmlSubsection
        article = source.get_block(/\<article class=.*?\<\/article\>/m)
        @author = article.get_author
        @title = article.get_title
        @text = article.get_block(/\<div class="sqs-block-content"\>.*?\<\/div\>/m).get_text
    end

    def print_data
        text = @text.gsub(/\s+/, " ")
        $dataFile.write "#{@title}|#{@author}|||#{text}\n"
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
            consume(listLink).to_HtmlSubsection
                .get_block(/\<ul class="archive-item-list"\>.*?\<\/ul/m)    # filter to monthly lists
                .get_block(/(?<=\<a href=")[^"]*/)                          # filter to article links
                .get_html
                .each do |linkTail|
                    if !@minDate || @minDate <= get_date(linkTail)
                        @links << 'https://www.bagpipeonline.com' + linkTail
                    end
                end
        end
        return @links
    end
end

$dataFile = ARGV[0] && ARGV[0] != "-" ? File.open(ARGV[0], mode = "w") : $stdout
$logFile = ARGV[1] && ARGV[1] != "-" ? File.open(ARGV[1], mode = "w") : $stdout

startTime = Time.now
scraper = LinkScraper.new([
    'https://www.bagpipeonline.com/news-archive',
    'https://www.bagpipeonline.com/arts-archive',
    'https://www.bagpipeonline.com/opinions-archive',
    'https://www.bagpipeonline.com/sports-archive'])
scraper.set_min_date ARGV[2] || ""
scraper.scrape.each do |articleLink|
    $logFile.write "Reading: #{articleLink}...\n"
    article = BagpipeArticle.new(articleLink)
    article.get_data
    $logFile.write "done.\n"
    article.print_data
end
endTime = Time.now
durationTime = (endTime - startTime).round
duration = (durationTime > 3600 ? (durationTime/3600).to_i.to_s + "h " : "") +
    (durationTime > 60 ? (durationTime/60%60).to_i.to_s + "m " : "") + 
    "#{(durationTime % 60).to_i}s"
$logFile.write "Completed in #{duration}"
