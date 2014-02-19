#!/bin/bash
########################################################################
#
# README
#
########################################################################
#
# This is a basic blog generator
#
# Program execution starts at the end of this file, after the final
# function declaration. 
#
# todo: add more information here
# 
########################################################################
#
# LICENSE
#
########################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# location of config file
# values found in here overload defaults in this script
# expected format:
# key="value"
global_config="bashblog2.conf"
# log file defined outside of initializeGlobalVariables
# b/c logging starts before it would be defined!
global_logFile="bashblog2.log"
# these are needed in order to exit entire script
# even when inside a subshell. ex: $(parse ......)
PID=$$
trap "builtin exit" TERM

# run at beginning of script to generate globals
#
# takes no args
initializeGlobalVariables() {
    log "[Info] Loading default globals"
    
    global_softwareName="BashBlog2"
    #global_softwareVersion="1.0b"
    
    global_title="My blog" # blog title
    global_description="Blogger blogging on my blog" # blog subtitle
    global_url="http://example.com/blog" # top-level URL for accessing blog
    global_author="John Doe" # your name
    global_authorUrl="$global_url" # optional link to a a facebook profile, etc.
    global_email="johndoe@example.com" # your email
    global_license="CC by-nc-nd" # "&copy;" for copyright, for example
   
    global_sourceDir="source" # dir for easy-to-edit source             # best  
    global_draftsDir="drafts" # dir for drafts                          # to leave
    global_htmlDir="html" # dir for final html files                    # these
    global_tempDir="/tmp/$global_softwareName" # dir for pending files  # alone
   
    global_indexFile="index.html" # index page, best to leave alone
    global_archiveFile="archive.html" # page to list all posts, best to leave alone
    global_headerFile=".header.html" # header file 
    global_footerFile=".footer.html" # footer file 
    global_blogcssFile="blog.css" # blog's styling
       
    global_feed="feed.rss" # rss feed file
    global_feedLength="10" # num of articles to include in feed
    
    global_syncFunction="" # example: "cp -r ./$global_htmlDir /mnt/backup/blog/"
    
    global_backupFile="backup.tar.gz" # destination for backup
    
    niceDateFormat="%B %d, %Y" # for displaying, not timestamps
    markdownBinary="$(which Markdown.pl)"
}

# makes sure markdown is working correctly
# ex usage:
# [[ testMarkdown -ne 0 ]] && echo "bad markdown" && return 1
#
# takes no args
testMarkdown() {
    [[ -z "$markdownBinary" ]] && return 1
    [[ -z "$(which diff)" ]] && return 1

    local in="/tmp/md-in-$(echo $RANDOM).md"
    local out="/tmp/md-out-$(echo $RANDOM).html"
    local good="/tmp/md-good-$(echo $RANDOM).html"
    echo -e "line 1\n\nline 2" > $in
    echo -e "<p>line 1</p>\n\n<p>line 2</p>" > $good
    $markdownBinary $in > $out 2> /dev/null
    diff $good $out &> /dev/null # output is irrelevant, check $?
    if [[ $? -ne 0 ]]; then
        rm -f $in $good $out
        return 1
    fi
    rm -f $in $good $out
    return 0
}

# Detects if GNU date is installed
#
# takes no args
detectDateVersion() {
    date --version >/dev/null 2>&1
    if [[ $? -ne 0 ]];  then
        # date utility is BSD. Test if gdate is installed
        if gdate --version >/dev/null 2>&1 ; then
            date() {
                gdate "$@"
            }
        else
            # BSD date
            date() {
                if [[ "$1" == "-r" ]]; then
                    # Fall back to using stat for 'date -r'
                    local format=$(echo $3 | sed 's/\+//g')
                    local stat -f "%Sm" -t "$format" "$2"
                elif [[ $(echo $@ | grep '\-\-date') ]]; then
                    # convert between dates using BSD date syntax
                    /bin/date -j -f "%a, %d %b %Y %H:%M:%S %z" "$(echo $2 | sed 's/\-\-date\=//g')" "$1"
                else
                    # acceptable format for BSD date
                    /bin/date -j "$@"
                fi
            }
        fi
    fi
}

# echo usage info at the user
#
# takes no args
usage() {
    echo $global_softwareName v$global_softwareVersion
    echo "Usage: $0 command [filename]"
    echo ""
    echo "Commands:"
    echo "    edit [filename] .............. edit a file and republish if necessary"
    echo "    post [markdown] [filename] ... publish a blog entry"
    echo "                                   if markdown not specified, then assume html"
    echo "                                   if no filename, start from scratch"
    echo ""
    echo "For more information, see README and $0 in a text editor"
    log "[Info] Showing usage"
}

