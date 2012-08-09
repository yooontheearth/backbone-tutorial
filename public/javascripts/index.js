(function() {
  var AppRouter, Busho, BushoList, DetailsView, HeaderView, ListItemView, ListView, app;

  app = null;

  $(document).ready(function() {
    app = new AppRouter();
    return Backbone.history.start();
  });

  AppRouter = Backbone.Router.extend({
    routes: {
      'busho/add': 'add',
      'busho/:id': 'details',
      'refresh': 'list',
      '': 'closeDetails'
    },
    initialize: function() {
      this.list = new BushoList();
      this.list.reset(_bushoList);
      this.listView = new ListView({
        model: this.list
      });
      $('#list').html(this.listView.render().el);
      return $('#header').html(new HeaderView().render().el);
    },
    add: function() {
      if (this.detailsView) {
        this.detailsView.close();
      }
      this.detailsView = new DetailsView({
        model: new Busho(),
        hideDelete: true
      });
      return $('#details').html(this.detailsView.render().el);
    },
    details: function(id) {
      var busho;
      if (this.detailsView) {
        this.detailsView.close();
      }
      busho = this.list.get(id);
      this.detailsView = new DetailsView({
        model: busho
      });
      return $('#details').html(this.detailsView.render().el);
    },
    list: function() {
      return this.list.fetch();
    },
    closeDetails: function() {
      if (this.detailsView) {
        return this.detailsView.close();
      }
    }
  });

  Busho = Backbone.Model.extend({
    urlRoot: 'busho',
    defaults: {
      id: null,
      name: null,
      description: null,
      imageUrl: null
    },
    initialize: function() {
      this.on('error', this.failOnValidation);
      return this.on('destroy', this.close);
    },
    validate: function(attrs) {
      if (!(attrs.name != null) || attrs.name.length === 0) {
        return '名称は必須です';
      }
    },
    failOnValidation: function(model, error) {
      return alert(error);
    },
    close: function() {
      return this.off();
    }
  });

  BushoList = Backbone.Collection.extend({
    model: Busho,
    url: 'list'
  });

  ListView = Backbone.View.extend({
    tagName: 'table',
    initialize: function() {
      var _this = this;
      this.model.bind('reset', this.render, this);
      return this.model.bind('add', function(busho) {
        return $(_this.el).append(new ListItemView({
          model: busho
        }).render().el);
      });
    },
    render: function() {
      $(this.el).empty();
      _.each(this.model.models, function(busho) {
        return $(this.el).append(new ListItemView({
          model: busho
        }).render().el);
      }, this);
      return this;
    }
  });

  ListItemView = Backbone.View.extend({
    tagName: 'tr',
    template: _.template($('#tpl-list-item').html()),
    initialize: function() {
      this.model.bind('change', this.render, this);
      return this.model.bind('destroy', this.close, this);
    },
    render: function() {
      $(this.el).html(this.template(this.model.toJSON()));
      return this;
    },
    events: {
      'click td': 'select'
    },
    select: function() {
      $('tr.selected').removeClass('selected');
      $(this.el).addClass('selected');
      return app.navigate("busho/" + this.model.id, true);
    },
    close: function() {
      return $(this.el).off().remove();
    }
  });

  DetailsView = Backbone.View.extend({
    template: _.template($('#tpl-details').html()),
    initialize: function() {
      return this.model.bind('change', this.render, this);
    },
    render: function() {
      $(this.el).html(this.template(this.model.toJSON()));
      if (this.options.hideDelete) {
        $(this.el).find('#delete').hide();
      }
      return this;
    },
    events: {
      'change input,textarea': 'changeData',
      'click #save': 'save',
      'click #delete': 'delete'
    },
    changeData: function(event) {
      var changeDataSet;
      changeDataSet = {};
      changeDataSet[event.target.name] = event.target.value;
      return this.model.set(changeDataSet, {
        silent: true
      });
    },
    save: function() {
      var _this = this;
      if (this.model.isNew()) {
        app.list.create(this.model, {
          wait: true,
          success: function(model, response) {
            _this.model.set('id', app.list.length);
            return app.navigate('', true);
          },
          error: function(model, error) {
            return alert(error.responseText ? error.responseText : error);
          }
        });
      } else {
        this.model.save({}, {
          success: function(model, response) {},
          error: function(model, error) {
            return alert(error.responseText ? error.responseText : error);
          }
        });
      }
      return false;
    },
    "delete": function() {
      if (!confirm('削除しますか？')) {
        return false;
      }
      this.model.destroy({
        success: function() {
          return app.navigate('', true);
        }
      });
      return false;
    },
    close: function() {
      return $(this.el).off().empty();
    }
  });

  HeaderView = Backbone.View.extend({
    template: _.template($('#tpl-header').html()),
    render: function() {
      $(this.el).html(this.template());
      return this;
    },
    events: {
      'click #refresh': 'refresh',
      'click #add': 'add'
    },
    refresh: function() {
      app.navigate('refresh', true);
      return false;
    },
    add: function() {
      app.navigate('busho/add', true);
      return false;
    }
  });

}).call(this);
