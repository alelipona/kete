class TopicsController < ApplicationController
  # since we use dynamic forms based on topic_types and topic_type_fields
  # and topics have their main attributes stored in an xml doc
  # within their content field
  # in fact none of the topics table fields are edited directly
  # we don't do CRUD for topics directly
  # instead we override CRUD here, as well as show
  # and use app/views/topics/_form.rhtml to customize
  # we'll start with using the override syntax for ajaxscaffold
  # the code should easily transferred to something else if we decide to drop it
  ### TinyMCE WYSIWYG editor stuff

  uses_tiny_mce(:options => { :theme => 'advanced',
                  :browsers => %w{ msie gecko},
                  :mode => "textareas",
                  :theme_advanced_toolbar_location => "top",
                  :theme_advanced_toolbar_align => "left",
                  :theme_advanced_resizing => true,
                  :theme_advanced_resize_horizontal => false,
                  :paste_auto_cleanup_on_paste => true,
                  :theme_advanced_buttons1 => %w{ formatselect fontselect fontsizeselect bold italic underline strikethrough separator justifyleft justifycenter justifyright indent outdent separator bullist numlist forecolor backcolor separator link unlink image undo redo},
                  :theme_advanced_buttons2 => [],
                  :theme_advanced_buttons3 => [],
                  :theme_advanced_buttons3_add => %w{ tablecontrols fullscreen},
                  :editor_selector => 'mceEditor',
                  :plugins => %w{ contextmenu paste table fullscreen} },
                :only => [:new, :pick, :list, :create, :edit, :update, :pick_topic_type])
  ### end TinyMCE WYSIWYG editor stuff

  ### ajaxscaffold stuff
  include AjaxScaffold::Controller

  # after_filter :clear_flashes
  before_filter :update_params_filter

  def update_params_filter
    update_params :default_scaffold_id => "topic", :default_sort => nil, :default_sort_direction => "asc"
  end
  def index
    redirect_to :action => 'list'
  end
  def return_to_main
    # If you have multiple scaffolds on the same view then you will want to change this to
    # to whatever controller/action shows all the views
    # (ex: redirect_to :controller => 'AdminConsole', :action => 'index')
    redirect_to :action => 'list'
  end

  def list
  end

  # All posts to change scaffold level variables like sort values or page changes go through this action
  def component_update
    @show_wrapper = false # don't show the outer wrapper elements if we are just updating an existing scaffold
    if request.xhr?
      # If this is an AJAX request then we just want to delegate to the component to rerender itself
      component
    else
      # If this is from a client without javascript we want to update the session parameters and then delegate
      # back to whatever page is displaying the scaffold, which will then rerender all scaffolds with these update parameters
      return_to_main
    end
  end

  def component
    @show_wrapper = true if @show_wrapper.nil?
    @sort_sql = Topic.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Topic.table_name}.#{Topic.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
    @paginator, @topics = paginate(:topics, :order => @sort_by, :per_page => default_per_page)

    render :action => "component", :layout => false
  end

  # this is code not generated by ajaxscaffold
  def pick_topic_type
    # we need to set the topic_type_id from a select box
    # add topic_type_id to params before forwarding the request to new
    @successful = true

    return render(:action => 'pick.rjs') if request.xhr?

    # Javascript disabled fallback
    if @successful
      @options = { :action => "create" }
      render :partial => "new_edit", :layout => true
    else
      return_to_main
    end
  end
  # end code not generated

  def new
    @topic = Topic.new
    @successful = true

    return render(:action => 'new.rjs') if request.xhr?

    # Javascript disabled fallback
    if @successful
      @options = { :action => "pick_topic_type" }
      render :partial => "pick", :layout => true
    else
      return_to_main
    end
  end

  def create
    begin
      # since this is creation, grab the topic_type fields
      topic_type = TopicType.find(params[:topic_type_id])
      params[:topic][:topic_type_id] = params[:topic_type_id]
      @fields = topic_type.topic_type_to_field_mappings
      # TODO: elimenate this HACK for determining name_for_url
      # ultimately I would like url's for peole to do look like the following:
      # topics/people/mcginnis/john
      # topics/people/mcginnis/john_marshall
      # topics/people/mcginnis/john_robert
      # for places:
      # topics/places/nz/wellington/island_bay/the_parade/206
      # events:
      # topics/events/2006/10/31
      # in the meantime we'll just use :name or :first_names and :last_names
      # TODO: helper for downcasing and underscoring

      # here's where we populate the content with our xml
      if @fields.size > 0
        params[:topic][:content] = render_to_string(:partial => 'field_to_xml',
                                                    :collection => @fields,
                                                    :layout => false)
      end

      # in order to get the ajax to work, we put form values in the topic hash
      # in parameters, this will break new and update, because they aren't apart of the model
      # directly, so strip them out of parameters

      replacement_topic_hash = { }
      params[:topic].keys.each do |field_key|
        # we only want real topic columns, not pseudo ones that are handled by content xml
        if Topic.column_names.include?(field_key)
            replacement_topic_hash = replacement_topic_hash.merge(field_key => params[:topic][field_key])
        end
      end

      @topic = Topic.new(replacement_topic_hash)

      # TODO: because id isn't available until after a save, we have a HACK
      # to add id into record during acts_as_zoom
      @topic.oai_record = render_to_string(:template => 'topics/oai_record',
                                           :layout => false)
      @successful = @topic.save

    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    if params[:relate_to_topic_id] and @successful
      ContentItemRelation.new_relation_to_topic(params[:relate_to_topic_id], @topic)
      redirect_to :action => 'show', :controller => '/topics', :id => params[:relate_to_topic_id]
    else
      params[:topic] = replacement_topic_hash
      return render(:action => 'create.rjs') if request.xhr?

      if @successful
        return_to_main
      else
        @options = { :scaffold_id => params[:scaffold_id], :action => "create" }
        render :partial => 'new_edit', :layout => true
      end
    end
  end

  def edit
    begin
      @topic = Topic.find(params[:id])
      @successful = !@topic.nil?
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    return render(:action => 'edit.rjs') if request.xhr?

    if @successful
      @options = { :scaffold_id => params[:scaffold_id], :action => "update", :id => params[:id] }
      render :partial => 'new_edit', :layout => true
    else
      return_to_main
    end
  end

  def update
    begin
      @topic = Topic.find(params[:id])
      topic_type = TopicType.find(@topic.topic_type_id)
      params[:topic][:topic_type_id] = params[:topic_type_id]
      @fields = topic_type.topic_type_to_field_mappings

      if @fields.size > 0
        params[:topic][:content] = render_to_string(:partial => 'field_to_xml',
                                                    :collection => @fields,
                                                    :layout => false)
      end

      # TODO: DRY this up, see create
      replacement_topic_hash = { }
      params[:topic].keys.each do |field_key|
        # we only want real topic columns, not pseudo ones that are handled by content xml
        if Topic.column_names.include?(field_key)
            replacement_topic_hash = replacement_topic_hash.merge(field_key => params[:topic][field_key])
        end
      end
      # update our oai_record virtual attribute
      # see oai_record for TODOs
      @topic.oai_record = render_to_string(:template => 'topics/oai_record',
                                           :layout => false)
      @successful = @topic.update_attributes(replacement_topic_hash)
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    params[:topic] = replacement_topic_hash
    return render(:action => 'update.rjs') if request.xhr?

    if @successful
      return_to_main
    else
      @options = { :action => "update" }
      render :partial => 'new_edit', :layout => true
    end
  end

  def destroy
    begin
      @topic = Topic.find(params[:id])
      # TODO: because id isn't available until after a save, we have a HACK
      # to add id into record during acts_as_zoom
      @topic.oai_record = render_to_string(:template => 'topics/oai_record',
                                           :layout => false)
      @successful = @topic.destroy
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    return render(:action => 'destroy.rjs') if request.xhr?

    # Javascript disabled fallback
    return_to_main
  end

  def cancel
    @successful = true

    return render(:action => 'cancel.rjs') if request.xhr?

    return_to_main
  end
  ### end ajaxscaffold stuff

  def show
    @topic = Topic.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :action => 'oai_record.rxml', :layout => false, :content_type => 'text/xml' }
    end
  end
end
