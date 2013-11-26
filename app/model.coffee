root = this
if Meteor.isClient
  Meteor.startup ->
    root.ScenarioCollection = new Meteor.Collection 'scenarios'
    root.AccountCollection = new Meteor.Collection 'accounts'
    root.ItemCollection = new Meteor.Collection 'items'
    root.PaymentCollection = new Meteor.Collection 'payments'
    root.UsageCollection = new Meteor.Collection 'usages'

if Meteor.isServer
  Meteor.startup ->
    ScenarioCollection = new Meteor.Collection 'scenarios'
    AccountCollection = new Meteor.Collection 'accounts'
    ItemCollection = new Meteor.Collection 'items'
    PaymentCollection = new Meteor.Collection 'payments'
    UsageCollection = new Meteor.Collection 'usages'

    adminPassword = null
      
    Meteor.methods
      reset: (selector) ->
        console.log 'reseting by',selector
        AccountCollection.remove selector
        PaymentCollection.remove selector
        ItemCollection.remove selector
        UsageCollection.remove selector
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
      createHash: (string) ->
        safepw.hash(string)
      validateHash: (hash, string) ->
        safepw.validate hash, string

