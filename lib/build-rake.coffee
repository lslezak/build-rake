
fs = require('fs')
path = require('path')

exports.provideRakeBuilder = ->
  class RakeBuildProvider
    constructor: (@cwd) ->

    getNiceName: ->
      'Rake'

    isEligible: ->
      fs.existsSync(path.join(@cwd, 'Rakefile'))
      
    settings: ->
      new Promise (resolve, reject) ->
        require('child_process').exec "rake -T", (error, stdout, stderr) ->
          reject(error) if error?
          config = []
          stdout.split("\n").forEach (line) ->
            if (m = /^rake (\S+)\s*#\s*(\S+.*)/.exec(line))?
              config.push
                name: "rake #{m[1]} - #{m[2]}"
                exec: "rake"
                sh: false
                args: [ m[1] ]
          resolve(config)
          