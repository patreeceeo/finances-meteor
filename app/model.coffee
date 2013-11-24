root = this
if Meteor.isClient
  Meteor.startup ->
    root.ScenarioCollection = new Meteor.Collection 'scenarios'
    root.AccountCollection = new Meteor.Collection 'accounts'
    root.ItemCollection = new Meteor.Collection 'items'
    root.PaymentCollection = new Meteor.Collection 'payments'
    root.UsageCollection = new Meteor.Collection 'usages'
    scenarioId = Router.getData().scenarioId
    root.currentScenario = new finances.Scenario
    root.currentScenario._id ?= Router.getData().scenarioId
    root.scenarioDep = new Deps.Dependency
    ScenarioCollection.find().observe
      added: (document) ->
        _.extend root.currentScenario, document
        if document._id?
          scenarioDep.changed()

if Meteor.isServer
  Meteor.startup ->
    ScenarioCollection = new Meteor.Collection 'scenarios'
    AccountCollection = new Meteor.Collection 'accounts'
    ItemCollection = new Meteor.Collection 'items'
    PaymentCollection = new Meteor.Collection 'payments'
    UsageCollection = new Meteor.Collection 'usages'

    Meteor.methods
      reset: ->
        AccountCollection.remove({})
        PaymentCollection.remove({})
        ItemCollection.remove({})
        UsageCollection.remove({})
      removePayments: (selector) ->
        PaymentCollection.remove(selector)
      removeAccount: (_id) ->
        UsageCollection.remove(fromAccount: _id)
        PaymentCollection.remove(fromAccount: _id)
        PaymentCollection.remove(toAccount: _id)
        AccountCollection.remove(_id)
      removeItem: (_id) ->
        UsageCollection.remove(item: _id)
        PaymentCollection.remove(items: _id)
        ItemCollection.remove(_id)
