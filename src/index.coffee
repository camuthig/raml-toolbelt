express     = require 'express'
path        = require 'path'
program     = require 'commander'
spawn       = require('child_process').spawn
request     = require 'request'
pkg         = require path.resolve __dirname, '../package.json'
fs          = require 'fs'
raml_parser = require 'raml-parser'

app         = express()

PORT        = 10500

starts_with = ( str, search ) -> 0 is str.indexOf search
file_or_url_to_absolute = ( file ) ->
  if starts_with(file, 'http:') or starts_with(file, 'https:')
    file
  else
    path.resolve process.cwd(), file

launch_webapp = ( port, cb ) ->
  app.get '/', (req, res) ->
    raml_url = req.query.url
    html = """
        <html>
        <head>
            <link rel="stylesheet" href="/api-console/styles/app.css" type="text/css" />
        </head>
        <body ng-app="ramlConsoleApp" ng-cloak id="raml-console-unembedded">
            <script src="/api-console/scripts/vendor.js"></script>
            <script src="/api-console/scripts/app.js"></script>
            <div style="overflow: auto; position: relative">
                <raml-console src="#{raml_url}"/>
            </div>
        </body>
        </html>
      """
    res.send html
  app.use '/api-console',  express.static path.resolve __dirname, '../api-console/dist'
  app.use '/api-designer', express.static path.resolve __dirname, '../api-designer/dist'
  app.get '/~raml-is', (req, res) -> res.send 'awesome'
  app.use '/', express.static '/'
  app.listen port, cb

webapp_is_listening = ( port, cb ) -> request "http://localhost:#{port}/~raml-is", (e, r, b) -> cb null, b is 'awesome'
launch_webapp_once  = ( port, cb ) -> webapp_is_listening port, (e, r) -> if r then cb() else launch_webapp port, cb

args = process.argv.slice 2

if args.length isnt 2
  console.log 'usage: raml console {file or url}'
  process.exit()

switch args[0]
  when 'console'
    launch_webapp_once PORT, ->
      file = file_or_url_to_absolute args[1]
      spawn 'open', [ "http://localhost:#{PORT}/?url=" + encodeURIComponent file ]
  when 'edit'
    null
  when 'validate'
    file = file_or_url_to_absolute args[1]
    nok = ( err )  -> console.error JSON.stringify err, null, 2
    ok  = ( node ) -> console.log "Successfully parsed RAML"
    raml_parser.composeFile( file ).then ok, nok

###
program
  .version(pkg.version)
  .option('-p, --port <port>', 'Port (defaults to 10556)', parseInt)
  .parse(process.argv)
port = program.port or 10556
###