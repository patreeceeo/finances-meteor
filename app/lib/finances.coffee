#
# dinner:
#   sugardaddy: Fred
#   moochers: Dafny Shaggy Scooby
# hotel:
#   sugermomma: Thelma
#   moochers: Fred Shaggy Scooby

log =
  write: ->
    console.debug.apply console, arguments

@finances ?= {}

if not _?
  _ = Package?.underscore._

class finances.Base
  constructor: (doc) ->
    _.extend this, doc 
  findOne: (Collection, selector) ->
    Collection.findOne selector
  find: (Collection, selector = {}, options = {}) ->
    extendedSelector = _.extend _(selector).clone(),
      scenario: @scenario or @_id
    Collection.find(extendedSelector, options)
  _scenario: (selector = @scenario) ->
    @findOne ScenarioCollection, selector
  _account: (selector = @account) ->
    @findOne AccountCollection, selector
  _accounts: (selector, options = {}) ->
    @find AccountCollection, selector
  _item: (selector = @item) ->
    @findOne ItemCollection, selector
  _items: (selector, options = {}) ->
    @find ItemCollection, selector
  _payment: (selector = @payments) ->
    @findOne PaymentCollection, selector
  _payments: (selector, options = {}) ->
    @find PaymentCollection, selector
  _usage: (selector = @usage) ->
    @findOne UsageCollection, selector
  _usages: (selector, options = {}) ->
    @find UsageCollection, selector
  add: (Collection, document) ->
    extendedDocument = _.extend _(document).clone(), 
      scenario: @scenario or @_id
    _id = Collection.insert extendedDocument
    extendedDocument._id = _id
    @findOne(Collection, _id) 
  update: (Collection, document, _id = document._id) ->
    throw new Error("Trying to update '#{@constructor.name}' without `_id`") unless _id?
    Collection.update _id, _(document).omit '_id'
  remove: (Collection, _id) ->
    Collection.remove(_id)
  _fromAccount: ->
    @_account @fromAccount
  _toAccount: ->
    @_account @toAccount

class finances.Scenario extends finances.Base
  addAccount: (document) ->
    new finances.Account @add AccountCollection, document
  addItem: (document) ->
    document.amount = parseInt document.amount
    new finances.Item @add ItemCollection, document
  addPayment: (document) ->
    new finances.Payment @add PaymentCollection, document
  addUsage: (document) ->
    new finances.Usage @add UsageCollection, document
  updateAccount: (document) ->
    @update AccountCollection, document
  updateItem: (document) ->
    @update ItemCollection, document
  updatePayment: (document) ->
    @update PaymentCollection, document
  updateUsage: (document) ->
    @update UsageCollection, document
  removeAccount: (_id) ->
    @remove AccountCollection, _id
  removeItem: (_id) ->
    @remove ItemCollection, _id
  removePayment: (_id) ->
    @remove PaymentCollection, _id
  removeUsage: (_id) ->
    @remove UsageCollection, _id 
  addOrIncreasePayment: (attributes) ->
    payment = @_payment 
      fromAccount: attributes.fromAccount
      toAccount: attributes.toAccount

    if payment
      log.write "increase #{(new Payment payment).toString()} by $#{attributes.amount}"
      if attributes.amount
        payment.amount += attributes.amount
      if attributes.items?
        payment.items.concat attributes.items
      @updatePayment payment
      payment
    else
      @addPayment attributes
  addInternalPayments: ->
    @_items().forEach (item) =>
      users = []
      @_usages(item: item._id).forEach (usage) =>
        user = @_account(usage.fromAccount)
        users.push(user) if user?
        undefined
      @_payments(items: item._id, settled: true).forEach (p) =>
        for user in users when user._id isnt p.fromAccount
          @addOrIncreasePayment
            amount: item.amount / users.length
            items: [item._id]
            toAccount: p.fromAccount
            fromAccount: user._id
            settled: false
        undefined
      undefined
    undefined
  simplifyPayments: ->
    # Simplify the payment graph as much as
    # possible without changing the ultimate
    # flow of $$$.
    #
    # Pseudo-code for a general solution:
    # The => symbol represents a payment between two accounts
    # Arithmetic operations with payments are performed with payment amounts
    # Assignment operations create payments if none existed previously
    #
    #
    # For each A1 => A2
    #   If A2 => A3
    #     If A1 => A2 > A2 => A3
    #       (A1 => A3) += (A1 => A2) - (A2 => A3)
    #       (A1 => A2) -= (A1 => A3)
    #       (A2 => A3) = 0
    #     Else If A1 => A2 < A2 => A3
    #       (A1 => A3) += (A2 => A3) - (A1 => A2)
    #       (A2 => A3) -= (A1 => A3)
    #       (A1 => A2) = 0
    #     Else If A1 => A2 is A2 => A3
    #       (A1 => A3) = (A1 => A2)
    #       (A1 => A2) = (A2 => A3) = 0

    # Implemenation:

    @_payments(settled: false, {sort: ['amount', 'asc']}).forEach (p) =>
      @_payments(settled: false, fromAccount: p.toAccount).forEach (p2) =>
        log.write """#{
          @_account(p.fromAccount).name
        } owes $#{
          p.amount
        } to #{
          @_account(p.toAccount).name
        } and #{
          @_account(p2.fromAccount).name
        } owes $#{
          p2.amount
        } to #{
          @_account(p2.toAccount).name
        }"""

        if p.amount is p2.amount
          if p.fromAccount isnt p2.toAccount
            log.write "redirect #{(new Payment p).toString()} to #{@_account(p2.toAccount).name}"
            p.toAccount = p2.toAccount
            @updatePayment p
          else
            log.write "delete #{(new Payment p).toString()}"
            @removePayment p._id
            p.settled = true
          log.write "delete #{(new Payment p).toString()}"
          @removePayment p2._id
          p2.settled = true
        else
          minflow = Math.min(p.amount, p2.amount)

          if p.fromAccount isnt p2.toAccount
            newp = @addOrIncreasePayment
              fromAccount: p.fromAccount
              toAccount: p2.toAccount
              amount: minflow
              settled: false
          
          if p.amount > p2.amount
            larger = p
            smaller = p2
          else
            larger = p2
            smaller = p

          if larger.amount > minflow
            log.write "decrease #{(new Payment larger).toString()} by $#{minflow}"
            larger.amount -= minflow
            @updatePayment larger
          else
            log.write "delete #{(new Payment larger).toString()}"
            @removePayment larger._id
            larger.settled = true
          log.write "delete #{(new Payment smaller).toString()}"
          @removePayment smaller._id
          smaller.settled = true

    undefined

