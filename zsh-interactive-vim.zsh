#!/usr/bin/env zsh

__ziv_matched_subdir_list() {
  local dir length seg starts_with_dir 
  if [[ "$1" == */ ]]; then # arg ends with /
    dir="$1"
    [[ "$dir" != / ]] && dir="${dir%?}" # remove trailing / (unless root dir)
    length=$(echo -n "$dir" | wc -c) # dir length stored in length (-n for no newline)
    [[ "$dir" == / ]] && length=0 # account for root edge case
    find -L "$dir" -maxdepth 1  2>/dev/null | cut -b $(( $length + 2 ))- | sed '/^$/d' | while read -r line; do #find subdirs/files at depth one, cut initial "./", delete empty paths and iterate over them
      [[ "${line[1]}" == "." ]] && continue # ignore paths starting with "."
      echo $line
    done
  else
    dir=$(dirname -- "$1") # parent dir (a/b/c ->  b; a/b/ -> a)
    length=$(echo -n "$dir" | wc -c) # dir length stored in length
    [[ "$dir" == / ]] && length=0 # if parent dir is root dirname outputs / 
    seg=$(basename -- "$1") # name of the file/dir at the end (might be incomplete)
    [[ "$seg" == "." && $(find -L . -maxdepth 1 2>/dev/null | grep "^\./\." | wc -l) -eq 0 ]] && seg="" # search for dirs in . (not starting with .) in case there aren't hidden dirs
    matching_dirs=$(find -L "$dir" -maxdepth 1 2>/dev/null | cut -b $(( $length + 2 ))- | sed '/^$/d' | while read -r line; do
      [[ "${seg[1]}" != "." && "${line[1]}" == "." ]] && continue # ignore dirs starting with.   
      if [ "$ziv_case_insensitive" = "true" ]; then
        [[ "$line:u" == "$seg:u"* ]] && echo "$line"
      else
        [[ "$line" == "$seg"* ]] && echo "$line" 
      fi
      
    done) # directories starting with seg directly in current dir
    [ -n "$matching_dirs" ] && echo "$matching_dirs"
  fi
}

__ziv_fzf_bindings() {
  autoload is-at-least

  if $(is-at-least '0.21.0' $(fzf --version)); then
    echo 'shift-tab:up,tab:down,bspace:backward-delete-char/eof' # enable backspace to go out of fzf
  else
    echo 'shift-tab:up,tab:down'
  fi
}

__ziv_empty_arg() {
  if [[ $LBUFFER =~ .*\ $ ]]; then
    echo "1"
  else
    echo "0"
  fi
}

__ziv_current_arg() {
  if [[ $(__ziv_empty_arg) -eq 1 ]]; then
    echo ""
  else
    echo '${(Q)@[-1]}'
  fi
}

_ziv_list_generator() {
  
  __ziv_matched_subdir_list $(eval echo $(__ziv_current_arg)) | sort #call __ziv_matched_subdir_list on the last [-1] arg unqouted (--flags "path to/dir" -> path to/dir )
}

_ziv_preview() {
  local _base base current dir
  _base=(${(z)1})
  base=${_base[-1]}
  [[ $(__ziv_empty_arg) -eq 1 ]] && base="." # fix empty arg
  [[ "$base" != */ ]] && base=$(dirname -- $base) # remove partial dir/filename
  [[ "$base" == */ ]] && base="${base%?}" # remove trailing /
  current=$2
  dir="$base/$2"
  export CLICOLOR_FORCE=1 # force colors
  if [ -d "$dir" ]; then
    ls $dir 
  else
    bat --color=always $dir
  fi
}

_ziv_complete() { # perform completion
  setopt localoptions nonomatch
  local l matches fzf tokens base
  l=$(_ziv_list_generator $@)
  if [ -z $l ]; then
    zle ${__ziv_default_completion:-expand-or-complete}
    return
  fi

  fzf_bindings=$(__ziv_fzf_bindings)

  if [ $(echo $l | wc -l) -eq 1 ]; then
    matches=${(q)l} # match the only element in the list (special chars accounted for (q))
  else
    matches=$(echo $l | __ziv_preview=$(declare -f _ziv_preview) _base=$* ___ziv_empty_arg=$(declare -f __ziv_empty_arg) LBUFFER=$LBUFFER FZF_DEFAULT_OPTS="--height 40% --bind '$fzf_bindings' --reverse" fzf --preview 'eval $__ziv_preview;eval $___ziv_empty_arg; _ziv_preview "$_base" {}' | while read -r item; do
      echo -n "${(q)item} "
    done)
  fi

  matches=${matches% } # remove trailing whitespace
  if [ -n "$matches" ]; then
    tokens=(${(z)LBUFFER})
    base="$(eval echo $(__ziv_current_arg))" # path, unquoted
    if [[ "$base" != */ ]]; then # if path not /-finished
      if [[ "$base" == */* ]]; then # path contains /
        base="$(dirname -- "$base")"
        [[ ${base[-1]} != / ]] && base="$base/"
      else
        base="" # relative to current, don't include /
      fi
    fi
    LBUFFER="${tokens[1,$(( ${#tokens} - 1 + $(__ziv_empty_arg) ))]} " # LBUFFER are characters to the left of the cursor in ZSH - initially set to cmd (*vim) + arg + args
    if [ -n "$base" ]; then
      base=${(q)base}
      LBUFFER="$LBUFFER${base}" # append formatted base (special chars)
    fi 
    LBUFFER="$LBUFFER$matches" # append selected dir/file
    [ -d "${base}$matches" ] && LBUFFER="$LBUFFER/" # append trailing / if dir
  fi

  zle redisplay
  declare -f zle-line-init > /dev/null && zle zle-line-init # check if zle-line-init widget is defined, zle-line-init if so 
}

ziv-completion() { # zle widget, match "*vim " and execute _ziv_complete, fallback to default completion otherwise
  setopt localoptions noshwordsplit noksh_arrays noposixbuiltins
  local tokens cmd
  tokens=(${(z)LBUFFER}) # parens exclude whitespaces from the array 
  cmd=${tokens[1]}
  if [[ "$LBUFFER" =~ "^\ *.?vim$" ]]; then # match vim and nvim when cursor is right after them, matching any amount of spaces before
    zle ${__ziv_default_completion:-expand-or-complete}
  elif [[ "$cmd" =~ ".?vim" ]]; then
    _ziv_complete ${tokens[2,${#tokens}]/#\~/$HOME} # perform actual completion (send array of args replacing ~ with $HOME) 
  else 
    zle ${__ziv_default_completion:-expand-or-complete}
  fi
}

zle -N ziv-completion # register as a macro
ziv_currently_bound=$(bindkey ${ziv_custom_keybind:-'^I'} | awk '{print $2}')
[[ "$ziv_currently_bound" != "ziv-completion" ]] && __ziv_default_completion=$ziv_currently_bound # set fallback to what was bound to the keybinding beforehand (ensure compatibility with plugins like zsh-interactive-cd as long as this is enabled afterwards) (check to prevent infinite recursion)
[ -z $ziv_custom_binding ] && ziv_custom_binding='^I' # default to ^I/TAB for completion 
bindkey $ziv_custom_binding ziv-completion # bind macro
