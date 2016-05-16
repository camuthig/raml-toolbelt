express     = require 'express'
path        = require 'path'
program     = require 'commander'
spawn       = require('child_process').spawn
request     = require 'request'
pkg         = require path.resolve __dirname, '../package.json'
fs          = require 'fs'
raml_parser = require 'raml-parser'


app         = express()
SPEC        = ''

starts_with = ( str, search ) -> 0 is str.indexOf search
file_or_url_to_absolute = ( file ) ->
  if starts_with(file, 'http:') or starts_with(file, 'https:')
    file
  else
    path.resolve process.cwd(), file

create_html = (raml_url) -> """
    </html>
    <head>
      <link rel="stylesheet" href="/api-console/styles/api-console-light-theme.css" type="text/css" />
    </head>
    <body ng-app="ramlConsoleApp" ng-cloak>
      <script src="/api-console/scripts/api-console-vendor.js"></script>
      <script type="text/javascript" src="/api-console/scripts/api-console.js"></script>
      <script type="text/javascript">
        $.noConflict();
      </script>

      <div style="overflow: auto; position: relative">
        <raml-console src="#{raml_url}" />
      </div>
    </body>
    </html>
  """

launch_webapp = ( port, cb ) ->
  app.get '/', (req, res) ->
    html = create_html(SPEC)
    res.send html
  app.use '/api-console',  express.static path.resolve __dirname, '../api-console/dist'
  app.use '/api-designer', express.static path.resolve __dirname, '../api-designer/dist'
  app.get '/~raml-is', (req, res) -> res.send 'awesome'
  app.use '/', express.static '/'
  app.listen port, cb

webapp_is_listening = ( port, cb ) -> request "http://localhost:#{port}/~raml-is", (e, r, b) -> cb null, b is 'awesome'
launch_webapp_once  = ( port, cb ) -> webapp_is_listening port, (e, r) -> if r then cb() else launch_webapp port, cb

program
  .version(pkg.version)

program
  .command 'console <file>'
  .description 'Run a console for the given specification file. The file can be a relative path or URL.'
  .option '-p, --port <number>', 'Port to run on', 10500
  .action (spec, options) ->
    launch_webapp_once options.port, ->
      SPEC = file_or_url_to_absolute spec
      spawn 'open', [ "http://localhost:#{options.port}/"]

program
  .command 'validate <file>'
  .description 'Validate the RAML. The file can be either a relative path or URL.'
  .action (spec, options) ->
    file = file_or_url_to_absolute spec
    ramljsonexpander = require('raml-jsonschema-expander');
    nok = ( err )  -> console.error JSON.stringify err, null, 2
    ok  = ( node ) -> console.log "Successfully parsed RAML"
    raml_parser.composeFile( file ).then ok, nok
    

program.parse(process.argv);

# console.log(process.argv.slice(2).length)
if process.argv.slice(2).length == 0
  program.outputHelp((txt) -> return txt)
