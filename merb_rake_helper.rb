def sudo
  windows = (PLATFORM =~ /win32|cygwin/) rescue nil
  ENV['MERB_SUDO'] ||= "sudo"
  sudo = windows ? "" : ENV['MERB_SUDO']
end

def gemx
  win32 = (PLATFORM =~ /win32/) rescue nil
  win32 ? 'gem.bat' : 'gem'
end

def rakex
  win32 = (PLATFORM =~ /win32/) rescue nil
  win32 ? 'rake.bat' : 'rake'
end
