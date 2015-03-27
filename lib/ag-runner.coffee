{BufferedProcess} = require 'atom'

module.exports =
  class AgRunner
    process: null
    args: null
    commandPath: null

    constructor: (search, folder)->
      @commandPath = 'ag'
      @args = ['-i', search, '--nocolor', '--nogroup', '--column', folder]

    setup: ->

    run: (callback)->
      command = @commandPath
      args = @args

      stdout = (output)=>
        @parseOutput(output, callback)

      stderr = (error)->
        callback(error: error)

      @process = new BufferedProcess({command, args, stdout, stderr})

    parseOutput: (output, callback)->
      items = output.split(/\n/).map (item)->
        [path, line, column, content...] = item.split(':')
        filePath: path
        line: line-1
        column: column-1
        content: content.join(':').replace(/^s/g, '')
      callback items

    destroy: ->
      @process.kill()