root = this

root.MAX_USERS = 100

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

    Meteor.publish 'scenarios', (selector) ->
      console.log 'scenarios', ScenarioCollection.find(selector).fetch()
      ScenarioCollection.find(selector)
    Meteor.publish 'accounts', (selector) ->
      AccountCollection.find(selector)
    Meteor.publish 'items', (selector) ->
      ItemCollection.find(selector)
    Meteor.publish 'payments', (selector) ->
      PaymentCollection.find(selector)
    Meteor.publish 'usages', (selector) ->
      UsageCollection.find(selector)

    Meteor.methods
      reset: (selector) ->
        AccountCollection.remove selector
        PaymentCollection.remove selector
        ItemCollection.remove selector
        UsageCollection.remove selector
      removePayments: (selector) ->
        PaymentCollection.remove(selector)
      removeUsages: (selector) ->
        UsageCollection.remove(selector)
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

