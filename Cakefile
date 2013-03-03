# Borrowed from https://raw.github.com/jashkenas/journo/master/Cakefile
{spawn} = require 'child_process'
fs = require 'fs'

task "build", "watch and build the source", ->
  compiler = spawn 'coffee', ['-cw', '.']
  compiler.stdout.on 'data', (data) -> console.log data.toString().trim()
  compiler.stderr.on 'data', (data) -> console.error data.toString().trim()

# Until GitHub has proper Literate CoffeeScript highlighting support, let's
# manually futz the README ourselves.
task "readme", "rebuild the readme file", ->
  source = fs.readFileSync('ji.litcoffee').toString()
  source = source.replace /\n\n    ([\s\S]*?)\n\n(?!    )/mg, (match, code) ->
    "\n```coffeescript\n#{code.replace(/^    /mg, '')}\n```\n"
  fs.writeFileSync 'README.md', source

