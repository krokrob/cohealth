require 'open-uri'

class BodaccScraper
  DEFAULT_TIME_SCOPE = 7.days
  BASE_URI = 'https://www.bodacc.fr'

  def announcements(keyword, options = {})
    url = "#{BASE_URI}/annonce/liste"
    response = RestClient.post(
      url, {
        motscles: keyword,
        categorieannonce: 'creation',
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
      names << title.text.gsub(/:/, '').strip
    end
    values = []
    doc.search('#annonce>dl>dd').each do |description|
      the_description = {}
      description.search('dl').each do |sub|
        sub_titles = []
        sub.search('dt').each do |title|
          sub_titles << title.text.gsub(/:/, '').strip
        end
        sub_descriptions = []
        sub.search('dd').each do |description|
          sub_descriptions << description.text.gsub(/[\n|\t| ]+/, ' ').strip
        end
        sub_titles.each_with_index do |sub_title, index|
          the_description[sub_title] = sub_descriptions[index]
        end
      end
      if the_description.empty?
        unless description.text =~ /Dépôt de l'état des créances/
          values << description.text.strip.gsub(/[\n|\t| ]+/, ' ')
        end
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
    naf = doc.search('div[datapath="activite.codeNAF"] p')
    unless naf.empty?
      naf = naf[0].text.split(':').first.strip
    end
    { 'naf' => naf }
  end
end