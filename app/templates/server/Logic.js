// Generated by CoffeeScript 1.9.3
(function() {
  var DB, Logic, QPCity, QPDevice, QPProduct, QPSensor, QPSettings, QPToken, QPUser, ResolveModule, uuid,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  QPSettings = require('./QPSettings');

  QPUser = require('./User');

  QPCity = require('./QPCity');

  QPSensor = require('./QPSensor');

  QPToken = require('./QPToken');

  QPDevice = require('./QPDevice');

  QPProduct = require('./QPProduct');

  uuid = require('node-uuid');

  DB = require('spincycle').DB;

  ResolveModule = require('spincycle').ResolveModule;

  Logic = (function() {
    function Logic(messageRouter) {
      var types;
      this.messageRouter = messageRouter;
      this.onCreateToken = bind(this.onCreateToken, this);
      console.log('Logic  constructor called');
      this.messageRouter.addTarget('createToken', '<none>', this.onCreateToken);
      types = [
        {
          name: 'QPUser',
          module: QPUser
        }, {
          name: 'QPCity',
          module: QPCity
        }, {
          name: 'QPSensor',
          module: QPSensor
        }, {
          name: 'QPToken',
          module: QPToken
        }, {
          name: 'QPDevice',
          module: QPDevice
        }, {
          name: 'QPProduct',
          module: QPProduct
        }
      ];
      this.messageRouter.register(types).then((function(_this) {
        return function() {
          console.log('Type models registered in SpinCycle');
          return DB.getOrCreateObjectByRecord({
            id: 17,
            type: 'QPSettings'
          }).then(function(settings) {
            console.log('QPLogic found settings');
            console.dir(settings);
            _this.settings = settings;
            _this.messageRouter.authMgr.setQpSettings(settings);
            settings.serialize();
            return _this.messageRouter.open();
          });
        };
      })(this));
    }

    Logic.prototype.onCreateToken = function(msg) {
      return new QPToken({
        token: uuid.v4(),
        userRef: msg.user.id
      }).then((function(_this) {
        return function(token) {
          token.serialize();
          msg.user.tokens.push(token);
          msg.user.serialize();
          return msg.replyFunc({
            status: 'SUCCESS',
            info: 'new token generated',
            payload: token.toClient()
          });
        };
      })(this));
    };

    return Logic;

  })();

  module.exports = Logic;

}).call(this);

//# sourceMappingURL=Logic.js.map
