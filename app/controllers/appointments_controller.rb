class AppointmentsController < ApplicationController

  require 'securerandom'

  before_action :authenticate_user!

  def convertStart date
  somedate = DateTime.new(date["start(1i)"].to_i,
                          date["start(2i)"].to_i,
                          date["start(3i)"].to_i,
                          date["start(4i)"].to_i,
                          date["start(5i)"].to_i)
  end

  def convertEnd date
  somedate = DateTime.new(date["end(1i)"].to_i,
                          date["end(2i)"].to_i,
                          date["end(3i)"].to_i,
                          date["end(4i)"].to_i,
                          date["end(5i)"].to_i)
  end

  def pdf
    @cal = Array.new
    Itinerary.get_all_by_user_id( current_user.id ).each { |i|
      @cal.push i
    }
    p @cal.inspect
    respond_to do |format|
      format.html
      format.pdf do
        render :pdf => 'file_name',
        :template => 'appointments/show.pdf.erb',
        :layout => '_pdf.html.erb',
        :show_as_html => params[:debug].present?
      end
    end
  end

  def view
    @cal_data = Array.new

    Itinerary.get_all_by_user_id( current_user.id ).each { |i|
      @cal_data.push i.to_bootstrap_calendar_hash
    }
    p @cal_data.inspect
  end

  def new
    @care_providers = CareProvider.pluck(:office_name) 
  end

  def create
    @care_provider_id = CareProvider.where(:office_name => params[:appointment][:office_name]).first.id
    @appointment = Itinerary.create!(:description => params[:appointment][:description], 
                  :start => self.convertStart(params[:appointment]), 
                  :care_provider_id => @care_provider_id,
                  :end => self.convertEnd(params[:appointment]),
                  :user_id => current_user.id,
                  :itinerary_status_id => 1)

    flash[:info] = "#{@appointment.description} was successfully created."
    redirect_to appointments_view_path
  end

  def edit
    id = params[:id] 
    @appointment = Itinerary.find(id)
    @care_providers = CareProvider.pluck(:office_name) 
  end

  def update
    @appointment = Itinerary.find params[:id]
    #turn the care provider office name into care provider id to update the appointment
    @care_provider_id = CareProvider.where(:office_name => params[:appointment][:care_provider_id]).first.id
    @appointment.update(:description => params[:appointment][:description])
    @appointment.update(:start => self.convertStart(params[:appointment]))
    @appointment.update(:end => self.convertEnd(params[:appointment]))
    @appointment.update(:care_provider_id => @care_provider_id)
    flash[:info] = "#{@appointment.description} was successfully updated."
    redirect_to appointment_path(@appointment)
  end

  def destroy
    id = params[:id] 
    @appointment = Itinerary.find(id)
    Itinerary.find(id).destroy
    flash[:info] = "#{@appointment.description} was successfully deleted."
    redirect_to appointments_view_path
  end

  def show
    id = params[:id] 
    @appointment = Itinerary.find(id)
    @careProvider = CareProvider.find(@appointment.care_provider_id)
    @status = ItineraryStatus.find(@appointment.itinerary_status_id)
    @comments = Comment.where(:itinerary_id => @appointment.id)
  end

  def comment

    itinerary_id = params[:itinerary_id]
    comment = params[:comment]

    @itinerary = Itinerary.find(itinerary_id)
    @care_provider = CareProvider.find(@itinerary.care_provider_id)

    random_string = SecureRandom.hex
    link = email_providerresponse_url :key => random_string.to_s

    # create record of email being sent
    EmailLink.create(
        :auth_token => random_string.to_s,
        :to_email => @care_provider.office_email,
        :to_name => @care_provider.office_name,
        :user_id => current_user.id,
        :itinerary_id => @itinerary.id
    )

    UserMailer.comment_for_provider(current_user, @care_provider, link).deliver_now

    Comment.create(
        :poster_email => current_user.email,
        :poster_name => current_user.name_first,
        :comment => comment,
        :itinerary_id => @itinerary.id
    )

    flash[:info] = "Your comment has been posted and " + @care_provider.office_name + " has been notified"
    redirect_to appointments_view_path
  end
end
