The [Bitbucket repo](https://bitbucket.org/pointychimp/bashblog) will be kept more up-to-date
=================================================
=================================================
=================================================
=================================================
=================================================
=================================================
=================================================
=================================================




BashBlog
========

My adaptation of [cfenollosa's bashblog](https://github.com/cfenollosa/bashblog).

Bashblog is a bash script that provides an easy way to generate and maintain a blog. It is easy to interact with and allows for customization. It does not depend on anything special. Everything needed is stored in a single script or is generated externally into files for optional customization.

[My blog](http://blog.mineoas.us) is generated with bashblog. [The initial blog post](http://mineoas.us/blog/bashblogquick-and-dirty-blog-generator.html) may have even more useful information in it than this readme, though the readme will be kept up-to-date.

Changelog
---------

* 1.0.1   [bdeb99e](https://bitbucket.org/pointychimp/bashblog/commits/bdeb99e90e3ff628c44549d03ea3ec76b682a23b) Fixed missing div close
* 1.0     [c511bc3](https://bitbucket.org/pointychimp/bashblog/commits/c511bc35c09d1fdb4288b909110d4ef2f5c0eb47) Added reset function
* 3.2b    [6671c8e](https://bitbucket.org/pointychimp/bashblog/commits/6671c8ef55166dd41ccbc960cc023368f2960d2f) Fixed markdown parsing issue
* 3.1b    [39fa613](https://bitbucket.org/pointychimp/bashblog/commits/39fa61393272284a4c839de04396b28b5d0ec11a) Fixed draft related issues
* 3.0b    [afaefa1](https://bitbucket.org/pointychimp/bashblog/commits/afaefa1921564766ed8bc2f3f15f199f932570a3) Added rebuild function
* 2.0b    [5ddec04](https://bitbucket.org/pointychimp/bashblog/commits/5ddec0441d2d4891e483e5d5a8f4daa6c090af64) Generates feed file.
* 1.0b    [29c65bf](https://bitbucket.org/pointychimp/bashblog/commits/29c65bfeb957881d594cd76b0c484cf49565a8bc) First "usable" release. Able to make/edit posts. Generates index and archive files.


Features
--------

* No external dependencies.
* Very simple to use. Use what ever text editor you want.
* Generates plain html files. No need for PHP or any server-side scripting
* (future) support for rss feeds, comments, google analytics
* Markdown support, ([get Markdown.pl here](http://daringfireball.net/projects/markdown/))
* Optionally run any command after making changes in order to sync to a different place. For example, you could be working in `~/Documents/bashblog` but want to copy posts to `/var/www/blog`. In that case, you could use `cp "$global_htmlDir" "/var/www/blog"`. To see more global variables ripe for customization and use, see the beginning of the script.

Configuration
-------------

You should create a config file and give at least some of the global variables personalized values. I would hesitate before changing the default directories, but you should definitely change the title, your name, email, etc.

The default name for the config file is `bashblog.conf`. The variables should be overloaded in the following format

    global_variable="value"

Remember to not prefix the variables with a `$`, to put the values in quotes, and to not put spaces around the equal signs.

Usage
-----

First make sure script is executable.

    chmod u+x ./bashblog.sh

Then you can call it simply by typing

    ./bashblog.sh

To start a new post, call one of the following

    ./bashblog.sh post
    ./bashblog.sh post markdown

depending on how you want to edit the post. After you've closed the text editor, you can preview your post if you would like. Then it can be published, saved as a draft, or discarded entirely.

`./bashblog.sh edit source/title-of-post.md` to edit a already published post
`./bashblog.sh post drafts/title-of-post.html` to start the post process again on a draft

Todo
----

* comments
* other functions .... none come to mind
* tag page listing all tags ordered by popular use
* page to view only posts with a specific tag




