browsermob-proxy-rb
===================

Ruby client for the BrowserMob Proxy 2.0 REST API.

[![Build Status](https://secure.travis-ci.org/jarib/browsermob-proxy-rb.png)](http://travis-ci.org/jarib/browsermob-proxy-rb)


How to use with selenium-webdriver
----------------------------------

Manually:

``` ruby
require 'selenium/webdriver'
require 'browsermob/proxy'

server = BrowserMob::Proxy::Server.new("/path/to/downloads/browsermob-proxy/bin/browsermob-proxy") #=> #<BrowserMob::Proxy::Server:0x000001022c6ea8 ...>
server.start

proxy = server.create_proxy #=> #<BrowserMob::Proxy::Client:0x0000010224bdc0 ...>

profile = Selenium::WebDriver::Firefox::Profile.new #=> #<Selenium::WebDriver::Firefox::Profile:0x000001022bf748 ...>
profile.proxy = proxy.selenium_proxy

driver = Selenium::WebDriver.for :firefox, :profile => profile

proxy.new_har "google"
driver.get "http://google.com"

har = proxy.har #=> #<HAR::Archive:0x-27066c42d7e75fa6>
har.entries.first.request.url #=> "http://google.com"
har.save_to "/tmp/google.har"

proxy.close
driver.quit
```

With event listener:

```ruby
require 'selenium/webdriver'
require 'browsermob/proxy'
require 'browsermob/proxy/webdriver_listener'

# start server, set up proxy like above
proxy_listener = BrowserMob::Proxy::WebDriverListener.new(proxy)

driver = Selenium::WebDriver.for :firefox, :profile => profile, :listener => proxy_listener
# use driver
driver.quit

proxy_listener.hars #=> [#<HAR::Archive:0x-27066c42d7e75fa6>, #<HAR::Archive:0x-d7e75fa627066c42>]
proxy.close

```

Viewing HARs
------------

The HAR gem includes a HAR viewer. After running the code above, you can view the saved HAR by running

    $ har /tmp/google.har

See also
--------

* http://bmp.lightbody.net/
* https://github.com/lightbody/browsermob-proxy

Note on Patches/Pull Requests
-----------------------------

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Copyright
---------

Copyright 2011-2014 Jari Bakken

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

