# Wemyss
Wemyss ([wɛmɪs]) is a scraping program for the [Bagpipe](https://www.bagpipeonline.com), the student newspaper of Covenant College.

Wemyss is currently comprised of only one program, `scraper.rb`, which downloads general information about each article within a date range. Usage is as follows:

`ruby scraper.rb [datafile] [logfile] [startdate]`

where:

- `datafile` is where scraped article data is written, or `STDOUT` if not provided or `-`,
- `logfile` is where a log of the scraping process is stored, or `STDOUT` if not provided or `-`,
- `startdate` is the earliest (inclusive) date from which articles will be gathered, or `1970/1/1` if not provided or mis-supplied.

## Data format

Data is scraped in the following format:

`link|title|date|category|author|||text`

### Note about dates:

Sometimes the publication date listed on an article's webpage differs slightly from the date listed in the article's link. In these cases the date from the link dominates.

---
## Origin

Wemyss is named after John Wemyss of Logie, the Scottish-born spy who was tried and executed for plotting to blow up a Dutch battlement.