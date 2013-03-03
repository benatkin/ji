# Borrowed from https://raw.github.com/jashkenas/journo/master/Cakefile
{spawn} = require 'child_process'
fs = require 'fs'

buildOrWatch = (watch) ->
  flags = if watch then '-cw' else '-c'
  compiler = spawn 'coffee', [flags, '.']
  compiler.stdout.on 'data', (data) -> console.log data.toString().trim()
  compiler.stderr.on 'data', (data) -> console.error data.toString().trim()

task "build", "build the source", ->
  buildOrWatch false

task "watch", "watch and build the source", ->
  buildOrWatch true

# Until GitHub has proper Literate CoffeeScript highlighting support, let's
# manually futz the README ourselves.
task "readme", "rebuild the readme file", ->
  source = fs.readFileSync('ji.litcoffee').toString()
  source = source.replace /\n\n    ([\s\S]*?)\n\n(?!    )/mg, (match, code) ->
    "\n```coffeescript\n#{code.replace(/^    /mg, '')}\n```\n"
  fs.writeFileSync 'README.md', source

