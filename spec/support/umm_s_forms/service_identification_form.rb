require 'rails_helper'

shared_examples_for 'Service Identification Form' do
  it 'displays the form with values' do
    expect(page).to have_field('Quality Flag', with: 'Reviewed')
    expect(page).to have_field('Traceability', with: 'traceability')
    expect(page).to have_field('Lineage', with: 'lineage')

    expect(page).to have_field('service_draft_draft_access_constraints_0', with: 'access constraint 1')
    expect(page).to have_field('service_draft_draft_access_constraints_1', with: 'access constraint 2')

    expect(page).to have_field('service_draft_draft_use_constraints_0', with: 'use constraint 1')
    expect(page).to have_field('service_draft_draft_use_constraints_1', with: 'use constraint 2')
  end
end
