Promise = require 'when'

CharacteristicSchema = require './models/Characteristic'

module.exports = (System) ->
  Characteristic = System.registerModel 'Characteristic', CharacteristicSchema
  ActivityItem = System.getModel 'ActivityItem'

  saveModel = (item) ->
    Promise.promise (resolve, reject) ->
      item.save (err) ->
        return reject err if err
        where =
          'attributes.characteristic': item._id
        delta =
          'attributes.rated': false
        options =
          multi: true
        ActivityItem
        .update where, delta, options, (err, updateResult) ->
          console.log 'reset ratings', err, updateResult
          resolve item

  getByText = (text) ->
    mpromise = Characteristic
    .where
      text: text
    .findOne()
    Promise mpromise

  routes:
    admin:
      '/admin/characteristic/:id/show': 'show'
      '/admin/characteristic/search': 'search'

  handlers:
    show: (req, res, next) ->
      Characteristic
      .where
        _id: req.params.id
      .findOne (err, item) ->
        return next err if err
        if item.toObject
          item = item.toObject()
        delete item.data
        res.render 'show',
          data: [item]
    search: (req, res, next) ->
      text = req.query.text
      return next() unless text?.length > 0
      Characteristic
      .where
        textLower: text.toLowerCase()
      .findOne (err, item) ->
        return next err if err
        return next() unless item
        if item.toObject
          item = item.toObject()
        delete item.data
        res.render 'show',
          data: [item]

  globals:
    public:
      activityItem:
        populate:
          characteristic: 'Characteristic'
      editStreamConditionOptions:
        hasLink:
          description: 'has link'
          where: 'characteristic.query.hasLink'
        doesNotHaveLink:
          description: 'no link'
          where: 'characteristic.query.doesNotHaveLink'
  events:
    characteristic:
      save:
        do: saveModel
      query:
        hasLink:
          do: (data = {}) ->
            getByText 'has link'
            .then (characteristic) ->
              if characteristic
                data.query['attributes.characteristic'] = characteristic?._id
              else
                data.query['nope'] = 'i guess we should make it return no results?'
              data
        doesNotHaveLink:
          do: (data = {}) ->
            getByText 'has link'
            .then (characteristic) ->
              if characteristic
                data.query['attributes.characteristic'] =
                  '$ne': characteristic?._id
              else
                console.log 'no has-link characteristic.. let everything through?'
              data

  models:
    Characteristic: Characteristic
