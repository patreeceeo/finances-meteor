if Meteor.isClient
  AccountCollection = new Meteor.Collection 'accounts',
    transform: (doc) ->
      scenario.createAccount doc
  ItemCollection = new Meteor.Collection 'items',
    transform: (doc) ->
      scenario.createItem doc
  PaymentCollection = new Meteor.Collection 'payments',
    transform: (doc) ->
      scenario.createPayment doc
  UsageCollection = new Meteor.Collection 'usage',
    transform: (doc) ->
      scenario.createUsage doc

  for C in [AccountCollection, ItemCollection, PaymentCollection, UsageCollection]
    _(C).extend insertOrUpdate: (frag) ->
      if not frag._id?
        @insert frag
      else
        @update frag._id, { $set: _(frag).omit('_id') }

  scenario = new finances.Scenario
    createAccount: (doc) ->
      AccountCollection.insertOrUpdate doc
      new finances.Account _.extend doc, scenario: this
    createItem: (doc) ->
      ItemCollection.insertOrUpdate doc
      new finances.Item _.extend doc, scenario: this
    createPayment: (doc) ->
      PaymentCollection.insertOrUpdate doc
      new finances.Payment _.extend doc, scenario: this
    createUsage: (doc) ->
      UsageCollection.insertOrUpdate doc
      new finances.Usage _.extend doc, scenario: this
    findAccounts: (sel) ->
      AccountCollection.find(sel).fetch()
    findAccount: (sel) ->
      AccountCollection.findOne(sel)
    findItems: (sel) ->
      ItemCollection.find(sel).fetch()
    findItem: (sel) ->
      ItemCollection.findOne(sel)
    findPayments: (sel) ->
      PaymentCollection.find(sel).fetch()
    findPayment: (sel) ->
      PaymentCollection.findOne(sel)
    findUsages: (sel) ->
      UsageCollection.find(sel).fetch()
    findUsage: (sel) ->
      UsageCollection.findOne(sel)
    savePayment: (doc) ->
      PaymentCollection.update doc._id, doc
    deletePayment: (doc) ->
      PaymentCollection.remove(doc._id)
    

  exports = this
  _.extend exports,
    AccountCollection: AccountCollection
    ItemCollection: ItemCollection
    PaymentCollection: PaymentCollection
    UsageCollection: UsageCollection
    fetchAccounts: ->
      AccountCollection.find().fetch()
    fetchItems: ->
      ItemCollection.find().fetch()
    fetchPayments: ->
      PaymentCollection.find().fetch()
    fetchAll: ->
      accounts: @fetchAccounts()
      items: @fetchItems()
      payments: @fetchPayments()
    currentScenario: scenario

if Meteor.isServer
  PaymentCollection?.remove({})
  Meteor.startup ->
    AccountCollection = new Meteor.Collection 'accounts'
    ItemCollection = new Meteor.Collection 'items'
    PaymentCollection = new Meteor.Collection 'payments'
    UsageCollection = new Meteor.Collection 'usage'

    AccountCollection.allow
      insert: -> true
      update: -> true
      remove: -> true
    ItemCollection.allow
      insert: -> true
      update: -> true
      remove: -> true
    PaymentCollection.allow
      insert: -> true
      update: -> true
      remove: -> true
    UsageCollection.allow
      insert: -> true
      update: -> true
      remove: -> true

    Meteor.methods
      reset: ->
        AccountCollection.remove({})
        PaymentCollection.remove({})
        ItemCollection.remove({})
        UsageCollection.remove({})
      removeUnsettledPayments: ->
        PaymentCollection.remove(settled: false)

