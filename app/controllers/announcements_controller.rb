class AnnouncementsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index

  def index
    return unless params[:keyword]

    @keyword = params[:keyword]
    @headers = [
      'Catégorie', 'Bodacc', 'Annonce n°', 'Siren', 'RCS', 'Nom', 'Prénom',
      'Dénomination', 'Forme juridique', 'Capital', 'Administration',
      'Adresse', 'Qualité', 'Origine du fond', 'Activité', 'Adresse établissement',
      'Adresse du siège social', 'Début Activité', 'Date de création',
      'URL infogreffe', 'NAF', 'Siren précédent', 'Admin précédent'
    ]
    @announcements = BodaccScraper.new.announcements(@keyword)
  end
end
