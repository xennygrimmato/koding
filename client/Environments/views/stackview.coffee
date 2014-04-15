class StackView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'environment-stack', options.cssClass

    super options, data

    @bindTransitionEnd()

  viewAppended:->

    @createHeaderElements()

    # Main scene for DIA
    @addSubView @scene = new EnvironmentScene @getData().stack

    # Rules Container
    @rules = new EnvironmentRuleContainer
    @scene.addContainer @rules

    # Domains Container

    @domains = new EnvironmentDomainContainer { delegate: this }
    @scene.addContainer @domains
    @domains.on 'itemAdded', @lazyBound 'updateView', yes

    # VMs / Machines Container
    stackId = @getOptions().stack.getId?()
    @vms    = new EnvironmentMachineContainer { stackId }
    @scene.addContainer @vms

    KD.getSingleton("vmController").on 'VMListChanged', =>
      EnvironmentDataProvider.get (data) => @loadContainers data

    # Rules Container
    @extras = new EnvironmentExtraContainer
    @scene.addContainer @extras

    @loadContainers()

  loadContainers: (data)->

    env     = data or @getData()
    orphans = domains: [], vms: []
    {stack, isDefault} = @getOptions()

    # Add rules
    @rules.removeAllItems()
    @rules.addItem rule  for rule in env.rules

    # Add domains
    @domains.removeAllItems()
    for domain in env.domains
      if domain.stack is stack.getId() or (isDefault and not domain.stack)
        @domains.addDomain domain
      else
        orphans.domains.push domain

    # Add vms
    @vms.removeAllItems()
    for vm in env.vms
      if vm.stack is stack.getId() or (isDefault and not vm.stack)
        vm.title = vm.hostnameAlias
        @vms.addItem vm
      else
        orphans.vms.push vm

    # Add extras
    @extras.removeAllItems()
    @extras.addItem extra  for extra in env.extras

    @setHeight @getProperHeight()
    KD.utils.wait 300, =>
      @_inProgress = no
      @updateView yes

  dumpStack:->
    dump = @getStackDump yes
    new KDModalView
      width    : 600
      overlay  : yes
      cssClass : 'recipe'
      title    : 'Stack recipe'
      content  : "<pre>#{dump}</pre>"

  getStackDump: (asYaml = no) ->
    {containers, connections} = @scene
    dump = {}

    for i, container of containers
      name = EnvironmentScene.containerMap[container.constructor.name]
      dump[name] = []
      for j, dia of container.dias
        dump[name].push \
          if name is 'domains'
            title   : dia.data.title
            aliases : dia.data.aliases
          else if name is 'vms'
            obj     =
              title : dia.data.title
            if dia.data.meta?.initScript
              obj.initScript = "[...]"
            obj
          else dia.data

    return if asYaml then jsyaml.dump dump else dump

  updateView:(dataUpdated = no)->

    @scene.updateConnections()  if dataUpdated

    if @getHeight() > 50
      @setHeight @getProperHeight()

    @scene.highlightLines()
    @scene.updateScene()

  getProperHeight:->
    (Math.max.apply null, \
      (box.diaCount() for box in @scene.containers)) * 45 + 170

  getMenuItems: ->
    items =
      'Show stack recipe'  :
        callback           : @bound "dumpStack"
      'Clone this stack'   :
        callback           : =>
          stackDump        = @getStackDump()
          stackDump.config = @getOptions().stack.meta?.config or ""
          @emit "CloneStackRequested", stackDump
      'Delete stack'       :
        callback           : @bound "confirmStackDelete"

    delete items['Delete stack']  if @getOptions().isDefault

    return items

  confirmStackDelete: ->
    stackMeta  = @getOptions().stack.meta or {}
    stackTitle = stackMeta.title or ""
    stackSlug  = stackMeta.slug  or "confirm"

    modal      = new VmDangerModalView
      name     : stackTitle
      action   : "DELETE MY STACK"
      title    : "Delete your #{stackTitle} stack"
      width    : 650
      content  : """
          <div class='modalformline'>
            <p><strong>CAUTION! </strong>This will destroy your #{stackTitle} stack including</strong>
            all VMs and domains inside this stack. You will also lose all your data in your VMs. This action <strong>CANNOT</strong> be undone.</p><br><p>
            Please enter <strong>#{stackSlug}</strong> into the field below to continue: </p>
          </div>
        """
      callback : =>
        modal.destroy()
        @deleteStack()
    , stackSlug

  deleteDomains: (callback = noop) ->
    domainDias    = @domains.dias
    domainDiaKeys = Object.keys domainDias
    domainCouter  = 0
    domainQueue   = domainDiaKeys.map (key) =>=>
      domainDias[key].data.domain.remove (err, res) =>
        domainCouter++
        domainQueue.next()
        @progressModal?.error()  if err
        @progressModal?.next()
        callback()  if domainCouter is domainDiaKeys.length

    Bongo.daisy domainQueue

  deleteVms: (callback = noop) ->
    vmc       = KD.getSingleton "vmController"
    vmDias    = @vms.dias
    vmDiaKeys = Object.keys vmDias
    vmCounter = 0
    vmQueue   = vmDiaKeys.map (key) =>=>
      vmc.deleteVmByHostname vmDias[key].data.hostnameAlias, (err) =>
        vmCounter++
        vmQueue.next()
        @progressModal?.next()
        @progressModal?.error()  if err
        callback()  if vmCounter is vmDiaKeys.length
      , no

    Bongo.daisy vmQueue

  deleteJStack: ->
    {stack} = @getOptions()
    stack.remove (err, res) =>
      return KD.showError err  if err
      @destroy()
      @progressModal?.destroy()

  deleteStack: ->
    hasDomain = Object.keys(@domains.dias).length
    hasVm     = Object.keys(@vms.dias).length

    @createProgressModal hasDomain, hasVm  if hasVm and hasDomain

    if hasDomain
      @deleteDomains =>
        if hasVm
          @deleteVms =>
            @deleteJStack()
        else
          @deleteJStack()
    else if hasVm
      @deleteVms =>
        @deleteJStack()
    else
      @deleteJStack()

  createProgressModal: (hasDomain, hasVm) ->
    listData = {}

    if hasDomain
      arr = listData["Deleting Domains"] = []
      for key, domain of @domains.dias
        arr.push domain.data.title

    if hasVm
      arr = listData["Deleting VMs"] = []
      for key, vm of @vms.dias
        arr.push vm.data.title

    @progressModal = new StackProgressModal {}, listData

  createHeaderElements: ->
    {stack} = @getOptions()
    group   = KD.getGroup().title
    title   = "#{stack.meta?.title or 'a'} stack on #{group}"

    @addSubView title = new KDView
      cssClass : 'stack-title'
      partial  : title

    @addSubView toggle = new KDButtonView
      title    : 'Hide details'
      cssClass : 'stack-toggle solid on clear stack-button'
      iconOnly : yes
      iconClass: 'toggle'
      callback : =>
        if @getHeight() <= 50
          @setHeight @getProperHeight()
          toggle.setClass 'on'
        else
          toggle.unsetClass 'on'
          @setHeight 48
        KD.utils.wait 300, @bound 'updateView'

    @addSubView context = new KDButtonView
      cssClass  : 'stack-context solid clear stack-button'
      style     : 'comment-menu'
      title     : ''
      iconOnly  : yes
      delegate  : this
      iconClass : "cog"
      callback  : (event)=>
        new KDContextMenu
          cssClass    : 'environments'
          event       : event
          delegate    : this
          x           : context.getX() - 138
          y           : context.getY() + 40
          arrow       :
            placement : 'top'
            margin    : 150
        , @getMenuItems()

    @addSubView configEditor = new KDButtonView
      cssClass  : "stack-editor solid clear stack-button"
      iconOnly  : yes
      iconClass : "editor"
      callback  : @bound "createConfigEditor"

  createConfigEditor: ->
    new EditorModal
      editor              :
        title             : "Stack Config Editor <span>(experimental)</span>"
        content           : @getOptions().stack.meta.config or ""
        saveMessage       : "Stack config saved."
        saveFailedMessage : "Couldn't save your config"
        saveCallback      : @bound "saveConfig"

  saveConfig: (config, modal) ->
    {stack} = @getOptions()

    stack.updateConfig config, (err, res) =>
      eventName = if err then "SaveFailed" else "Saved"
      modal.emit eventName
