express = require 'express'
stylus = require 'stylus'
app = express.createServer()

app.configure ->
	app.use express.logger('tiny')
	app.set 'views', __dirname + '/views'
	app.set 'view engine', 'jade'
	app.set 'view options', {layout:false}
	app.use express.bodyParser()
	app.use express.methodOverride()
	app.use app.router
	app.use stylus.middleware({src: __dirname + '/public'})
	app.use express.compiler(src: __dirname + '/public', dest: __dirname + '/public', enable: ['coffeescript'])
	app.use express.static(__dirname + '/public')
	app.use express.errorHandler({ dumpExceptions: true, showStack: true })

bushoList = [
	{id:1, name:'山中鹿介', description:'戦国時代から安土桃山時代にかけての山陰地方の武将。出雲国能義郡（現在の島根県安来市広瀬町）に生まれる[2]。戦国大名尼子氏の家臣。実名は幸盛（ゆきもり）、幼名は甚次郎（じんじろう）。優れた武勇の持ち主で「山陰の麒麟児」の異名を取る。', imageUrl:'http://ec2.images-amazon.com/images/I/51-TNOTqi8L._SL500_AA300_.jpg'},
	{id:2, name:'秋宅庵助', description:'戦国時代から安土桃山時代にかけての武将。尼子氏の家臣。通称は伊織介。父は秋上綱平、叔父に秋上孝重。'},
	{id:3, name:'寺本生死助'},
	{id:4, name:'尤道理助'},
	{id:5, name:'今川鮎助'},
	{id:6, name:'藪中荊助' },
	{id:7, name:'横道兵庫助', description:'戦国時代から安土桃山時代にかけての武将。尼子氏の家臣。通称は兵庫介（ひょうごのすけ）。秀綱・政光とも表記する。' },
	{id:8, name:'五月早苗助' },
	{id:9, name:'植田稲葉助' },
	{id:10, name:'尼子勝久', description: '戦国時代から安土桃山時代にかけての武将。尼子誠久の五男。', imageUrl:'http://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Amago_Katsuhisa.jpg/240px-Amago_Katsuhisa.jpg' }
]

app.get '/index', (req, res) ->
					res.render 'index',
						locals:
							title: '尼子十勇士'
							bushoList: bushoList
app.get '/list', (req, res) ->
					# 永続化機構からデータの取得を行う
					res.json bushoList
app.post '/busho', (req, res) ->
						# アイテム追加の永続化処理
						res.end()
app.put '/busho/:id', (req, res) ->
 						# アイテム更新の永続化処理
						res.end()
app.delete '/busho/:id', (req, res) ->
						# アイテム削除の永続化処理
						res.end()

app.listen 3000
console.log "Express server listening on port #{app.address().port} in #{app.settings.env} mode"