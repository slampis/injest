#!/bin/bash

rm injest-client-0.1.2.gem
gem uninstall injest-client
gem build
gem install injest-client-0.1.2.gem

ruby test_gem.rb

gem uninstall injest-client