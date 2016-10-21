defer           = require('node-promise').defer
uuid            = require('node-uuid')
SuperModel      = require('spincycle').SuperModel

class QPUser extends SuperModel

  @type  = 'QPUser'
  @model =

    [
      { name: 'name',             public: true,   value: 'name', default: 'anonymous hero' }
      { name: 'organization',     public: true,   value: 'organization', default: 'qp' }
      { name: 'displayname',      public: true,   value: 'displayname', default: 'false' }
      { name: 'cdata',            public: true,   value: 'cdata',  default: {} }
      { name: 'admin',            public: true,   value: 'admin' , default: 'false'}
      { name: 'orgRef',           public: true,   value: 'orgRef' , default: '-1'}
      { name: 'providerId',       public: false,  value: 'providerId', default: 'false' }
      { name: 'profileUrl',       public: true,   value: 'profileUrl', default: 'false' }
      { name: 'picture',          public: true,   value: 'picture', default: 'false', image: true }
      { name: 'provider',         public: false,  value: 'provider', default: 'false' }
      { name: 'email',            public: true,   value: 'email', default: 'false' }
      { name: 'activation_code',  public: false,  value: 'activation_code', default: 'false' }
      { name: 'password',         public: false,  value: 'password', default: 'false' }
      { name: 'lastLogin',        public: true,   value: 'lastLogin', default: 0 }
      { name: 'nologins',         public: true,   value: 'nologins', default: 1 }
      { name: 'qpoints',          public: true,   value: 'qpoints', default: 0 }
      { name: 'tokens',           public: true,   array: true, type: 'QPToken', ids: 'tokens'}
      { name: 'devices',          public: true,   array: true, type: 'QPDevice', ids: 'devices'}
      { name: 'sensors',          public: true,   array: true, type: 'QPSensor', ids: 'sensors'}
    ]

  constructor: (@record={}) ->
    return super

module.exports = QPUser