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

@finances ?= 
  concatNames: (list, separator = '/') ->
    (o.name for o in list).join(separator)
  buildArithmaticExpression: (addends = [], subtrahends = []) ->
    addendCount = {}
    subtrahendCount = {}
    for addend in addends
      addendCount[addend.name] ?= 0
      addendCount[addend.name] += 1
    for subtrahend in subtrahends
      subtrahendCount[subtrahend.name] ?= 0
      subtrahendCount[subtrahend.name] += 1
    addendExpression = (
      for own name, count of addendCount
        "#{name}"
    ).join '+'
    subtrahendExpression = (
      for own name, count of subtrahendCount
        "#{name}"
    ).join '-'
    "#{
      if addendExpression.length
        addendExpression
      else
        ''
    }#{
      if subtrahendExpression.length
        "-#{subtrahendExpression}"
      else
        ''
    }"


pstr = (doc) ->
  (new finances.Payment doc).toString()
istr = (doc) ->
  (new finances.Item doc).toString()
astr = (doc) ->
  (new finances.Account doc).toString()
ustr = (doc) ->
  (new finances.Usage doc).toString()

if not _?
  _ = Package?.underscore._

class finances.Base
  constructor: (doc) ->
    _.extend this, doc 
  findOne: (Collection, selector, options) ->
    extendedSelector = _.extend _(selector or {}).clone(),
      scenario: @scenario or @_id
    Collection.findOne extendedSelector, options
  find: (Collection, selector = {}, options = {}) ->
    extendedSelector = _.extend _(selector).clone(),
      scenario: @scenario or @_id
    Collection.find(extendedSelector, options)
  _scenario: (selector = @scenario, options = {}) ->
    @findOne ScenarioCollection, selector, options
  _account: (selector = @account, options = {}) ->
    @findOne AccountCollection, selector, options
  _accounts: (selector, options = {}) ->
    @find AccountCollection, selector, options
  _item: (selector = @item, options = {}) ->
    @findOne ItemCollection, selector, options
  _items: (selector, options = {}) ->
    @find ItemCollection, selector, options
  _payment: (selector = @payments, options = {}) ->
    @findOne PaymentCollection, selector, options
  _payments: (selector, options = {}) ->
    @find PaymentCollection, selector, options
  _usage: (selector = @usage, options = {}) ->
    @findOne UsageCollection, selector, options
  _usages: (selector, options = {}) ->
    @find UsageCollection, selector, options
  add: (Collection, document) ->
    extendedDocument = _.extend _(document).clone(), 
      scenario: @scenario or @_id
    _id = Collection.insert extendedDocument
    extendedDocument._id = _id
    @findOne(Collection, _id) 
  update: (Collection, document, _id = document._id) ->
    throw new Error("Trying to update '#{@constructor.name}' without `_id`") unless _id?
    Collection.update _id, $set: _(document).omit '_id'
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

    if payment?
      log.write "combine #{pstr(attributes)} with existing #{pstr(payment)}"
      if attributes.amount?
        payment.amount += attributes.amount
      if attributes.addItems?
        payment.addItems = payment.addItems.concat attributes.addItems
      if attributes.minusItems?
        payment.minusItems = (payment.minusItems or []).concat attributes.minusItems
      @updatePayment payment
      payment
    else
      log.write "add #{pstr(attributes)}"
      @addPayment attributes
    
  addInternalPayments: ->
    console.count('addInternalPayments')
    @_items().forEach (item) =>
      users = []
      @_usages(item: item._id).forEach (usage) =>
        user = @_account(usage.fromAccount)
        users.push(user) if user?
        undefined
      @_payments(addItems: item._id, settled: true).forEach (p) =>
        for user in users when user._id isnt p.fromAccount
          @addOrIncreasePayment
            amount: p.amount / users.length
            addItems: [item._id]
            toAccount: p.fromAccount
            fromAccount: user._id
            settled: false
        undefined
      undefined
    undefined
  simplifyPayments: ->
    console.count('simplifyPayments')
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
        return if p.obviated or p2.obviated
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
            log.write "redirect #{pstr p} to #{@_account(p2.toAccount).name}"
            p.toAccount = p2.toAccount
            @updatePayment p
          else
            log.write "delete loopback: #{pstr p}"
            p.obviated = true
            @updatePayment p
          log.write "delete 2nd equal edge: #{pstr p2}"
          p2.obviated = true
          @updatePayment p2
        else
          if p.amount > p2.amount
            larger = p
            smaller = p2
          else
            larger = p2
            smaller = p

          minflow = smaller.amount

          if p.fromAccount isnt p2.toAccount
            @addOrIncreasePayment
              fromAccount: p.fromAccount
              addItems: p.addItems
              minusItems: p.minusItems
              toAccount: p2.toAccount
              amount: minflow
              settled: false
          
          log.write "decrease larger #{pstr larger} by $#{minflow}"
          larger.amount -= minflow
          larger.minusItems = (larger.minusItems or []).concat smaller.addItems
          larger.addItems = larger.addItems.concat (smaller.minusItems or [])
          @updatePayment larger
          log.write "delete smaller #{pstr smaller}"
          smaller.obviated = true
          @updatePayment smaller

    @_payments(obviated: true).forEach (p) =>
      @removePayment p._id

    undefined

