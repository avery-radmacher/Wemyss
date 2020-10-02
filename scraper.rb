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

# 'https://www.bagpipeonline.com/news/2020/9/15/policy-overview-of-presidential-candidates'
# 'https://www.bagpipeonline.com/opinions/2020/9/12/prevent-a-twindemic-get-a-vaccine'
article = BagpipeArticle.new(ARGV[0] || 'https://www.bagpipeonline.com/news/2015/3/31/dr-whitebro-tempts-students-with-art-again')
article.get_data
article.print_data
