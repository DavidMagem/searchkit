elasticsearch = require "elasticsearch"
promise       = require "bluebird"
moment        = require "moment"
_             = require "lodash"
assets        = require "./assets"

client = new elasticsearch.Client({
  host:"localhost:9200"
})

getMultiFieldDef = (name) ->
  def = {
    type: "multi_field"
    fields: {
      "raw": {type:"string", "index": "not_analyzed"}
    }
  }

processedAssets = _.map(assets,(asset)->
  return {
    title:asset.title
    pixelWidth:asset.pixelwidth
    pixelHeight: asset.pixelheight
    orientation: asset.orientation
    originalFilename: asset.originalFilename
    filetype: asset.filetype
    fileCategory: asset.fileCategory
    created: asset.datecreated
    modified: asset.datemodified
    assetExpiry: asset.assetExpiryDate
    imagePath: "#{asset.pathFolderNames.join('/')}/#{asset.originalFilename}"
    resolution: asset.resolution
  }
)

mapping = {
  index:"assets"
  type:"asset"
  body:
    asset:
      properties:
        version:{type:"integer"}
        pixelWidth:{type:"integer"}
        pixelHeight: {type:"integer"}

}
commands = []

for m in processedAssets
  commands.push {index:{_index:"assets", _type:"asset", _id:m.artwork_id}}
  commands.push(m)

client.indices.delete {index:"assets"}, (err, res)->
  console.log(err, res)
  client.indices.create {index:"assets"}, (err, res)->
    console.log(err, res)
    client.indices.putMapping mapping, (err, res)->
      console.log(err, res)
      client.bulk {body:commands}, (err, res)->
        if err
          return console.log err
        if res.errors
          return console.log(res.errors)

        console.log "indexed #{res.items.length} items in #{res.took}ms"