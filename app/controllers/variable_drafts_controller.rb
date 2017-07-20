# :nodoc:
class VariableDraftsController < BaseDraftsController
  before_action :set_resource, only: [:show, :edit, :update, :destroy, :publish]
  before_action :set_schema, only: [:new, :edit, :update, :create]
  before_action :set_form, only: [:edit, :update]
  before_action :set_current_form, only: [:edit]
  before_action :set_science_keywords, only: [:new, :edit]

  def new
    super

    set_form

    set_current_form
  end

  def publish
    draft = get_resource.draft

    ingested = cmr_client.ingest_variable(draft.to_json, get_resource.provider_id, get_resource.native_id, token)

    if ingested.success?
      # get information for publication email notification before draft is deleted
      Rails.logger.info("Audit Log: Draft #{get_resource.entry_title} was published by #{current_user.urs_uid} in provider: #{current_user.provider_id}")
      user_info = get_user_info
      short_name = get_resource.draft['ShortName']
      version = get_resource.draft['Version']

      # Delete draft
      get_resource.destroy

      concept_id = ingested.body['concept-id']
      revision_id = ingested.body['revision-id']

      # instantiate and deliver notification email
      DraftMailer.draft_published_notification(user_info, concept_id, revision_id, short_name, version).deliver_now

      redirect_to collection_path(concept_id, revision_id: revision_id), flash: { success: 'Draft was successfully published.' }
    else
      # Log error message
      Rails.logger.error("Ingest Metadata Error: #{ingested.inspect}")
      Rails.logger.info("User #{current_user.urs_uid} attempted to ingest draft #{get_resource.entry_title} in provider #{current_user.provider_id} but encountered an error.")
      @ingest_errors = generate_ingest_errors(ingested)
      # TODO remove puts
      puts "ingest_errors: #{@ingest_errors}"

      flash[:error] = 'Draft was not published successfully.'
      render :show
    end
  end

  private

  def set_schema
    @schema = UmmJsonSchema.new('umm-var-json-schema.json')
    @schema.fetch_references(@schema.parsed_json)
  end

  def set_form
    @json_form = UmmJsonForm.new('umm-var-form.json', @schema, get_resource.draft, 'field_prefix' => 'variable_draft/draft')
  end

  def set_current_form
    @current_form = params[:form] || @json_form.forms.first.parsed_json['id']
  end

  def set_science_keywords
    # TODO: Move this into the UmmKeywordPicker class, including the rendering of JavaScript
    @science_keywords = cmr_client.get_controlled_keywords('science_keywords')
  end

  def variable_draft_params
    # Allow for completely empty forms to be saved
    return {} unless params.key?(:variable_draft)

    # If the form isn't empty, only permit whitelisted attributes
    params.require(:variable_draft).permit(:draft_type).tap do |whitelisted|
      # Allows for any nested key within the draft hash
      whitelisted[:draft] = params[:variable_draft][:draft]
    end
  end
end