class finances.Item extends finances.Base
  clone: (name) ->
    @add ItemCollection, name: name, amount: @amount
  toString: ->
    "#{@name} ($#{@amount})"


class finances.Account extends finances.Base
  addPayment: (document) ->
    new finances.Payment @add PaymentCollection, document
  addUsage: (document) ->
    new finances.Usage @add UsageCollection, document
  pays: (item, amount) ->
    log.write "#{@toString()} pays $#{amount} for #{istr(item)}"
    @addPayment
      addItems: [item._id]
      fromAccount: @_id
      settled: true
      amount: amount or item.amount
  uses: (item) ->
    log.write "#{@toString()} uses #{istr(item)}"
    @addUsage
      item: item._id
      fromAccount: @_id
  paysAndUses: (item, amount) ->
    @pays(item, amount)
    @uses(item)
  # TODO: deprecate
  crunch: ->
    total = 0
    @_payments(fromAccount: @_id, settled: false).forEach (p) ->
      log.write "include in total #{pstr(p)}"
      total += p.amount
    total: total
  toString: ->
    @name
  
Payment =
class finances.Payment extends finances.Base
  vivifyAssociates: ->
    @fromAccount = @_account @fromAccount
    @toAccount = @_account @toAccount
    @addItems = @fetchItems @addItems
    @minusItems = @fetchItems @minusItems
    this
  addItem: (document) ->
    @amount += document.amount
    @addItems.push document._id
  fetchItems: (items = []) ->
    for item in items
      @_item item
  toString: ->
    """#{
    if @settled
      ''
    else
      'unsettled '
    }payment of $#{@amount} from #{
      @_fromAccount().name
    } to #{
      @_toAccount()?.name
    } for #{
      finances.buildArithmaticExpression(@fetchItems(@addItems), @fetchItems(@minusItems))
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
  testScenario: (seed) ->
    console.count('testScenario')
    scenario = new finances.Scenario 
      name: "test ##{seed}"
      _id: "#{seed}"
    random = @getPRNG(seed)
    totalPayments = 0

    nAccounts = random(2, 4)
    nUsers = random(1, nAccounts)
    nPayers = random(1, nAccounts)

    nItems = random(nPayers * 0.1, nPayers * 1)

    console.debug 'nAccounts',nAccounts,'nItems',nItems

    accounts =
    for i in [1..nAccounts]
      scenario.addAccount name: "account #{i}"

    items = 
    for i in [1..nItems]
      scenario.addItem
        name: "item #{i}"
        amount: random(1, 100/24) * 24

    for own index, item of items
      nPayersPerItem = Math.min Math.ceil(nAccounts/nItems), accounts.length - index - 1
      for groupIndex in [0...nPayersPerItem] 
        payerIndex = index % nPayers + groupIndex
        userIndex = accounts.length - 1 - (index + groupIndex) % nUsers
        accounts[payerIndex].pays item, item.amount / nPayersPerItem
        accounts[userIndex].uses item

    scenario
