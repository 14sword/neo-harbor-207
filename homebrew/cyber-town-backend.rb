class CyberTownBackend < Formula
  desc "FastAPI Backend for Cyber Town RPG"
  homepage "https://github.com/14sword/neo-harbor-207"
  url "https://github.com/14sword/neo-harbor-207/archive/refs/heads/main.tar.gz"
  version "1.0.0"

  depends_on "python@3.10"

  def install
    # Copy backend folder contents to execution prefix directory
    libexec.install Dir["backend/*"]
  end

  # Register backend as a system service
  service do
    run ["python3", "-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", "8000", "--working-dir", opt_libexec]
    keep_alive true
    log_path var/"log/cyber-town-backend.log"
    error_log_path var/"log/cyber-town-backend-err.log"
  end
end
