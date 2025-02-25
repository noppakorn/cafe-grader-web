class DatasetsController < ApplicationController
  before_action :set_dataset, only: %i[ show edit update destroy
                                        manager_delete manager_view
                                        checker_view checker_download checker_delete
                                        testcase_input testcase_sol testcase_delete
                                        view set_as_live rejudge
                                      ]
  before_action :admin_authorization
  before_action :check_valid_login

  # GET /datasets/new
  def new
    @dataset = Dataset.new
  end

  # GET /datasets/1/edit
  def edit
  end

  # POST /datasets or /datasets.json
  def create
    @dataset = Dataset.new(dataset_params)

    respond_to do |format|
      if @dataset.save
        format.html { redirect_to dataset_url(@dataset), notice: "Dataset was successfully created." }
        format.json { render :show, status: :created, location: @dataset }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /datasets/1 or /datasets/1.json
  def update
    respond_to do |format|
      if params[:dataset][:managers]
        @dataset.managers.attach params[:dataset][:managers]
      end
      if params[:dataset][:checker]
        # since checker is downloaded and cached by WorkerDataset, we have to invalidate it
        # when it is updated
        WorkerDataset.where(dataset_id: @dataset).delete_all
      end
      if @dataset.update(dataset_params)
        @updated = "Updated successfully on #{Time.zone.now}"
        #format.html { redirect_to dataset_url(@dataset), notice: "Dataset was successfully updated." }
        format.json { render :show, status: :ok, location: @dataset }
        format.turbo_stream
      else
        #format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
        format.turbo_stream
      end
    end
  end

  def manager_delete
    mg = @dataset.managers.find(params[:mg_id])
    @updated = "#{mg.filename} is deleted"
    mg.purge
  end

  def manager_view
    mg = @dataset.managers.find(params[:mg_id])
    render partial: 'shared/msg_modal_show', locals: {do_popup: true, header_msg: mg.filename, body_msg: mg.download}
  end

  def checker_view
    c = @dataset.checker
    render partial: 'shared/msg_modal_show', locals: {do_popup: true, header_msg: c.filename, body_msg: c.download}
  end

  def checker_download
    type = @dataset.checker.content_type
    filename = @dataset.checker.filename.to_s
    send_data @dataset.checker.download, disposition: 'inline', type: type, filename: filename
  end

  def checker_delete
    @dataset.checker.purge
    @updated = "Checker is deleted"
    render 'manager_delete'
  end

  # as turbo
  def testcase_input
    tc = Testcase.find(params[:tc_id])
    render partial: 'shared/msg_modal_show', locals: {do_popup: true, header_msg: 'input', body_msg: tc.inp_file.download }

  end

  # as turbo
  def testcase_sol
    tc = Testcase.find(params[:tc_id])
    render partial: 'shared/msg_modal_show', locals: {do_popup: true, header_msg: 'answer', body_msg: tc.ans_file.download }
  end

  # as turbo
  def testcase_delete
    tc = Testcase.find(params[:tc_id])
    tc.destroy
    @updated = "Testcase ##{tc.num} is deleted"
    render :update
  end

  def view
    @dataset = Dataset.find(params[:null][:dsid])
    render :update
  end

  def set_as_live
    @updated = "Dataset #{@dataset.name} is live"
    @dataset.problem.update(live_dataset: @dataset)
    render :update
  end

  def rejudge
    @dataset.problem.submissions.each do |sub|
      #mass rejudge, priority is very low
      sub.add_judge_job(@dataset,-100)
    end

  end

  # DELETE /datasets/1 or /datasets/1.json
  def destroy
    p = @dataset.problem
    @dataset.destroy
    @dataset = p.datasets.first

    respond_to do |format|
      format.html { redirect_to datasets_url, notice: "Dataset was successfully destroyed." }
      format.json { head :no_content }
      format.turbo_stream { render :update}
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dataset
      @dataset = Dataset.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def dataset_params
      params.fetch(:dataset, {})
      params.require(:dataset).permit(:name, :time_limit, :memory_limit, :score_type, :evaluation_type, :main_filename, :checker)
    end

end
