# Testing
As a stopgap measure until I find a better way to unit test w/ Meteor I'm using a basic jasmine installation with a SpecRunner.html Since our app is written in coffeescript we have to run

    coffee -o spec/ -cw spec/

While running Meteor so that the compiled JS is where SpecRunner.html expects.

