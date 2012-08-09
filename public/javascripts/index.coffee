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
						# ※fetch({data: {page: 3}}) のような形でQueryStringを渡せるのでページングなどもfetchで行える
	closeDetails:->
		@detailsView.close() if @detailsView	# 詳細ビューが開いていたら閉じる

# 武将モデル
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
			return '名称は必須です'			# 検証に失敗した場合はメッセージを返す
	failOnValidation: (model, error) -> alert error		# 検証に失敗した場合のイベントハンドリング
	close: ->
		@off()

# 武将モデルコレクション
BushoList = Backbone.Collection.extend
	model: Busho	# createを呼び出す場合はmodelの指定は必須
	url: 'list'		# fetchするときのリクエスト先

# リストビュー
ListView = Backbone.View.extend
	tagName: 'table'
	initialize: ->
		# modelはBushoListなのでBushoListが変更されたときに備えてイベント登録
		@model.bind 'reset', @render, this
		@model.bind 'add', (busho)=>
			$(@el).append new ListItemView(model:busho).render().el		# tableに新しい行を追加する
	render: ->
		$(@el).empty()
		_.each @model.models, (busho) ->		# BushoListの内容をtableに行として追加する
			$(@el).append new ListItemView(model:busho).render().el
		, this
		return this

# リストビューアイテム
ListItemView = Backbone.View.extend
	tagName: 'tr'
	template: _.template $('#tpl-list-item').html()
	initialize: ->
		# modelはBushoなのでBusho情報が変更されたときに備えてイベント登録
		@model.bind 'change', @render, this
		@model.bind 'destroy', @close, this
	render: ->
		$(@el).html @template @model.toJSON()
		return this
	events:
		'click td':'select'		# 行が選択された処理をフックするためにUI要素のイベント登録を行う
	select: ->
		$('tr.selected').removeClass('selected')
		$(@el).addClass('selected')
		app.navigate "busho/#{@model.id}", true		# 詳細情報を表示するためにルーターに通知する
	close: ->
		$(@el).off().remove()

# 詳細情報画面
DetailsView = Backbone.View.extend
	template: _.template $('#tpl-details').html()
	render: ->
		$(@el).html @template @model.toJSON()
		$(@el).find('#delete').hide() if @options.hideDelete
		return this
	events:
		'change input,textarea':'changeData'	# UI要素に入力された情報をモデルに反映するためのイベントハンドリング
		'click #save':'save'
		'click #delete':'delete'
	changeData:(event)->
		# changeイベントでデータを必ずしも反映させる必要はなく、アプリの要件によっては保存ボタン押下時などにまとめて行っても良い
		changeDataSet = {}
		changeDataSet[event.target.name] = event.target.value
		@model.set changeDataSet, silent:true		# silent:trueで検証を無効化している
	save: ->
		if @model.isNew()	# 新規登録時はリストに追加する
			app.list.create @model,
				wait:true
				success: (model, response) =>
					@model.set 'id', app.list.length # IDの採番は適当。本来ならばサーバからのレスポンスにIDを渡しておいて設定するとか
					app.navigate '', true
				error:(model, error)->		# サーバサイドでのエラーはresponseTextを参照、それ以外はクライアントでの検証エラー
					alert if error.responseText then error.responseText else error
		else
			@model.save {},
				success: (model, response) ->
					# とくに処理なし
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

# ヘッダービュー
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
