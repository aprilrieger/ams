module AMS
  class PushSearchBuilder < Hyrax::CatalogSearchBuilder
    self.default_processor_chain += [:check]
    def models
      [Asset]
    end

    def check(solr_params)
      require('pry');binding.pry
      solr_params[:q] = 'needs_update: true'
      solr_params
    end
  end
end