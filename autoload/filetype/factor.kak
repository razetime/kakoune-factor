hook global BufCreate .*\.factor(-rc|-boot-rc)? %{
    set-option buffer filetype factor
    # set-option buffer matching_pairs ( ) { } [ ]
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# declare-option str k_exec "~/k/k" 
hook global WinSetOption filetype=factor %¹
    require-module factor

    hook window InsertChar \n -group factor-indent factor-indent-on-new-line
    hook window InsertChar [})\]] -group factor-indent factor-indent-on-closing

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window factor-.+ }
¹

hook -group factor-highlight global WinSetOption filetype=factor %{
    add-highlighter window/factor ref factor
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/factor }
}

provide-module factor %¹

# Highlighters & Completion
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
add-highlighter shared/factor regions
add-highlighter shared/factor/code default-region group
#Comments
add-highlighter shared/factor/code/ regex "^#!(?S).*$" 0:comment
add-highlighter shared/factor/mcomment region "/\*\s" "\*/" fill comment
add-highlighter shared/factor/code/scomment regex "(^| )!(((TODO|FIXME|XXX):)|[^\n])*$" 0:comment 3:keyword

# init
add-highlighter shared/factor/code/ regex "(STARTUP-HOOK|SHUTDOWN-HOOK):" 0:attribute

# help
add-highlighter shared/factor/code/ regex "\bHELP:\s(\s*![^\n]*?\n)*\s*\S+" 0:module 1:comment
add-highlighter shared/factor/code/ regex "(ARTICLE|ABOUT):" 0:module

# defns
add-highlighter shared/factor/defn region "(^|\s)(SYNTAX|CONSTRUCTOR|(M|MACRO|MEMO|TYPED)?:?):" "\s;" group
add-highlighter shared/factor/defn/ fill magenta
add-highlighter shared/factor/defn/ ref factor/code/scomment

# private
add-highlighter shared/factor/private region "<PRIVATE\s" "(^|\s)PRIVATE>" group
add-highlighter shared/factor/private/ ref factor/defn
add-highlighter shared/factor/private/ ref factor/comment
add-highlighter shared/factor/private/ regex "(<PRIVATE|PRIVATE>)" 0:red

add-highlighter shared/factor/code/ regex "\s(t|f|B|@|_)\b" 0:bright-red

add-highlighter shared/factor/code/ regex ":>" 0:operator

# char, string, regex
add-highlighter shared/factor/code/escape regex "\\(\\|[abefnrtsv0""]|x[a-fA-F0-9]{2}|u[a-fA-F0-9]{6}|u\{[^}]+\}|[0-9a-fA-F]{2}|[0-7]{1,3})" 0:keyword
add-highlighter shared/factor/chcolor region "(CHAR|COLOR):\s+" "\S+" group
add-highlighter shared/factor/chcolor/ fill string
add-highlighter shared/factor/chcolor/ ref factor/code/escape
add-highlighter shared/factor/nstr region "STRING: \S+\n" "^;$" group
add-highlighter shared/factor/nstr/ fill string
add-highlighter shared/factor/nstr/ ref factor/code/escape
add-highlighter shared/factor/str region '\\?\K[A-Z]*"' '\n[^ ]|(?<!\\)(?:\\\\)*"' group
add-highlighter shared/factor/str/ fill string
add-highlighter shared/factor/str/ ref factor/code/escape
add-highlighter shared/factor/mstr region '\S*\[={0,6}\[' '\]={0,6}\]' group
add-highlighter shared/factor/mstr/ fill string
add-highlighter shared/factor/mstr/ ref factor/code/escape
add-highlighter shared/factor/regex region 'R/' '(?<!\\)(?:\\\\)*/[a-z]+' group
add-highlighter shared/factor/regex/ fill string

add-highlighter shared/factor/using region "\bUSING:\s" "\s;" group
add-highlighter shared/factor/using/ fill module
add-highlighter shared/factor/using/ ref factor/code/scomment
add-highlighter shared/factor/code/ regex "\bUSE:\s(\s*![^\n]*?\n)*\s*\S+" 0:module 1:comment
add-highlighter shared/factor/code/ regex "\bUNUSE:\s(\s*![^\n]*?\n)*\s*\S+" 0:module 1:comment
add-highlighter shared/factor/code/ regex "\bIN:\s(\s*![^\n]*?\n)*\s*\S+" 0:module 1:comment
add-highlighter shared/factor/from region "\bFROM:\s+\S+\s+=>" ";" group
add-highlighter shared/factor/from/ fill module
add-highlighter shared/factor/from/ ref factor/code/scomment

#add-highlighter shared/factor/string region '\\?\K"' '\n[^ ]|(?<!\\)(?:\\\\)*"' group
#add-highlighter shared/factor/string/ fill string
#add-highlighter shared/factor/string/ regex "\\." 0:keyword

# add-highlighter shared/factor/code/ regex ";" 0:white
# add-highlighter shared/factor/code/ regex "[ \t]+$" 0:white,red
# add-highlighter shared/factor/code/ regex "[{}]" 0:white
# add-highlighter shared/factor/code/ regex "[\[\]\(\)]" 0:bright-black
# add-highlighter shared/factor/code/ regex '[+\-*%!&|<>=~,^#_$?@.:]:?' 0:keyword
# add-highlighter shared/factor/code/ regex "[\\/']:?" 0:green
# add-highlighter shared/factor/code/ regex "-?\d+([ijl]|[NW][ijl]?|[nw]|(\.\d+)?(e-?\d+)?)?" 0:value
# add-highlighter shared/factor/code/ regex "-?(0[NnWw])" 0:value
# add-highlighter shared/factor/code/ regex '[0-5]:' 0:keyword
# add-highlighter shared/factor/code/ regex "\b-" 0:keyword
# add-highlighter shared/factor/code/ regex "\b0x([\dA-Fa-f]{2})*" 0:string
# add-highlighter shared/factor/code/ regex "[01]+b" 0:value
# add-highlighter shared/factor/code/ regex "\b[A-Za-z][A-Za-z0-9\.]*" 0:yellow
# add-highlighter shared/factor/code/ regex "`([A-Za-z][A-Za-z0-9]*|\b0x([\dA-Fa-f]{2})*)" 0:bright-magenta

declare-user-mode factor
define-command -hidden factor-indent-on-new-line %`
    evaluate-commands -draft -itersel %_
        # preserve previous line indent
        try %{ execute-keys -draft <semicolon> K <a-&> }
        # copy # comments prefix
        try %{ execute-keys -draft <semicolon><c-s>k<a-x> s ^\h*\K/+\h* <ret> y<c-o>P<esc> }
        # indent after lines ending with { ⟨ [
        try %( execute-keys -draft k<a-x> <a-k> [{⟨\[]\h*$ <ret> j<a-gt> )
        # cleanup trailing white spaces on the previous line
        try %{ execute-keys -draft k<a-x> s \h+$ <ret>d }
     _
`

¹
