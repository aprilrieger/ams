# Generated via
#  `rails generate hyrax:work DigitalInstantiation`

module Hyrax
  class DigitalInstantiationsController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::DigitalInstantiation

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::DigitalInstantiationPresenter
  end
end