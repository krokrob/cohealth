require 'open-uri'

class BodaccScraper
  DEFAULT_TIME_SCOPE = 7.days
  BASE_URI = 'https://www.bodacc.fr'
  EXPIRE = 1.week

  def announcements(keyword, options = {})
    from_cache(keyword) do
      url = "#{BASE_URI}/annonce/liste"
      response = RestClient.post(
        url, {
          motscles: keyword,
          # categorieannonce: 'creation',
          typeannonce: 'tout',
          datepublicationmin: Time.zone.today - DEFAULT_TIME_SCOPE,
          publication: 'A'
        },
        { content_type: 'application/x-www-form-urlencoded' }
      )
      # scrape results
      # html = open('list.html')
      html = response.body
      doc = Nokogiri::HTML(html)
      annonces = []
      page_scraper(doc, annonces)
      pages = doc.search('.pagination.top>p>a')
      unless pages.empty?
        next_page = pages[0].attr('href')
        html = open("#{BASE_URI}#{next_page}")
        doc = Nokogiri::HTML(html)
        annonces = page_scraper(doc, annonces)
      end
      annonces.map { |annonce| Announcement.new(annonce) }
    end
  end

  private

  def page_scraper(doc, annonces)
    doc.search('#resultats table p > a').each do |link|
      puts 'Scraping announcement ...'
      path = link.attr('href')
      annonces << annonce_parser(path)
      puts 'Scraping done.'
      puts
    end
    annonces
  end

  def annonce_parser(path)
    html = open("#{BASE_URI}#{path}")
    # html = open(path)
    doc = Nokogiri::HTML(html)
    annonce = {}
    annonce['Catégorie'] = doc.search('#annonce>h3').first.text.gsub(/[\n|\t| ]+/, ' ').strip
    annonce['Bodacc'] = doc.search('#annonce>p.standardMargin>em').text.strip
    names = []
    doc.search('#annonce>dl>dt').each do |title|
      names << title.text.delete(':').strip
    end
    values = []
    doc.search('#annonce>dl>dt+dd').each do |description|
      the_description = {}
      description.search('dl').each do |sub|
        sub_titles = []
        sub.search('dt').each do |title|
          sub_titles << title.text.delete(':').strip
        end
        sub_descriptions = []
        sub.search('dd').each do |sub_description|
          sub_descriptions << sub_description.text.gsub(/[\n|\t| ]+/, ' ').strip
        end
        sub_titles.each_with_index do |sub_title, index|
          the_description[sub_title] = sub_descriptions[index]
        end
      end
      if the_description.empty?
        values << description.text.strip.gsub(/[\n|\t| ]+/, ' ')
      else
        values << the_description
      end
    end
    names.each_with_index do |name, index|
      annonce[name] = values[index]
    end
    annonce['infogreffe'] = doc.search('.lienExterne').attr('href').value
    annonce.merge!(ig_parser(annonce['infogreffe']))
    annonce
  end

  def ig_parser(link)
    response = RestClient.get(link)
    html = response.body
    # html = open('infogreffe.html')
    doc = Nokogiri::HTML(html)
    naf = doc.search('div[datapath="activite.codeNAF"] p')[0]
    naf = naf.text.split(':').first.strip unless naf.nil?
    { 'naf' => naf }
  end

  def from_cache(keyword)
    key = "search:keyword:#{keyword}:date:#{Time.zone.today.strftime('%Y%m%d')}"
    if !ENV['DISABLE_CACHE'] && cached_value = redis.get(key)
      Marshal.load(cached_value)
    else
      value_to_cache = yield
      redis.set(key, Marshal.dump(value_to_cache))
      redis.expire(key, EXPIRE)
      value_to_cache
    end
  end

  def redis
    @redis ||= Redis.new
  end
end
