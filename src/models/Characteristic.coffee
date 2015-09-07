_ = require 'lodash'
Promise = require 'when'

###
# Characteristic schema
###

module.exports = (mongoose) ->
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId

  CharacteristicSchema = new Schema
    text:
      type: String
      required: true
      index:
        unique: true
    textLower:
      type: String
      index:
        unique: true
    attributes:
      type: Object
      default: -> new Object()
    createdAt:
      type: Date
      default: Date.now

  CharacteristicSchema.statics.getOrCreateArray = (arr) ->
    return Promise.resolve() unless arr?.length > 0
    mpromise = @where
      text:
        '$in': arr
    .find()
    Promise(mpromise).then (chars) =>
      Promise.all _.map arr, (char) =>
        existing = _.find chars, (existingChar) ->
          existingChar.textLower == char.toLowerCase()
        return existing if existing
        @getOrCreate char

  CharacteristicSchema.statics.getOrCreate = (obj, retry = true) ->
    Characteristic = mongoose.model 'Characteristic'
    if typeof obj is 'string'
      obj =
        text: obj

    return Promise.reject new Error 'Bad input' unless obj.text?.length > 0

    obj.textLower = obj.text.toLowerCase()

    mpromise = Characteristic
    .where
      textLower: obj.textLower
    .findOne()
    Promise(mpromise).then (char) ->
      return char if char
      obj.attributes =
        rated: false
      char = new Characteristic obj
      char.markModified 'attributes'
      Promise char.save()
      .catch (err) ->
        console.log 'char save error', err if err
        throw err unless retry == true
        Promise.promise (resolve, reject) ->
          setTimeout ->
            resolve Characteristic.getOrCreate obj, false
          , 100 + Math.random() * 100
      .then -> char

  # CharacteristicSchema.pre 'save', (next) ->
  #   if !@ratings
  #     @ratings = {}
  #   if !@ratings.overall
  #     @ratings.overall = 0
  #   if !@ratings.likes
  #     @ratings.likes = 0
  #   if !@ratings.dislikes
  #     @ratings.dislikes = 0
  #
  #   likes = @ratings.likes
  #   dislikes = @ratings.dislikes
  #   if likes == 0 || dislikes == 0
  #     likes *= likes
  #     dislikes *= dislikes
  #   factors = []
  #   likeness = 0
  #   thumbs = dislikes + likes
  #   percent = if thumbs < 100 then thumbs else 100
  #   percent = if percent > 10 then percent else percent + (10-percent)*.5
  #   if dislikes > likes
  #     likeness = -(dislikes-likes)/dislikes*percent
  #   if likes > dislikes
  #     likeness = (likes-dislikes)/likes*percent
  #   if likeness != 0
  #     factors[0] = likeness
  #
  #   sum = 0
  #   for k, val in @ratings
  #     if parseFloat(@ratings[k]) != 0 and k != 'overall' and k != 'likes' and k != 'dislikes'
  #       factors[factors.length] = parseFloat @ratings[k]
  #   factors.forEach (f) => sum += f
  #   @ratings.overall = if factors.length > 0 then sum/factors.length else 0
  #   @markModified 'ratings'
  #
  #   next()

  mongoose.model 'Characteristic', CharacteristicSchema
