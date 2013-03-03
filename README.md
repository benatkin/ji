ji
==

`ji` is a JSON Inspector for the command line.

Input
-----

ji handles its input much like `grep`. Data can be passed to it through stdin
or by providing a list of filenames. Globbing works.

The Reader class reads from the standard input or a list of files, and emits
events when a JSON document is read, and when it's finished reading documents.
```coffeescript
{EventEmitter} = require 'events'
fs = require 'fs'

class Reader extends EventEmitter
```
Read the standard input, by resuming the standard input stream and calling
`@readStream` on it.
```coffeescript
  readStandardInput: ->
    process.stdin.setEncoding 'utf8'
    process.stdin.resume()
    @readStream '(standard input)', process.stdin, =>
      @emit 'end'
```
Read the next file from the `@filenames` array which contains the remaining
files to be read.
```coffeescript
  _readNextFile: () ->
    filename = @_filenames.shift()
    if filename
      stream = fs.createReadStream filename
      stream.setEncoding 'utf8'
      @readStream filename, stream, =>
        @_readNextFile()
    else
      @emit 'end'
```
Read a list of files. Makes a copy of the filenames so it can be modified
without modifying the value passed in by reference.
```coffeescript
  readFiles: (filenames) ->
    @_filenames = filenames.slice()
    @_readNextFile()
```
Read data from a stream. At present only one document per stream is permitted.
```coffeescript
  readStream: (name, stream, done) ->
    data = ''
    stream.on 'data', (chunk) ->
      data += chunk
    stream.on 'end', =>
      document = JSON.parse(data)
      @emit 'data', name, document
```
Printing Data
-------------
```coffeescript
class Printer
  print: (data) ->
    str = JSON.stringify data, null, 2
    console.log str
```
Gluing It Together
------------------

A Program class interprets the command-line arguments and runs commands.
```coffeescript
class Program
```
Construct the object instances.
```coffeescript
  constructor: ->
    @reader = new Reader
    @printer = new Printer
    @buildOptions()
```
The options are specified here. The key is both the key that will be set on
the Program instance and the default long option name. A boolean option won't
use a parameter; all other options will.
```coffeescript
  options:
    path:
      short: 'p'
    replace:
      short: 'r'
    flat:
      short: 'f'
      boolean: true
```
Build the options into a more searchable format.
```coffeescript
  buildOptions: ->
    @_options = {}
    for name, option of @options
      option.name = name
      option.long or= name
      @_options[option.long] = option
      @_options[option.short] = option if option.short
```
Parse the arguments using the options table. Make a lookup table for short
options.
```coffeescript
  parse: (argv) ->
    @filenames = argv.slice(2)
```
Parse the options and execute the command.
```coffeescript
  run: ->
    @parse process.argv
    @reader.on 'data', (name, document) =>
      @printer.print document
    if @filenames.length > 0
      @reader.readFiles @filenames
    else
      @reader.readStandardInput()
```
Display errors.
```coffeescript
  showError: (message) ->
    console.error 'Error: ' + message

  exitWithError: (message) ->
    @showError message
    process.exit 1
```
Run the program, unless this is being imported from another module.
```coffeescript
unless module.parent
  program = new Program()
  program.run()
```
Export the classes.
```coffeescript
exports.Reader = Reader
exports.Printer = Printer
exports.Program = Program
```
[JSON Pointer][json-pointer] is used for addressing a node.

  [json-pointer]: http://datatracker.ietf.org/doc/draft-ietf-appsawg-json-pointer/
