class AnnouncementsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index
  def index
    if params[:keyword]
      @keyword = params[:keyword]
      @headers = ['Catégorie', 'Bodacc', 'Annonce n°', 'Siren', 'RCS',
        'Dénomination', 'Forme juridique', 'Capital', 'Administration',
        'Adresse', 'Qualité', 'Origine du fond', 'Activité', 'Adresse établissement',
        'Début Activité', 'Date de création', 'URL infogreffe', 'NAF']
      @announcements = BodaccScraper.new.announcements(@keyword)
    end
  end
end
