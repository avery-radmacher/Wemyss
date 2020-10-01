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
        match = @subtexts[0].match(/\<a.*?\>(.*?)\<\/a\>/)
        return match[1]
    end

    def get_author
        match = @subtexts[0].match(/\<article.*?\>/)
        match = match[0].match(/hentry author.*? /)
        return match[0].gsub(/(hentry author-|-| )/, "hentry author-" => "", "-" => " ", " " => "")
    end

    def get_text
        text = ""
        @subtexts.each {|subtext|
            subtext.scan(/(?<="white-space:pre-wrap;"\>).*?(?=\<\/p)/) {|paragraph|
                text += paragraph.gsub(/\<\/?(strong|em|a|span).*?\/?\>/, "") + "\n"
            }
        }
        return text
            .gsub(/\n+/, "\n\n")
            .gsub(/(&nbsp;| )+/, " ")
    end
end

#source = eat('https://www.bagpipeonline.com/opinions/2020/9/12/prevent-a-twindemic-get-a-vaccine')
source = eat('https://www.bagpipeonline.com/news/2020/9/15/policy-overview-of-presidential-candidates')
    .to_HtmlSubsection
#block = source.get_block(/\<head\>.*\<\/head\>/m)
article = source
    .get_block(/\<article class=.*?\<\/article\>/m)
author = article.get_author
title = article.get_title
articleInfo = article
    .get_block(/\<header\>.*?\<\/header\>/m)
articleText = article
    .get_block(/\<div class="sqs-block-content"\>.*?\<\/div\>/m)
puts title
puts "by #{author}\n\n"
puts articleText.get_text