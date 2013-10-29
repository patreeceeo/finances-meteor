# Testing
As a stopgap measure while lacks suitable support for unit testing this is a 
basic jasmine installation that expects source files to be in src/. Since our
app is written in coffeescript we have to run

  coffee -o build/ -cw app/*.coffee

And

  coffee -o spec/ -cw spec

so that the compiled JS is where SpecRunner.html expects.

