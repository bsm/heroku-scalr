class Logger

  def reopen
    return unless @logdev && @logdev.filename

    @logdev.dev.reopen(@logdev.filename, "a")
    @logdev.dev.sync = true
    self
  end

end unless Logger.public_instance_methods.include?(:reopen)
