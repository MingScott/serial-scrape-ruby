# serial-scrape-ruby

A project for scraping arbitrary webnovels, with easy extension for specific cases by adding custom classes.

Will generate an html and a mobi with a table of contents.

When scraping formats not specified, will probably work but may contain artifacts (e.g links, incorrectly formatted boxes). If you expand the functionality, please submit a pull request :)

## Dependencies

    sudo apt install ruby calibre
    sudo gem install nokogiri
    sudo gem install mail

* ruby
* calibre

gems
* nokogiri
* mail

## Examples

### Scrape a serial into a mobi at a directory 
ruby serial_scrape.rb -n NAME -s FIRST_CHAPTER_URL -d ~/Downloads

### Scrape a serial into a mobi and send it as an attachment to an email address (default setup is gmx email through smtp as recommended by calibre)
ruby serial_scrape.rb -n NAME -s FIRST_CHAPTER_URL -t EMAIL_TO
-f EMAIL_FROM -p PASSWORD