= omnifocus-github

home :: https://github.com/seattlerb/omnifocus-github
rdoc :: http://seattlerb.rubyforge.org/omnifocus-github

== DESCRIPTION:

Plugin for omnifocus gem to provide github BTS synchronization.

Support for Github Enterprise:

In your git config, set the key omnifocus-github.accounts to a space
separated list of github accounts. 

    git config --global omnifocus-github.accounts "github myghe"

For each account API and web end points and authentication information 
should be stored in the git config under a key matching the
account. For example:

    git config --global github.user me
    git config --global github.password mypassword
    git config --global myghe.api https://ghe.mydomain.com/api/v3
    git config --global myghe.api https://ghe.mydomain.com/

For each account can you specify the following parameters:

* api - specify an API endpoint other than
  https://api.github.com. This is so you can point this at your Github
  Enterprise endpoint.

* web - specify an API endpoint other than https://www.github.com. This
  is so you can point this at your Github Enterprise endpoint

* user, password - A username and password pair for Basic http authentication.

== FEATURES/PROBLEMS:

* Provides github BTS synchronization.

== REQUIREMENTS:

* omnifocus
* octokit
* ~/.gitrc must have github username defined

== INSTALL:

* sudo gem install omnifocus-github

== LICENSE:

(The MIT License)

Copyright (c) Ryan Davis, seattle.rb

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
