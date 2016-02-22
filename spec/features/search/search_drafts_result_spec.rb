# MMT-11

require 'rails_helper'

describe 'Search drafts results', js: true do
  short_name = 'id_123'
  entry_title = 'Aircraft Flux-Filtered: Univ. Col. (FIFE)'

  before :each do
    login
    create(:draft, entry_title: entry_title, short_name: short_name)
  end

  context 'when searching drafts by short name' do
    before do
      full_search(full_search_term: short_name, record_type: 'Drafts')
    end

    it 'displays collection results' do
      expect(page).to have_search_query(1, "Drafts Search Term: #{short_name}", 'Record State: Draft Records')
    end

    it 'displays expected data' do
      within '#search-results' do
        expect(page).to have_content(short_name)
        expect(page).to have_content(entry_title)
      end
    end
  end

  context 'when searching drafts by entry title' do
    before do
      full_search(full_search_term: entry_title, record_type: 'Drafts')
    end

    it 'displays collection results' do
      expect(page).to have_search_query(1, "Drafts Search Term: #{entry_title}", 'Record State: Draft Records')
    end

    it 'displays expected data' do
      within '#search-results' do
        expect(page).to have_content(short_name)
        expect(page).to have_content(entry_title)
      end
    end
  end
end

# MMT-389
describe 'Search results permissions for drafts', js: true, reset_provider: true do
  short_name = 'Climate Change'
  entry_title = 'Climate Observation Record'
  provider = 'MMT_2'
  modal_text = 'requires you change your provider context to MMT_2'

  context 'when searching drafts' do
    before do
      login
      draft = create(:draft, entry_title: entry_title, short_name: short_name, provider_id: provider)
    end

    context 'when drafts are from current provider' do
      before do
        user = User.first
        user.provider_id = 'MMT_2'
        user.save

        full_search(full_search_term: entry_title, record_type: 'Drafts')
      end

      it 'search results contain the draft' do
        expect(page).to have_search_query(1, "Drafts Search Term: #{entry_title}", 'Record State: Draft Records')
        within '#collection_search_results' do
          expect(page).to have_content(short_name)
          expect(page).to have_content(entry_title)
          expect(page).to have_content(provider)
          expect(page).to have_content(today_string)
        end
      end

      it 'allows user to view the draft preview page' do
        within '#collection_search_results' do
          click_on short_name
        end

        expect(page).to have_content("#{entry_title} DRAFT RECORD")
        expect(page).to have_content("Publish Draft")
        expect(page).to have_content("Delete Draft")
      end
    end

    context 'when drafts are from available providers' do
      before do
        user = User.first
        user.provider_id = 'MMT_1'
        user.available_providers = %w(MMT_1 MMT_2)
        user.save

        full_search(full_search_term: short_name, record_type: 'Drafts')
      end

      it 'search results contain the draft' do
        expect(page).to have_search_query(1, "Drafts Search Term: #{short_name}", 'Record State: Draft Records')
        expect(page).to have_content(short_name)
        expect(page).to have_content(entry_title)
        expect(page).to have_content(provider)
        expect(page).to have_content(today_string)
      end

      context 'when trying to view the draft' do
        before do
          within '#collection_search_results' do
            click_on short_name
          end
        end

        it 'displays a modal informing the user they need to switch providers' do
          expect(page).to have_content("Viewing this draft #{modal_text}")
        end

        context 'when clicking Yes' do
          before do
            find('.not-current-provider-link').click
            wait_for_ajax
          end

          it 'switches the provider context' do
            expect(User.first.provider_id).to eq('MMT_2')
          end

          it 'shows the draft preview page' do
            expect(page).to have_content("#{entry_title} DRAFT RECORD")
            expect(page).to have_content("Publish Draft")
            expect(page).to have_content("Delete Draft")
          end
        end
      end
    end

    context 'when drafts are not from available providers' do
      before do
        user = User.first
        user.provider_id = 'SEDAC'
        user.available_providers = ['SEDAC']
        user.save

        full_search(full_search_term: short_name, record_type: 'Drafts')
      end

      it 'does not find the drafts' do
        within '#collection_search_results' do
          expect(page).to have_no_content(short_name)
          expect(page).to have_no_content(entry_title)
          expect(page).to have_no_content(provider)
        end
      end
    end
  end
end
