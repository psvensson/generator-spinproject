generators = require('yeoman-generator')

module.exports = generators.Base.extend(constructor: -> # Calling the super constructor is important so our generator is correctly set up
  generators.Base.apply this, arguments  # Next, add your custom code
  @option 'coffee' # This method adds support for a `--coffee` flag

  prompting: ->
    @prompt(
      [
        {
          type: 'input'
          name: 'auth0-domain'
          message: 'Your Auth0 domain (like foo.eu.auth0.com)'
          default: ''
        },
        {
          type: 'input'
          name: 'auth0clientid'
          message: 'Your Auth0 Client ID (like 7Jkc0g5Kr5VTA0x76632XxifzboO0wa1)'
          default: ''
        },
        {
          type: 'input'
          name: 'dbtype'
          message: 'Which database to use for storage (mongodb, rethinkdb or google)'
          default: 'mongodb'
        },
        {
          type: 'input'
          name: 'adminemail'
          message: 'The email address of the first admin user'
          default: ''
        }
      ]).then (answers)=>
        this.log('app name', answers.name)

  install: ->

  writing: ->
    @fs.copyTpl @templatePath('index.html'), @destinationPath('public/index.html'), title: @appname


  @argument('appname', { type: String, required: true })
  @appname = _.camelCase(@appname)

)