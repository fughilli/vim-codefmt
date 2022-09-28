" Copyright 2017 Google Inc. All rights reserved.
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"     http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.


let s:plugin = maktaba#plugin#Get('codefmt')


""
" @private
"
" Formatter provider for textproto files using txtpbfmt.
function! codefmt#txtpbfmt#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'txtpbfmt',
      \ 'setup_instructions': 'Install txtpbfmt. ' .
          \ '(https://github.com/protocolbuffers/txtpbfmt).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('txtpbfmt_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'textproto'
  endfunction

  ""
  " Reformat the current buffer with txtpbfmt or the binary named in
  " @flag(txtpbfmt)
  " @throws ShellError
  function l:formatter.Format() abort
    let l:cmd = [ s:plugin.Flag('txtpbfmt_executable') ]
    let l:fname = expand('%:p')

    try
      " NOTE: Ignores any line ranges given and formats entire buffer.
      " txtpbfmt does not support range formatting.
      call codefmt#formatterhelpers#Format(l:cmd)
    catch
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for line in split(v:exception, "\n")
        if empty(l:fname)
          let l:fname_pattern = 'stdin'
        else
          let l:fname_pattern = escape(l:fname, '\')
        endif
        let l:tokens = matchlist(line,
            \ '\C\v^\V'. l:fname_pattern . '\v:(\d+):(\d+):\s*(.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ "filename": @%,
              \ "lnum": l:tokens[1],
              \ "col": l:tokens[2],
              \ "text": l:tokens[3]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse txtpbfmt error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction
