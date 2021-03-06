{BufferedProcess} = require 'atom'

module.exports =
  class Runner
    commandString: null
    process: null
    useGitGrep: false
    columnArg: false

    constructor: ()->
      atom.config.observe 'atom-fuzzy-grep.grepCommandString', =>
        @commandString = atom.config.get 'atom-fuzzy-grep.grepCommandString'
        @columnArg = @detectColumnFlag()
      atom.config.observe 'atom-fuzzy-grep.detectGitProjectAndUseGitGrep', =>
        @useGitGrep = atom.config.get 'atom-fuzzy-grep.detectGitProjectAndUseGitGrep'

    run: (@search, @rootPath, callback)->
      if @useGitGrep and @isGitRepo()
        @commandString = 'git grep --no-color -n -e'
        @columnArg = false
      [command, args...] = @commandString.split(/\s/)
      args.push @search
      options = cwd: @rootPath

      stdout = (output)=>
        @parseOutput(output, callback)
      stderr = (error)->
        callback(error: error)
      exit = (exit)->
        callback([]) if exit
      @process = new BufferedProcess({command, exit, args, stdout, stderr, options})
      @process

    parseOutput: (output, callback)->
      items = []
      contentRegexp = if @columnArg then /^(\d+):\s*/ else /^\s+/
      for item in output.split(/\n/)
        break unless item.length
        [path, line, content...] = item.split(':')
        content = content.join ':'
        items.push
          filePath: path
          line: line-1
          column: @getColumn content
          content: content.replace(contentRegexp, '')
      callback items

    getColumn: (content)->
      if @columnArg
        return content.match(/^(\d+):/)?[1] - 1
      # escaped characters in regexp can cause error
      # skip it for a while
      try
        match = content.match(new RegExp(@search, 'gi'))?[0]
      catch error
        match = false
      if match then content.indexOf(match) else 0

    destroy: ->
      @process?.kill()

    isGitRepo: ->
      atom.project.repositories.some (item)=>
        @rootPath.startsWith(item.repo?.workingDirectory) if item

    detectColumnFlag: ->
      /(ag|ack)$/.test(@commandString.split(/\s/)[0]) and ~@commandString.indexOf('--column')
