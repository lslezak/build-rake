
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

    describe 'on non-Windows', ->
      beforeEach ->
        Object.defineProperty process, 'platform', value: 'MockOS'

      it 'runs rake to get the list of tasks', ->
        spyOn(child_process, 'exec').andCallFake ->
          child_process.exec.mostRecentCall.args[2](null, '', '')

        waitsForPromise -> builder.settings()

        runs ->
          expect(child_process.exec.mostRecentCall.args[0]).toEqual('rake -T')

      it 'returns the found rake tasks', ->
          # mocked "rake -T" output
          rakeOutput = "rake test   # run all tests\n"
          spyOn(child_process, 'exec').andCallFake ->
            child_process.exec.mostRecentCall.args[2](null, rakeOutput, '')

          waitsForPromise -> builder.settings().then (settings) ->
            expect(settings.length).toBe(1)
            expect(settings[0].exec).toEqual('rake')
            expect(settings[0].args).toEqual(['test'])

    describe 'on Windows', ->
      beforeEach  ->
        Object.defineProperty process, 'platform', value: 'win32'

      it 'returns the found rake tasks', ->
          # mocked "rake -T" output
          rakeOutput = "rake test   # run all tests\n"
          spyOn(child_process, 'exec').andCallFake ->
            child_process.exec.mostRecentCall.args[2](null, rakeOutput, '')

          waitsForPromise -> builder.settings().then (settings) ->
            expect(settings.length).toBe(1)
            expect(settings[0].exec).toEqual('rake.bat')
            expect(settings[0].args).toEqual(['test'])

      it 'runs rake.bat to get the list of tasks', ->
        spyOn(child_process, 'exec').andCallFake ->
          child_process.exec.mostRecentCall.args[2](null, '', '')

        waitsForPromise -> builder.settings()

        runs ->
          expect(child_process.exec.mostRecentCall.args[0])
            .toEqual('rake.bat -T')

