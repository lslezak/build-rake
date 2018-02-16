
fs = require('fs')
path = require('path')
child_process = require('child_process')

exports.config =
  rakePlatform:
    title: 'Platform on which Rake runs'
    type: 'string'
    enum: [
      {order: 1, value: 'auto', description: 'Auto-detect'}
      {order: 2, value: 'unix', description: 'Unix (rake)'}
      {order: 3, value: 'windows', description: 'Windows (rake.bat)'}
    ]
    default: 'auto'

exports.provideRakeBuilder = ->
  class RakeBuildProvider
    constructor: (@cwd) ->

    getNiceName: ->
      'Rake'

    isEligible: ->
      files = ['Rakefile', 'rakefile', 'Rakefile.rb', 'rakefile.rb']
      found = files.map (file) => path.join(@cwd, file)
        .filter(fs.existsSync)

      found.length > 0

    settings: ->
      new Promise (resolve, reject) =>
        rake_exec = switch atom.config.get('build-rake.rakePlatform')
          when 'auto'
            if /^win/.test(process.platform) then 'rake.bat' else 'rake'
          when 'windows' then 'rake.bat'
          else 'rake'
        rake_t = "#{rake_exec} -T"
        child_process.exec rake_t, {cwd: @cwd}, (error, stdout, stderr) ->
          reject(error) if error?
          config = []
          stdout.split("\n").forEach (line) ->
            if (m = /^rake (\S+)\s*#\s*(\S+.*)/.exec(line))?
              config.push
                name: "rake #{m[1]} - #{m[2]}"
                exec: rake_exec
                sh: false
                args: [ m[1] ]
          resolve(config)
