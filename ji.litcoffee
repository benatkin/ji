ji
==

`ji` is a JSON Inspector for the command line.

Input
-----

ji handles its input much like `grep`. Data can be passed to it through stdin
or by providing a list of filenames. Globbing works.

The Reader class reads from the standard input or a list of files, and emits
events when a JSON document is read, and when it's finished reading documents.

    {EventEmitter} = require 'events'
    fs = require 'fs'
    querystring = require 'querystring'

    class Reader extends EventEmitter

Read the standard input, by resuming the standard input stream and calling
`@readStream` on it.

      readStandardInput: ->
        process.stdin.setEncoding 'utf8'
        process.stdin.resume()
        @readStream '(standard input)', process.stdin, =>
          @emit 'end'

Read the next file from the `@filenames` array which contains the remaining
files to be read.

      _readNextFile: () ->
        filename = @_filenames.shift()
        if filename
          stream = fs.createReadStream filename
          stream.setEncoding 'utf8'
          @readStream filename, stream, =>
            @_readNextFile()
        else
          @emit 'end'

Read a list of files. Makes a copy of the filenames so it can be modified
without modifying the value passed in by reference.

      readFiles: (filenames) ->
        @_filenames = filenames.slice()
        @_readNextFile()

Read data from a stream. At present only one document per stream is permitted.

      readStream: (name, stream, done) ->
        data = ''
        stream.on 'data', (chunk) ->
          data += chunk
        stream.on 'end', =>
          document = JSON.parse(data)
          @emit 'data', name, document

Selecting Nodes
---------------

[JSON Pointer][json-pointer] is used for selecting nodes. It uses the same
syntax as URLs. This differs from the spec in that you're allowed to omit the
leading slash ('/').

    class Pointer

To decode, split a string on slashes and unescape each component.

      @decode: (path) ->
        (querystring.unescape(component) for component in path.split '/')

To encode, escape each component and join it with a slash.

      @encode: (components) ->
        escaped = (querystring.escape(component) for component in components)
        escaped.join '/'

Get a value at a jsonpointer path.

      @get: (document, path) ->
        value = document
        components = Pointer.decode path
        for component in components
          if typeof value == 'object' and value != null
            value = value[component]
          else
            value = undefined
        value

Printing Data
-------------

    class Printer
      print: (data) ->
        str = JSON.stringify data, null, 2
        console.log str

Gluing It Together
------------------

A Program class interprets the command-line arguments and runs commands.

    class Program

Construct the object instances.

      constructor: ->
        @reader = new Reader
        @printer = new Printer
        @buildOptions()

The options are specified here. The key is both the key that will be set on
the Program instance and the default long option name. A boolean option won't
use a parameter; all other options will.

      options:
        path:
          short: 'p'
        #replace:
        #  short: 'r'
        #flat:
        #  short: 'f'
        #  boolean: true

Build the options into a more searchable format.

      buildOptions: ->
        @_options = {}
        for name, option of @options
          option.name = name
          option.long or= name
          @_options[option.long] = option
          @_options[option.short] = option if option.short

Parse the arguments using the options table. Make a lookup table for short
options.

      parse: (argv) ->
        args = argv.slice(2)
        @filenames = []
        i = 0
        while i < args.length
          if /^-/.test(args[i])
            option = @_options[args[i][1]]
            @exitWithError 'unrecognized option: ' + args[i] unless option
            if option.boolean
              @[option.name] = true
            else
              if typeof args[i+1] == 'undefined'
                @exitWithError 'value required for option ' + args[i]
              @[option.name] = args[i+1]
              i += 1
          else
            @filenames.push args[i]
          i += 1

Parse the options and execute the command.

      run: ->
        @parse process.argv
        @reader.on 'data', (name, document) =>
          value = document
          if @path
            value = Pointer.get document, @path
          @printer.print value unless typeof value == 'undefined'
        if @filenames.length > 0
          @reader.readFiles @filenames
        else
          @reader.readStandardInput()

Display errors.

      showError: (message) ->
        console.error 'error: ' + message

      exitWithError: (message) ->
        @showError message
        process.exit 1

Run the program, unless this is being imported from another module.

    unless module.parent
      program = new Program()
      program.run()

Export the classes.

    exports.Reader = Reader
    exports.Pointer = Pointer
    exports.Printer = Printer
    exports.Program = Program

  [json-pointer]: http://datatracker.ietf.org/doc/draft-ietf-appsawg-json-pointer/
