
fs = require('fs')
path = require('path')
child_process = require('child_process')

exports.provideRakeBuilder = ->
  class RakeBuildProvider
    constructor: (@cwd) ->

    getNiceName: ->
      'Rake'

    isEligible: ->
      files = ['Rakefile', 'rakefile', 'Rakefile.rb', 'rakefile.rb']
      found = files.map (file) => path.join(@cwd, file)
        .filter(fs.existsSync)

      gemfiles = ['Gemfile', 'Gemfile.lock']
      gemfilesFound = files.map (file) => path.join(@cwd, file)
        .filter(fs.existsSync)
      @useBundler = (gemfilesFound.length > 0)

      found.length > 0

    settings: ->
      new Promise (resolve, reject) =>
        rake_exec = if /^win/.test(process.platform) then "rake.bat" else "rake"
        rake_exec = "bundle exec #{rake_exec}" if @useBundler
        rake_t    = "#{rake_exec} -T"
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
