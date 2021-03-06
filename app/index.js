// Generated by CoffeeScript 1.9.3
(function() {
  var generators;

  generators = require('yeoman-generator');

  module.exports = generators.Base.extend({
    constructor: function() {
      generators.Base.apply(this, arguments);
      this.option('coffee');
      ({
        prompting: function() {
          return this.prompt([
            {
              type: 'input',
              name: 'auth0-domain',
              message: 'Your Auth0 domain (like foo.eu.auth0.com)',
              "default": ''
            }, {
              type: 'input',
              name: 'auth0clientid',
              message: 'Your Auth0 Client ID (like 7Jkc0g5Kr5VTA0x76632XxifzboO0wa1)',
              "default": ''
            }, {
              type: 'input',
              name: 'dbtype',
              message: 'Which database to use for storage (mongodb, rethinkdb or google)',
              "default": 'mongodb'
            }, {
              type: 'input',
              name: 'adminemail',
              message: 'The email address of the first admin user',
              "default": ''
            }
          ]).then((function(_this) {
            return function(answers) {
              return _this.log('app name', answers.name);
            };
          })(this));
        },
        install: function() {},
        writing: function() {
          return this.fs.copyTpl(this.templatePath('index.html'), this.destinationPath('public/index.html'), {
            title: this.appname
          });
        }
      });
      this.argument('appname', {
        type: String,
        required: true
      });
      return this.appname = _.camelCase(this.appname);
    }
  });

}).call(this);

//# sourceMappingURL=index.js.map
