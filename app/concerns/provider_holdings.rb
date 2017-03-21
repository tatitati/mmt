require 'enumerator'

# Controller methods that allows developers to get this data without
# making an HTTP request (with the exception of the CMR call)
module ProviderHoldings
  extend ActiveSupport::Concern

  def set_data_providers(token = nil)
    providers = cmr_client.get_providers.body

    providers.each do |provider|
      # Request the collections that belong to this provider
      holdings_response = cmr_client.get_provider_holdings(false, provider['provider-id'], token)

      # No additional work is necessary on error
      next if holdings_response.error?

      holdings = holdings_response.body

      # Append the additional information necessary for the view
      provider['collection_count'] = holdings.size
      provider['granule_count'] = holdings.map { |h| h['granule-count'] }.inject(:+) || 0
    end

    @providers = providers.sort_by { |provider| provider['short-name'] }
  end

  def set_provider_holdings(provider_id, token = nil)
    @collections = []

    provider_holdings_response = cmr_client.get_echo_provider_holdings(provider_id)

    @provider = provider_holdings_response.body.fetch('provider', {})

    return if provider_holdings_response.error?
    
    provider_holdings_response = cmr_client.get_provider_holdings(false, @provider['provider_id'], token)

    return if provider_holdings_response.error?

    concept_ids = provider_holdings_response.body.map { |c| c['concept-id'] }

    return if concept_ids.empty?

    # Slice the concept ids into groups of either 2000 (CMR max page size) or the
    # the total number of concept ids, whichever is smaller
    concept_ids.each_slice([concept_ids.count, 2000].min) do |ids|
      search_options = {
        concept_id: provider_holdings_response.body.map { |c| c['concept-id'] },
        include_granule_counts: true,
        page_size: ids.count
      }

      collection_search_response = cmr_client.search_collections(search_options, token)

      next if collection_search_response.error?

      collection_search_response.body.fetch('feed', {}).fetch('entry', []).each do |collection|
        concept_id = collection['id']
        title = collection['title']
        granules = collection['granule_count']
        short_name = collection['short_name']
        version = collection['version_id']

        @collections << {
          'id'         => concept_id,
          'title'      => title,
          'short_name' => short_name,
          'version'    => version,
          'granules'   => granules
        }
      end
    end
  end
end