class finances.Item extends finances.Base
  clone: (name) ->
    @add ItemCollection, name: name, amount: @amount

class finances.Account extends finances.Base
  addPayment: (document) ->
    new finances.Payment @add PaymentCollection, document
  addUsage: (document) ->
    new finances.Usage @add UsageCollection, document
  pays: (item, percent = 100) ->
    @addPayment
      items: [item._id]
      percent: percent
      fromAccount: @_id
      settled: true
      amount: @_item(item).amount
  uses: (item) ->
    @addUsage
      item: item._id
      fromAccount: @_id
  paysAndUses: (item, percent = 100) ->
    @pays(item, percent)
    @uses(item)
  crunch: ->
    total = 0
    @_payments(fromAccount: @_id, settled: false).forEach (p) ->
      log.write "include in total #{(new Payment p).toString()}"
      total += p.amount
    total: total

Payment =
class finances.Payment extends finances.Base
  vivifyAssociates: ->
    @fromAccount = @_account @fromAccount
    @toAccount = @_account @toAccount
    @items = 
    for item in @items
      @_item item
    this
  addItem: (document) ->
    @amount += document.amount
    @items.push document._id
  toString: ->
    """#{
    if @settled
      ''
    else
      'unsettled '
    }payment from #{
      @_fromAccount().name
    } to #{
      @_toAccount()?.name
    } for #{
      @_item()?.name
    } ($#{
      @amount
    })"""

class finances.Usage extends finances.Base
  vivifyAssociates: ->
    @fromAccount = @_account @fromAccount
    @item = @_item @item
    this

_.extend finances,
  getPRNG: (seed) ->
    (min, max) ->
      x = Math.sin(seed++) * 10000
      r = x - Math.floor(x)
      Math.round r * (max - min) + min
  testScenario: (seed, scenario) ->
    random = @getPRNG(seed)
    totalPayments = 0

    nUsers = random(2, 10)
    nPayers = random(2, 10)

    nAccounts = do ->
      min = Math.max(nUsers, nPayers)
      random(min, nUsers + nPayers)
    nItems = random(Math.max(nUsers, nPayers), nAccounts * 3)

    accounts =
      for i in [1..nAccounts]
        scenario.addAccount name: "account #{i}"
    items =
      for i in [1..nItems]
        scenario.addItem
          name: "item #{i}"
          amount: random(2, 100)

    payments = []
    for index, item of items
      payments.push accounts[index % nPayers].pays item
      accounts[accounts.length - 1 - index % nUsers].uses item
      totalPayments += item.amount
    

    totalPayments: totalPayments
    accounts: accounts
    items: items
    payments: payments
