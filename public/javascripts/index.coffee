app = null
$(document).ready ->
	app = new AppRouter()
	Backbone.history.start()

AppRouter = Backbone.Router.extend
	routes:
		'busho/add':'add'
		'busho/:id':'details'
		'refresh':'list'
		'':'closeDetails'
	initialize: ->
		@list = new BushoList()
		@list.reset _bushoList	# 初期表示するデータはページロード時に用意してあるのでそちらから取得
		@listView = new ListView model:@list
		$('#list').html @listView.render().el
		$('#header').html new HeaderView().render().el	# ヘッダービューをDOMツリーに反映
	add:->
		@detailsView.close() if @detailsView
		@detailsView = new DetailsView
			model:new Busho()
			hideDelete:true		# 追加なので削除ボタンは不要
		$('#details').html @detailsView.render().el		# 詳細ビューをDOMツリーに反映
	details:(id)->
		@detailsView.close() if @detailsView
		busho = @list.get id	# リストから詳細を表示するアイテムを取得
		@detailsView = new DetailsView model:busho
		$('#details').html @detailsView.render().el		# 詳細ビューをDOMツリーに反映
	list:->
		@list.fetch()	# リストの更新
						# ※fetch({data: {page: 3}}) のような形でQueryStringを渡せるのでページングなどもここで行える
	closeDetails:->
		@detailsView.close() if @detailsView	# 詳細ビューが開いていたら閉じる

Busho = Backbone.Model.extend
	urlRoot: 'busho'	# Bushoモデルがサーバへのリクエストを行うときの基本となる部分の指定
	defaults:		# templateで使用するプロパティがundefinedだとエラーになるので初期値を設定しておく
		id:null
		name:null
		description:null
		imageUrl:null
	initialize: ->
		@on 'error', @failOnValidation
		@on 'destroy', @close
	validate: (attrs) ->
		if not attrs.name? or attrs.name.length == 0
			return '名称は必須です'	# 検証に失敗した場合はメッセージを返す
	failOnValidation: (model, error) -> alert error		# 検証に失敗した場合のイベントハンドリング
	close: ->
		@off()

BushoList = Backbone.Collection.extend
	model: Busho
	url: 'list'

ListView = Backbone.View.extend
	tagName: 'table'
	initialize: ->
		@model.bind 'reset', @render, this
		@model.bind 'add', (busho)=>
			$(@el).append new ListItemView(model:busho).render().el
	render: ->
		$(@el).empty()
		_.each @model.models, (busho) ->
			$(@el).append new ListItemView(model:busho).render().el
		, this
		return this

ListItemView = Backbone.View.extend
	tagName: 'tr'
	template: _.template $('#tpl-list-item').html()
	initialize: ->
		@model.bind 'change', @render, this
		@model.bind 'destroy', @close, this
	render: ->
		$(@el).html @template @model.toJSON()
		return this
	events:
		'click td':'select'
	select: ->
		$('tr.selected').removeClass('selected')
		$(@el).addClass('selected')
		app.navigate "busho/#{@model.id}", true
	close: ->
		$(@el).off().remove()

DetailsView = Backbone.View.extend
	template: _.template $('#tpl-details').html()
	initialize: ->
		@model.bind 'change', @render, this
	render: ->
		$(@el).html @template @model.toJSON()
		$(@el).find('#delete').hide() if @options.hideDelete
		return this
	events:
		'change input,textarea':'changeData'
		'click #save':'save'
		'click #delete':'delete'
	changeData:(event)->
		changeDataSet = {}
		changeDataSet[event.target.name] = event.target.value
		@model.set changeDataSet, silent:true
	save: ->
		if @model.isNew()
			app.list.create @model,
				wait:true
				success: (model, response) =>
					@model.set 'id', app.list.length # 適当
					app.navigate '', true
				error:(model, error)->
					alert if error.responseText then error.responseText else error
		else
			@model.save {},
				success: (model, response) ->
					#
				error: (model, error) ->
					alert if error.responseText then error.responseText else error
		return false
	delete: ->
		return false unless confirm '削除しますか？'
		@model.destroy
			success: ->
				app.navigate '', true
		return false
	close: ->
		$(@el).off().empty()

HeaderView = Backbone.View.extend
	template: _.template $('#tpl-header').html()
	render: ->
		$(@el).html @template()
		return this
	events:
		'click #refresh':'refresh'
		'click #add':'add'
	refresh: ->
		app.navigate 'refresh', true
		return false
	add: ->
		app.navigate 'busho/add', true
		return false
