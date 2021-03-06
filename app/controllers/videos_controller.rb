class VideosController < ApplicationController


  before_filter :user_signed_in, :only => [:create, :edit, :new, :show_user_videos]

  def following
    @videos = []

    current_user.all_following.each  { |cu|
      @videos << cu.videos.first 
    } 

    current_user.last_checked_followers = DateTime.current
    current_user.save 

    render 'index'
  end


  # GET /videos
  # GET /videos.json
  def index



    @yt_client = YouTubeIt::Client.new(:dev_key => ENV["YOUTUBE_DEV_KEY"])

    @videos = Video.search(params[:search])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @videos }
    end
  end

  def show_user_videos 
    if user_signed_in?
      @yt_client = YouTubeIt::Client.new(:dev_key => "AI39si6hkRNCL77mzzv1LycIohZtksVIi0L5S9lQMx6crqOfGdyKcB2U2M5WHeNBUT2VLgTVzjR9rxPa1RJZw-sZ6wqtnaZ7AA")
      @videos = Video.find_all_by_user_id(current_user)
      redirect_to new_video_path and return if @videos.nil?

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @videos }
      end

    else 
      redirect_to beta_path
    end

  end 

  # GET /videos/1
  # GET /videos/1.json
  def show
    @yt_client = YouTubeIt::Client.new(:dev_key => "AI39si6hkRNCL77mzzv1LycIohZtksVIi0L5S9lQMx6crqOfGdyKcB2U2M5WHeNBUT2VLgTVzjR9rxPa1RJZw-sZ6wqtnaZ7AA")
    @video = Video.find(params[:id])

    @comments = @video.comments.all


    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @video }
    end
  end

  # GET /videos/new
  # GET /videos/new.json
  def new
    @video = Video.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @video }
    end
  end

  # GET /videos/1/edit
  def edit
    @video = Video.find(params[:id])
    redirect_to @video unless @video.user_id == current_user.id 
  end

  # POST /videos
  # POST /videos.json
  def create
    @video = current_user.videos.build(params[:video])

    @url = params[:video][:url]


    require 'uri'


    if(@url.downcase.include? 'youtube.com')
      ##create ways to catch if user is using 
      query_string = URI.parse(params[:video][:url]).query
      parameters = Hash[URI.decode_www_form(query_string)]
      puts parameters['v'] # => aNdMiIAlK0g
      video_id = parameters['v']
    elsif (@url.downcase.include? 'y2u.be')
      puts video_id = @url.match(/\.be\/(.+)$/)[1]
      @url = 'http://www.youtube.com/watch?v='+video_id
      @video.url = @url 
    elsif (@url.downcase.include? 'youtu.be')
      puts video_id = @url.match(/\.be\/(.+)$/)[1]
      @url = 'http://www.youtube.com/watch?v='+video_id
      @video.url = @url
    end
      
      

    @yt_client = YouTubeIt::Client.new(:dev_key => "AI39si6hkRNCL77mzzv1LycIohZtksVIi0L5S9lQMx6crqOfGdyKcB2U2M5WHeNBUT2VLgTVzjR9rxPa1RJZw-sZ6wqtnaZ7AA")
    @video.youtube_id = video_id # => aNdMiIAlK0g

    this_video = @yt_client.video_by(video_id)


    @video.duration = this_video.duration 



    respond_to do |format|
      if @video.save ##and video is over 60 seconds in duration 
        format.html { redirect_to @video, notice: 'Video was successfully created.' }
        format.json { render json: @video, status: :created, location: @video }
      else
        format.html { render action: "new" }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /videos/1
  # PUT /videos/1.json
  def update


    @video = Video.find(params[:id])


    @url = params[:video][:url]

    require 'uri'


    if(@url.downcase.include? 'youtube.com')
      ##create ways to catch if user is using 
      query_string = URI.parse(params[:video][:url]).query
      parameters = Hash[URI.decode_www_form(query_string)]
      puts parameters['v'] # => aNdMiIAlK0g
      video_id = parameters['v']
    elsif (@url.downcase.include? 'y2u.be')
      puts video_id = @url.match(/\.be\/(.+)$/)[1]
      @url = 'http://www.youtube.com/watch?v='+video_id
      puts params[:video][:url] = @url 
    elsif (@url.downcase.include? 'youtu.be')
      puts video_id = @url.match(/\.be\/(.+)$/)[1]
      @url = 'http://www.youtube.com/watch?v='+video_id
      puts params[:video][:url] = @url
    end
      
      

    @yt_client = YouTubeIt::Client.new(:dev_key => "AI39si6hkRNCL77mzzv1LycIohZtksVIi0L5S9lQMx6crqOfGdyKcB2U2M5WHeNBUT2VLgTVzjR9rxPa1RJZw-sZ6wqtnaZ7AA")
    @video.youtube_id = video_id # => aNdMiIAlK0g

    this_video = @yt_client.video_by(video_id)


    @video.duration = this_video.duration 





    respond_to do |format|
      if @video.update_attributes(params[:video])
        format.html { redirect_to @video, notice: 'Video was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /videos/1
  # DELETE /videos/1.json
  def destroy
    @video = Video.find(params[:id])
    @video.destroy

    respond_to do |format|
      format.html { redirect_to videos_url }
      format.json { head :no_content }
    end
  end


  def vote_up
    ##need to add ajax for this and to change the number next to the vote. 
    @video = Video.find(params[:id])
    begin
      current_user.vote_for(@video)
      #redirect_to root_path 
      render :partial => "votecount"
#      render :nothing => true, :status => 200
    rescue ActiveRecord::RecordInvalid
#      redirect_to root_path       
      render :nothing => true, :status => 404
    end
  end


  def comment
    ##need to add ajax for this and to change the number next to the vote. 
    @video = Video.find(params[:commentable][:commentable_id])

    @video.comments.create(:title => params[:comment][:title], :comment => params[:comment][:comment], :user_id => current_user.id)
    redirect_to @video

  end



  private
    def user_signed_in
      redirect_to beta_path if !user_signed_in?
    end


end

