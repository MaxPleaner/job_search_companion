module App::PID

  PIDS = Set.new

  def add_pid(pid)
    pids.add(pid)
  end

  def remove_pid(pid)
    pids.delete(pid)
  end

  def pid_closed?(pid)
    !pids.include?(pid)
  end

  def in_new_thread &blk
    Thread.new do
      pid = Thread.current.object_id
      add_pid(pid)
      blk.call(pid)
    end
  end

  private

  def pids
    App::PID::PIDS
  end

end