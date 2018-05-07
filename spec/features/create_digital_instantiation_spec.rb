require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Create and Validate Digital Instantiation', js: true do
  context 'Create adminset, create DigitalInstantiation' do
    let(:admin_user) { create :admin_user }
    let!(:user_with_role) { create :user_with_role, role_name: 'user' }
    let(:admin_set_id) { AdminSet.find_or_create_default_admin_set_id }

    let!(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(admin_set_id: admin_set_id) }
    let!(:workflow) { Sipity::Workflow.create!(active: true, name: 'test-workflow', permission_template: permission_template) }

    let(:input_date_format) { '%m/%d/%Y' }
    let(:output_date_format) { '%F' }

    let(:digital_instantiation_attributes) do
      {
          title: "My Test Digital Instantiation",
          media_type: "Moving Image",
          digital_format: 'video/mp4',
          location: 'Test Location',
          date: rand_date_time,
          rights_summary: 'My Test Rights summary',
          rights_link: 'http://somerightslink.com/testlink',
          local_instantiation_identifer: 'localId1234',
          tracks: '1234',
          channel_configuration: 'Configured!',
          alternative_modes: 'This mode is so alternative'
      }
    end

    scenario 'Create and Validate Digital Instantiation, Search Digital Instantiation' do
      Sipity::WorkflowAction.create!(name: 'submit', workflow: workflow)
      Hyrax::PermissionTemplateAccess.create!(
          permission_template_id: permission_template.id,
          agent_type: 'group',
          agent_id: 'user',
          access: 'deposit'
      )
      # Login role user to create DigitalInstantiation
      login_as(user_with_role)

      # create digital instantiation
      visit '/'
      click_link "Share Your Work"
      choose "payload_concern", option: "DigitalInstantiation"
      click_button "Create work"
      expect(page).to have_content "Add New Digital Instantiation", wait: 20
      click_link "Files" # switch tab

      click_link "Descriptions" # switch tab
      fill_in('Title', with: digital_instantiation_attributes[:title])

      # Select Format
      select = page.find('select#digital_instantiation_digital_format')
      select.select digital_instantiation_attributes[:digital_format]

      # Select Media Type
      select = page.find('select#digital_instantiation_media_type')
      select.select digital_instantiation_attributes[:media_type]

      fill_in('Location', with: digital_instantiation_attributes[:location])

      # Expect the required metadata indicator to indicate 'complete'
      expect(page.find("#required-metadata")[:class]).to include "complete"

      click_link "Additional fields" # additional metadata

      fill_in('Date', with: digital_instantiation_attributes[:date].strftime(input_date_format))
      fill_in('Rights summary', with: digital_instantiation_attributes[:rights_summary])
      fill_in('Rights link', with: digital_instantiation_attributes[:rights_link])
      fill_in('Local instantiation identifer', with: digital_instantiation_attributes[:local_instantiation_identifer])
      fill_in('Tracks', with: digital_instantiation_attributes[:tracks])
      fill_in('Channel configuration', with: digital_instantiation_attributes[:channel_configuration])
      fill_in('Alternative modes', with: digital_instantiation_attributes[:alternative_modes])

      click_link "Relationships" # define adminset relation
      find("#digital_instantiation_admin_set_id option[value='#{admin_set_id}']").select_option

      # set it public
      find('body').click
      choose('digital_instantiation_visibility_open')
      expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      click_on('Save')

      wait_for(10) { DigitalInstantiation.where(title: digital_instantiation_attributes[:title]).first }

      visit '/'
      find("#search-submit-header").click

      # expect digital instantiation is showing up
      expect(page).to have_content digital_instantiation_attributes[:title]
      expect(page).to have_content digital_instantiation_attributes[:date].strftime(output_date_format)

      # open digital instantiation with detail show
      click_on(digital_instantiation_attributes[:title])
      expect(page).to have_content digital_instantiation_attributes[:title]
      expect(page).to have_content digital_instantiation_attributes[:media_type]
      expect(page).to have_content digital_instantiation_attributes[:digital_format]
      expect(page).to have_content digital_instantiation_attributes[:location]
      expect(page).to have_content digital_instantiation_attributes[:date].strftime(output_date_format)
      expect(page).to have_content digital_instantiation_attributes[:rights_summary]
      expect(page).to have_content digital_instantiation_attributes[:rights_link]
      expect(page).to have_content digital_instantiation_attributes[:local_instantiation_identifer]
      expect(page).to have_content digital_instantiation_attributes[:tracks]
      expect(page).to have_content digital_instantiation_attributes[:channel_configuration]
      expect(page).to have_content digital_instantiation_attributes[:alternative_modes]
      expect(page).to have_current_path(guid_regex)
    end
  end
end