# fills a pending post with template
#
# $1    format, "md" or "html"
# $2    filename
fillPostTemplate() {
    log "[Info] Applying template to $2"
    local datetime=$(date +'%Y%m%d%H%M%S')
    if [[ $1 == "md" ]]; then local content="This is the body of your post. You may format with **markdown**.\n\nUse as many lines as you wish.";
    else local content="<p>This is the body of your post. You may format with <b>html</b></p>\n\n<p>Use as many lines as you wish.</p>"; fi
    echo "---------DO-NOT-EDIT-THIS-SECTION----------"  > $2
    echo $1                                            >> $2 # format 
    echo $datetime                                     >> $2 # original datetime
    echo $datetime                                     >> $2 # edit datetime
    echo "----------------POST-CONTENT---------------" >> $2
    echo "Title goes on this line"                     >> $2
    echo "----"                                        >> $2
    echo -e $content                                   >> $2
    echo "---------POST-TAGS---ONE-PER-LINE----------" >> $2
    echo ""                                            >> $2
}

# performs the sync function (if any)
# and logs about it
#
# takes no args
sync() {
    if [[ ! -z "$global_syncFunction" ]]; then
        log "[Info] Starting sync"
        $global_syncFunction
        log "[Info] End of sync"
    else
        log "[Info] No sync function"
    fi
    
}

