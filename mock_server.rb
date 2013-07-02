require 'sinatra/base'
require 'json'

class MockySync < Sinatra::Base
    
    configure do
        # set :bind, '10.202.181.183'
        # set :port, 80
        set :recipe_config => {
                "default" => {
                    :test_response_filenames => ["0.txt", "1.txt", "2.txt", "3.txt", "4.txt"]
                },
                "sync_malformed_json_sync_aggregate" => {
                    :aggregate_response_filenames => ["aggregate_0_janky_formatted_json.txt", "aggregate_1_no_new_objects.txt"],
                    :event_directory_response_filenames => ["event_dir_0_one_event.txt"],
                    :theme_response_filenames => ["theme_0.txt"]
                },
                "sync_malformed_json_sync_objects_1" => {
                    :aggregate_response_filenames => ["aggregate_0_1_new_activity, map, organization, person.txt", "aggregate_1_no_new_objects.txt"],
                    :new_and_updated_sync_objects_response_filenames => ["0.txt", "1.txt"],
                    :event_directory_response_filenames => ["event_dir_0_one_event.txt"],
                    :theme_response_filenames => ["theme_0.txt"]
                },
                "sync_update_one_launch_item_w_bad_date" => {
                    :aggregate_response_filenames => ["aggregate_0_update_one_launch_item_object.txt", "aggregate_1_no_new_objects.txt"],
                    :new_and_updated_sync_objects_response_filenames => ["0.txt", "1.txt"],
                    :event_directory_response_filenames => ["event_dir_0_one_event.txt"],
                    :theme_response_filenames => ["theme_0.txt"]
                },
                "sync_one_location_object" => {
                    :aggregate_response_filenames => ["aggregate_0_one_new_location_object.txt", "aggregate_1_no_new_objects.txt"],
                    :new_and_updated_sync_objects_response_filenames => ["0.txt", "1.txt"],
                    :deleted_sync_objects_response_filenames => ["0.txt"],
                    :event_directory_response_filenames => ["event_dir_0_one_event.txt"],
                    :theme_response_filenames => ["theme_0.txt"]
                },
                "sync_update_existing_activity_with_extra_fields" => {
                    :aggregate_response_filenames => ["aggregate_0_update_1_activity.txt", "aggregate_1_no_new_objects.txt"],
                    :new_and_updated_sync_objects_response_filenames => ["0.txt", "1.txt"],
                    :event_directory_response_filenames => ["event_dir_0_one_event.txt"],
                    :theme_response_filenames => ["theme_0.txt"]
                },
                "sync_two_duplicate_activity_objects_with_diff_updated_at_dates" => {
                    :aggregate_response_filenames => ["aggregate_0_one_new_activity.txt", "aggregate_1_no_new_objects.txt"],
                    :new_and_updated_sync_objects_response_filenames => ["0.txt", "1.txt"],
                    :event_directory_response_filenames => ["event_dir_0_one_event.txt"],
                    :theme_response_filenames => ["theme_0.txt"]
                },
                "sync_timeout_on_sync_aggregate" => {
                    :aggregate_response_filenames => ["TIMEOUT"],
                    :event_directory_response_filenames => ["event_dir_0_one_event.txt"],
                    :theme_response_filenames => ["theme_0.txt"]
                }
            }

        set :current_recipe => "default"
        set :current_dataset => "A"

        set :request_counts => {}
    end 

    
    def request_count_key_for_sync_obj(object_name, sync_action)

      var_name = "sync_obj_#{sync_action}_#{object_name}_request_count"
      return var_name.to_sym
    end



    def increment_request_count_setting(request_count_key)
      
      if !settings.request_counts[request_count_key]
        settings.request_counts[request_count_key] = -1
      end

      req_count = settings.request_counts[request_count_key]
      settings.request_counts[request_count_key] = req_count + 1
    end



    def response_filename(request_count_key, response_filenames_key)

        response_filenames = settings.recipe_config[settings.current_recipe][response_filenames_key]
        response_current_index = settings.request_counts[request_count_key]
        
        if (response_current_index >= response_filenames.count)
            response_current_index = response_filenames.count - 1 
        end

        return response_filenames[response_current_index]
    end


    def read_response_file_and_increment_request_count(request_count_key, response_filenames_key, response_path)

        increment_request_count_setting(request_count_key)

        response_filename = response_filename(request_count_key, response_filenames_key)

        if (response_filename == "TIMEOUT")

        end

        response_path = "#{response_path}/#{response_filename}"

        puts response_path
        
        canned_response_string = File.read(response_path)
        return canned_response_string
    end


    get "/" do
      "Hello world! This is mocky, your friendly fake server."
    end

    
    #test endpoint
    get '/test' do

        response_path = "responses/#{settings.current_dataset}/#{settings.current_recipe}/test"

        canned_response_string = read_response_file_and_increment_request_count(:test_request_count, :test_response_filenames, response_path)
        
        puts canned_response_string
        return canned_response_string
    end


    #sync aggregate
    get '/e/:event_oid/synchronization/aggregate/:time.js' do

        response_path = "responses/#{settings.current_dataset}/#{settings.current_recipe}/aggregate_responses"

        canned_response_string = read_response_file_and_increment_request_count(:aggregate_request_count, :aggregate_response_filenames, response_path)

        canned_response_string.gsub!("${LAST_SYNC_DATE}", params[:time])
        canned_response_string.gsub!("${MOCK_SERVER_URL}", settings.bind)

        #puts canned_response_string
        return canned_response_string
    end


    #sync object new and updated
    get '/e/:event_oid/:table_name/new_and_updated/:last_updated_at.js' do
        
        request_count_key = request_count_key_for_sync_obj(params[:table_name], "new_and_updated")

        response_path = "responses/#{settings.current_dataset}/#{settings.current_recipe}/sync_objects_new_and_updated/#{params[:table_name]}"

        canned_response_string = read_response_file_and_increment_request_count(request_count_key, :new_and_updated_sync_objects_response_filenames, response_path)
        
        puts canned_response_string
        return canned_response_string
    end


    #sync object deletes
    get '/e/:event_oid/:table_name/deleted/:last_updated_at.js' do

        request_count_key = request_count_key_for_sync_obj(params[:table_name], "deleted")
      
        response_path = "responses/#{settings.current_dataset}/#{settings.current_recipe}/deleted/#{params[:table_name]}"

        canned_response_string = read_response_file_and_increment_request_count(request_count_key, :deleted_sync_objects_response_filenames, response_path) 
        
        puts canned_response_string
        return canned_response_string
    end

    
    #user aggregate
    get '/client/v3/user/event/:event_oid/aggregate' do

        response_path = "responses/#{settings.current_dataset}/#{settings.current_recipe}/user_aggregate"
        canned_response_string = read_response_file_and_increment_request_count(:user_aggregate_request_count, :user_aggregate_response_filenames, response_path)

        #puts canned_response_string
        return canned_response_string
    end


    #event directory
    get '/client/v3/apps/:app_oid/events' do
      
      status 200
      response.headers['Content-Type'] = "text/json"

      response_path = "responses/#{settings.current_dataset}/#{settings.current_recipe}/event_directory"
      
      canned_response_string = read_response_file_and_increment_request_count(:event_directory_request_count, :event_directory_response_filenames, response_path)

      canned_response_string.gsub!("${MOCK_SERVER_URL}", settings.bind)
  
      #puts canned_response_string
      return canned_response_string
    end


    #invidual event responses; for now these aren't "sequenced" - they remain static and has such have no "response_filenames" key defined in the recipe_config hash
    get '/client/v3/events/:event_oid' do

      status 200
      response.headers['Content-Type'] = "text/json"

      response_path = "responses/#{settings.current_dataset}/#{settings.current_recipe}/events/#{params[:event_oid]}.txt"

      puts response_path
      
      canned_response_string = File.read(response_path)
      canned_response_string.gsub!("${MOCK_SERVER_URL}", settings.bind)

      #puts canned_response_string
      return canned_response_string
    end


    get '/api/client/events/:event_oid/theme' do

      status 200
      response.headers['Content-Type'] = "text/json"

      increment_request_count_setting(:theme_request_count)

      response_filename = response_filename(:theme_request_count, :theme_response_filenames)
      response_path = "responses/#{settings.current_dataset}/#{settings.current_recipe}/theme/#{params[:event_oid]}/#{response_filename}"

      puts response_path
      
      canned_response_string = File.read(response_path)
      canned_response_string.gsub!("${MOCK_SERVER_URL}", settings.bind)

      #puts canned_response_string
      return canned_response_string
    end



    put '/configure' do
      
      new_config = JSON.parse(params[:config])

      settings.current_dataset = new_config["dataset"]
      settings.current_recipe = new_config["recipe"]
      
      settings.request_counts.keys.each do |key|
        settings.request_counts[key] = -1
      end

      puts "Configuring server with dataset: #{settings.current_dataset}, using recipe: #{settings.current_recipe}"

    end


    get '/reset_response_counts' do

      settings.current_recipe = "default"

      settings.request_counts.keys.each do |key|
        settings.request_counts[key] = -1
      end

      puts "reset response counts"

    end

#    run!
end
