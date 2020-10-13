if !ARGV[0]
    puts "Must specify an input file"
    return
end

fields = Hash.new()
counts = Hash.new(0)
File.open(ARGV[0], mode = "r").each.with_index {|line, lineNumber|
    if lineNumber == 0
        line.scan(/[^|\n]+/).each_with_index do |match, matchIndex| fields[match] = matchIndex; end
    else
        wordCount = (line.match(/(?:[^|]*\|){#{fields["words"]}}([^|\n]*)/) || [])[1].to_i
        gender = (line.match(/(?:[^|]*\|){#{fields["gender"]}}([^|\n]*)/) || [])[1]
        year = (line.match(/(?:[^|]*\|){#{fields["year"]}}([^|\n]*)/) || [])[1]
        genderYear = gender + "|" + year
        gender = gender + "|*"
        year = "*|" + year
        counts[genderYear] += wordCount
        counts[gender] += wordCount
        counts[year] += wordCount
        counts["*|*"] += wordCount
    end
}

puts "Totals:"
counts.to_a.sort!.each do |count| puts "#{count[0]}: #{count[1]}"; end
