
fs = require('fs')
path = require('path')
child_process = require('child_process')
{provideRakeBuilder} = require('../lib/build-rake')

describe 'Rakefile provider', ->
  Builder = provideRakeBuilder()
  builder = null
  projectDir = 'foo'

  beforeEach ->
    builder = new Builder(projectDir)

  it 'returns "Rake" as the nice name', ->
    expect(builder.getNiceName()).toEqual('Rake')

  describe 'when Rakefile does not exist', ->
    it 'should not be eligible', ->
      spyOn(fs, 'existsSync').andReturn(false)

      expect(builder.isEligible()).toBe(false)
      expect(fs.existsSync.calls[0].args[0])
        .toEqual(path.join(projectDir, 'Rakefile'))

  describe 'when Rakefile exists', ->
    it 'should be eligible', ->
      spyOn(fs, 'existsSync').andReturn(true)

      expect(builder.isEligible()).toBe(true)
      expect(fs.existsSync.calls[0].args[0])
        .toEqual(path.join(projectDir, 'Rakefile'))

    it 'returns the found rake tasks', ->
      # mocked "rake -T" output
      rakeOutput = "rake test   # run all tests\n"
      spyOn(child_process, 'exec').andCallFake ->
        child_process.exec.mostRecentCall.args[2](null, rakeOutput, '')

      waitsForPromise -> builder.settings().then (settings) ->
        expect(settings.length).toBe(1)
        expect(settings[0].exec).toEqual('rake')
        expect(settings[0].args).toEqual(['test'])

    describe 'on non-Windows', ->

      it 'runs rake to get the list of tasks', ->
        Object.defineProperty process, 'platform', value: 'MockOS'
        spyOn(child_process, 'exec').andCallFake ->
          child_process.exec.mostRecentCall.args[2](null, '', '')

        waitsForPromise -> builder.settings()

        runs ->
          expect(child_process.exec.mostRecentCall.args[0]).toEqual('rake -T')

    describe 'on Windows', ->

      it 'runs rake to get the list of tasks', ->
        Object.defineProperty process, 'platform', value: 'win32'
        spyOn(child_process, 'exec').andCallFake ->
          child_process.exec.mostRecentCall.args[2](null, '', '')

        waitsForPromise -> builder.settings()

        runs ->
          expect(child_process.exec.mostRecentCall.args[0])
                 .toEqual('rake.bat -T')

