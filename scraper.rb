require 'eat'

class String
    def get_block pattern, occurence = 1
        self.scan(pattern) {|block|
            if occurence == 1
                return block
            end
            occurence -= 1
        }
        return ""
    end

    def get_text
        text = ""
        self.scan(/(?<=\>).*?(?=\<)/) {|paragraph|
            text += paragraph + "\n"
        }
        return text
    end
end

source = eat('https://www.bagpipeonline.com/news/2020/9/15/policy-overview-of-presidential-candidates')
#block = source.get_block(/\<head\>.*\<\/head\>/m)
block = source.get_block(/\<article class=.*?\<\/article\>/m)
block = block.get_block(/\<div class="sqs-block-content"\>.*?\<\/div\>/m, 2)
puts block.get_text