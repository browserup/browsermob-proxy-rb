require 'spec_helper'

describe "Server" do
  it 'should not stop itself at exit if :stop_at_exit is false' do
    server_pid = run_in_isolation do
      server = BrowserMob::Proxy::Server.new(
          File.join(home, "bin", "browsermob-proxy"),
          port: Selenium::WebDriver::PortProber.above(3000),
          log: true,
          stop_at_exit: false
        ).start
      server.process.pid
    end

    expect(process_alive?(server_pid)).to eq(true)
    Process.kill 'TERM', server_pid
  end

  it 'should stop itself at exit if :stop_at_exit is not set (true by default)' do
    server_pid = run_in_isolation do
      server = BrowserMob::Proxy::Server.new(
          File.join(home, "bin", "browsermob-proxy"),
          port: Selenium::WebDriver::PortProber.above(3000),
          log: true
        ).start
      server.process.pid
    end

    expect(process_alive?(server_pid)).to eq(false)
  end
end
