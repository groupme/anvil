async    = require("async")
fs       = require("fs")
http     = require("http")
manifest = require("./manifest")
mkdirp   = require("mkdirp")
os       = require("os")
path     = require("path")
program  = require("commander")
url      = require("url")
util     = require("util")

program
  .version(require("#{__dirname}/../package.json").version)
  .usage('[options] <slug url>')
  .option('-a, --auth <password>', 'admin password')
  .option('-c, --concurrency <num>', 'number of workers', os.cpus().length)
  .option('-e, --env <url>', 'environment file')
  .option('-p, --port <port>', 'port on which to listen', 3000)

datastore_fetchers = (manifest, dir) ->
  fetchers = {}
  for name, file_manifest of manifest
    do (name, file_manifest) =>
      fetchers[file_manifest.hash] = (async_cb) =>
        filename = "#{dir}/#{name}"
        mkdirp path.dirname(filename), =>
          fs.open filename, "w", (err, fd) =>
            console.log "url", "#{process.env.ANVIL_HOST}/file/#{file_manifest["hash"]}"
            get = http.get(url.parse("#{process.env.ANVIL_HOST}/file/#{file_manifest["hash"]}"))
            get.on "data", (chunk) -> fs.write fs, chunk
            get.on "end", ->
              fs.fchmod fd, file_manifest.mode
              fs.close fd
              async_cb null, true

module.exports.execute = (args) ->
  program.parse(args)
  fs.readFile program.args[0], (err, data) ->
    manifest = JSON.parse(data)
    mkdirp program.args[1]
    async.parallel datastore_fetchers(manifest, program.args[1]), (err, results) ->
      cb spawn("tar", ["czf", "-", "."], cwd:path)

  console.log "args", program.args
  # crossover.create(program).listen(program.args[0], program.env, program.port)