# edit a file and start the process of republishing if needed
# got here with "./bashblog2.sh edit filename"
#
# $1    filename to edit
edit() {
    if [[ "$1" == *$global_sourceDir/* ]]; then
        # get format from within file
        log "[Info] Entering editor $EDTIOR"
        $EDITOR "$1"
        log "[Info] Exited editor $EDITOR"
        # set edit date in file
        # republish it
    elif [[ "$1" == *$global_draftDir/* ]]; then
        # get format from within file
        # set post and edit date in file
        # use post func to edit and possibly publish
    else
        # warn that this will edit an arbitrary file
            # and run sync func. Nothing more.
        log "[Info] Entering editor $EDTIOR"
        $EDITOR "$1"
        log "[Info] Exited editor $EDITOR"
    fi
    sync
}

# parse the given file into html
# and put it all into the given filename
#
# $1    file to parse
# $2    dir to put parsed .html file into
# returns $2/title-of-post.html
parse() {
    local format
    local postDate
    local editDate
    local title
    local content
    local tags
    local filename
    local onTags="false"
    local line
    while read line; do
        if [[ "$line" == "---------DO-NOT-EDIT-THIS-SECTION----------" ]]; then
            read line # format content is in, "md" or "html"
            if [[ -z "$format" ]]; then
                format="$line"
                if [[ $format != "md" ]] && [[ $format != "html" ]]; then
                    exit "[Error] Couldn't parse file: invalid format" "Couldn't parse file: invalid format"
                fi
            fi
            read line # posting date, should never change
            if [[ -z "$postDate" ]]; then
                postDate="$line"
                if [[ ! $postDate =~ ^[0-9]+$ ]]; then
                    exit "[Error] Couldn't parse file: invalid post date" "Couldn't parse file: invalid date"
                fi
            fi
            read line # edit date, changes when editing after publication
            if [[ -z "$editDate" ]]; then
                editDate="$line"
                if [[ ! $editDate =~ ^[0-9]+$ ]]; then
                    exit "[Error] Couldn't parse file: invalid edit date" "Couldn't parse file: invalid date"
                fi
            fi
        elif [[ "$line" == "----------------POST-CONTENT---------------" ]]; then
            read line # title, then also convert into filename
            title="$line" 
            # get filename based on title: all lower case, spaces to dashes, all alphanumeric
            filename="$2/$(echo $title | tr [:upper:] [:lower:] | sed 's/\ /-/g' | tr -dc '[:alnum:]-').html"
            read line # spacer between title and content
        elif [[ "$line" != "---------POST-TAGS---ONE-PER-LINE----------" ]] && [[ $onTags == "false" ]]; then
            # get everything before tag divider into the content variable
            [[ ! -z "$content" ]] && content="$content\n$line" || content="$line"
        else
            onTags="true"
            # get tags, except first thing will be the divider so continue first
            [[ "$line" == "---------POST-TAGS---ONE-PER-LINE----------" ]] && continue
            if [[ $line =~ ^.*\;.*$ ]]; then
                exit "[Error] Couldn't parse file: bad tags" "Coudln't parse file: tags can't have \";\" in them"
            else
                # append latest tag to list, dividing each with ";"
                [[ ! -z "$tags" ]] && tags="$tags;$line" || tags="$line"
            fi
        fi
    done < "$1"
    
    createHtmlPage $format $postDate $editDate "$title" "$content" "$tags" "$filename"
}

# takes parsed information 
# and turns into an html file 
# ready for publishing (or previewing)
#
# $1    format, "md" or "html"
# $2    date & time of original posting
# $3    date & time of latest edit
# $4    title of post
# $5    content of post
# $6    tags of post, if any
# $7    filename where everything goes
# returns $7
createHtmlPage() {
    local format=$1
    local postDate=$2; postDate="${postDate:0:8} ${postDate:8:2}:${postDate:10:2}:${postDate:12:2}"
    local editDate=$3; editDate="${editDate:0:8} ${editDate:8:2}:${editDate:10:2}:${editDate:12:2}"
    local title="$4"
    local content="$5"; [[ $format == "md" ]] && content=$(markdown "$content")
    local tagList="$6"
    local filename="$7"
    
    cat "$global_headerFile" > "$filename"
    echo "<title>$title</title>" >> "$filename"
    echo "</head><body>" >> "$filename"
    # body divs
    echo '<div id="divbodyholder">' >> "$filename"
    echo '<div class="headerholder"><div class="header">' >> "$filename"
    # blog title
    echo '<div id="title"><h1 class="nomargin"><a class="ablack" href="'$global_url'">'$global_title'</a></h1>' >> "$filename"
    echo '<div id="description">'$global_description'</div>' >> "$filename"
    # title, header, headerholder respectively
    echo '</div></div></div>' >> "$filename"
    echo '<div id="divbody"><div class="content">' >> "$filename"
    
    # not doing index, just one entry
    if [[ "$filename" != "$global_indexFile" ]]; then
        echo '<!-- entry begin -->' >> "$filename" # marks the beginning of the whole post
        echo '<h3><a class="ablack" href="'$global_url"$(echo $filename | sed "s/$global_htmlDir//")"'">' >> "$filename"
        # remove possible <p>'s on the title because of markdown conversion
        echo "$(echo "$title" | sed 's/<\/*p>//g')" >> "$filename"
        echo '</a></h3>' >> "$filename"
        echo '<div class="subtitle">'$(date +"$niceDateFormat" --date="$postDate") ' &mdash; ' >> "$filename"
        echo "$global_author</div>" >> "$filename"
        echo '<!-- text begin -->' >> "$filename" # This marks the beginning of the actual content
    fi
    echo -e "$content" >> "$filename" # body of post finally
    if [[ "$filename" != "$global_indexFile" ]]; then
        echo '<!-- text end -->' >> "$filename"
        echo '<!-- entry end -->' >> "$filename" # end of post
    fi
    echo '</div>' >> "$filename" # content
    cat "$global_footerFile" >> "$filename"
    echo '</body></html>' >> "$filename"
    
    echo $7
}

# publish a file
# got here with "./bashblog2.sh post [filename]"
#
# $1    format, "md" or "html"
# $2    filename, optional
post() {
    local format=$1
    local filename="$filename"
    # if no filename passed, posting a new file. Make a temp file
    if [[ -z "$filename" ]]; then
        filename="$global_tempDir/$RANDOM$RANDOM$RANDOM"
        fillPostTemplate $format $filename
    fi
    # do any editing if the blogger wants to
    local postResponse="e"
    while [[ $postResponse != "p" ]] && [[ $postResponse != "s" ]] && [[ $postResponse != "q" ]]
    do
        $EDITOR "$filename"
        # see if blogger wants to preview post
        local previewResponse="n"
        echo -n "Preview post? (y/N) "
        read previewResponse && echo
        previewResponse=$(echo $previewResponse | tr '[:upper:]' '[:lower:]')
        if [[ $previewResponse == "y" ]]; then
            # yes he does
            local parsedPreview="$(parse "$filename" "$global_htmlDir/preview")" # filename of where source is on disk
            local url=$global_url"$(echo $parsedPreview | sed "s/$global_htmlDir//")" # url of preview, assuming sync is set up
            log "[Info] Generating preview $parsedPreview"
            sync
            echo "See $parsedPreview"
            echo "or $url"
            echo "depending on your configuration"
        else
            # do nothing
            echo "" &> /dev/null
        fi
        
        echo -n "[P]ublish, [E]dit, [D]raft for later, [Q]uit? (p/E/d/q) "
        read postResponse && echo
        postResponse=$(echo $postResponse | tr '[:upper:]' '[:lower:]')
    done
    # don't know if blogger previewed, so just delete any preview
    [[ -f "$parsedPreview" ]] && rm "$parsedPreview" && log "[Info] Deleted $parsedPreview"
    if [[ $postResponse == "p" ]]; then
        # parse directly into htmldir
        local parsedPost="$(parse "$filename" "$global_htmlDir")"
        # move source from tempdir to sourcedir, renaming to nice name
        mv "$filename" "$global_sourceDir/"$(basename $parsedPost .html)".$format" 
        # echo/log afterwards because need title of post in echo/log
        echo "Publishing "$(basename $parsedPost)
        log "[Info] Publishing $parsedPost"
    elif [[ $postResponse == "s" ]]; then
        local parsedPost="$(parse "$filename" "$global_tempDir")"
        echo "Saving $global_draftDir"$(basename $parsedPost)".$format"
        log "[Info] Saving $global_draftDir"$(basename $parsedPost .html)".$format"
        mv "$filename" "$global_draftsDir/"$(basename $parsedPost .html)".$format"
    elif [[ $postResponse == "q" ]]; then
        log "[Info] Post process halted"
    fi
    sync
    
}

# backup desired files to compressed tarball
# best to leave $global_backupList alone
#
# takes no args
backup() {
    local backupList="$global_sourceDir $global_draftsDir $global_htmlDir $global_config"
    tar cfz $global_backupFile $backupList &> /dev/null
    [[ $? -ne 0 ]] && log "[Warning] Backup error"
    chmod 600 $global_backupFile
}

# takes markdown-formatted string and
# returns html-formatted string
#
# $1 markdown-formatted string
markdown() {
    log "[Info] Translating markdown"
    echo -e "$1" | $markdownBinary
}

# if the file does not already exist,
# creates style sheet from scratch
#
# takes no args
createCss() {
    # this is basically a line-for-line copy of the original bashblog's css
    # if you're comparing it to the original, this is the css for 
    # both the blog.css and main.css files. Some things may not be relevant anymore,
    # or may be ready to style things that haven't been implemented yet in bashblog2.
    #
    # This needs to be reviewed.
    if [[ ! -f "$global_htmlDir/$global_blogcssFile" ]]; then
    log "[Warning] blog.css file not found. Regenerating from scratch"
    echo 'body{font-family:Georgia,"Times New Roman",Times,serif;margin:0;padding:0;background-color:#F3F3F3;}
#divbodyholder{padding:5px;background-color:#DDD;width:874px;margin:24px auto;}
#divbody{width:776px;border:solid 1px #ccc;background-color:#fff;padding:0px 48px 24px 48px;top:0;}
.headerholder{background-color:#f9f9f9;border-top:solid 1px #ccc;border-left:solid 1px #ccc;border-right:solid 1px #ccc;}
.header{width:800px;margin:0px auto;padding-top:24px;padding-bottom:8px;}
.content{margin-bottom:45px;}
.nomargin{margin:0;}
.description{margin-top:10px;border-top:solid 1px #666;padding:10px 0;}
h3{font-size:20pt;width:100%;font-weight:bold;margin-top:32px;margin-bottom:0;}
.clear{clear:both;}
#footer{padding-top:10px;border-top:solid 1px #666;color:#333333;text-align:center;font-size:small;font-family:"Courier New","Courier",monospace;}
a{text-decoration:none;color:#003366 !important;}
a:visited{text-decoration:none;color:#336699 !important;}
blockquote{background-color:#f9f9f9;border-left:solid 4px #e9e9e9;margin-left:12px;padding:12px 12px 12px 24px;}
blockquote img{margin:12px 0px;}
blockquote iframe{margin:12px 0px;}
#title{font-size: x-large;}
a.ablack{color:black !important;}
li{margin-bottom:8px;}
ul,ol{margin-left:24px;margin-right:24px;}
#all_posts{margin-top:24px;text-align:center;}
.subtitle{font-size:small;margin:12px 0px;}
.content p{margin-left:24px;margin-right:24px;}
h1{margin-bottom:12px !important;}
#description{font-size:large;margin-bottom:12px;}
h3{margin-top:42px;margin-bottom:8px;}
h4{margin-left:24px;margin-right:24px;}
#twitter{line-height:20px;vertical-align:top;text-align:right;font-style:italic;color:#333;margin-top:24px;font-size:14px;}' > "$global_htmlDir/$global_blogcssFile"
    [[ ! -f "$global_htmlDir/preview/$global_blogcssFile" ]] && ln -s "../$global_blogcssFile" "$global_htmlDir/preview/$global_blogcssFile"
    fi
}

# if they do not already exist,
# creates header and footer from scratch
#
# takes no args
createHeaderFooter() {
    if [[ ! -f "$global_headerFile" ]]; then
    log "[Warning] header file not found. Regenerating from scratch"
        echo '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"><head>
<meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
<link rel="stylesheet" href="'$global_blogcssFile'" type="text/css" />' > "$global_headerFile"
    fi
    if [[ ! -f "$global_footerFile" ]]; then
    log "[Warning] footer file not found. Regenerating from scratch"
        local protected_mail="$(echo "$global_email" | sed 's/@/\&#64;/g' | sed 's/\./\&#46;/g')"
        echo '<div id="footer">'$global_license '<a href="'$global_author_url'">'$global_author'</a> &mdash; <a href="mailto:'$protected_mail'">'$protected_mail'</a><br/>
Generated with <a href="https://github.com/pointychimp/bashblog2">bashblog2</a>, based on <a href="https://github.com/cfenollosa/bashblog">bashblog</a></div>' > "$global_footerFile"
    fi
}

# prepare everything to get ready
# creates css file(s), makes directories,
# get global variables initialized, etc.
#
# takes no args
initialize() {
    log "[Info] Initializing"
    detectDateVersion
    initializeGlobalVariables
    [[ -f "$global_config" ]] && log "[Info] Overloading globals with $global_config" && source "$global_config" &> /dev/null
    mkdir -p "$global_sourceDir" "$global_draftsDir" "$global_htmlDir/preview" "$global_tempDir"
    createCss
    createHeaderFooter
}

# wrapper for logging to $global_logFile
#
# $1    stuff to put in log file
log() {
    echo -n "$(date +"[%Y-%m-%d %H:%M:%S]")" >> $global_logFile
    #echo -n "[$$]" >> $global_logFile
    echo "$1" >> $global_logFile
}

# overload of exit function
#
# $1    optional message to log
# $2    optional message to print (requires $1 to exist)
exit() {
    [[ ! -z "$1" ]] && log "$1"
    [[ ! -z "$2" ]] && echo "$2"
    log "[Info] Ending run"
    kill -s TERM $PID
}

########################################################################
# main (execution starts here)
########################################################################
log "[Info] Starting run"
initialize
# make sure $EDITOR is set
[[ -z $EDITOR ]] && exit "[Error] \$EDITOR not exported" "Set \$EDITOR enviroment variable"
# check for valid arguments
# chain them together like [[  ]] && [[  ]] && ... && usage && exit
[[ $1 != "edit" ]] && [[ $1 != "post" ]] && usage && exit

#
# edit option
#############
# $1    "edit"
# $2    filename
if [[ $1 == "edit" ]]; then
    if [[ $# -lt 2 ]]; then
        exit "[Error] No file passed" "Enter a valid file to edit"
    elif [[ ! -f "$2" ]]; then
        exit "[Error] File does not exist" "$2 does not exist"
    else
        backup
        edit "$2" # $2 is a filename
    fi
fi
#############

#
# post option
#############
# $1    "post"
# $2    "markdown" or filename
# $3    if $2=="markdown", $3==filename
if [[ $1 == "post" ]]; then
    format=""
    filename=""
    
    if [[ $2 == "markdown" ]]; then filename="$3";
    else filename="$2"; fi
    
    if [[ -z "$filename" ]]; then
        # no filename, generate new file
        if [[ $2 == "markdown" ]]; then format="md";
        else format="html"; fi
        backup
        log "[Info] Going to post a new $format file"
        post $format
    elif [[ -f "$filename" ]]; then
        # filename, and file exists, post it
        extension=$(echo "${filename##*.}" | tr '[:upper:]' '[:lower:]')
        if [[ $extension == "md" ]] && [[ ! $2 == "markdown" ]]; then
            log "[Warning] Assuming markdown file based on extension"
            format="md"
        elif [[ ! $extension == "md" ]] && [[ $2 == "markdown" ]]; then
            exit "[Error] $filename is not markdown" "$filename isn't markdown. If it is, change the extension."
        elif [[ $extension == "md" ]]; then format="md";
        elif [[ $extension == "html" ]]; then format="html";
        else
            log "[Warning] Unknown extension. Assuming file is html"
            format="html"
        fi
        backup
        log "[Info] Going to post $filename"
        post $format $filename
    elif [[ ! -f "$filename" ]]; then
        # filename, but file doesn't exist
        exit "[Error] $filename does not exist" "$filename does not exist"
    fi
fi
#############

exit
