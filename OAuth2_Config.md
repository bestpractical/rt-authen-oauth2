# NAME

RT::Authen::OAuth2 Configuration

# USER-CONFIGURABLE OPTIONS

- `$EnableOAuth2`

    Set this to enable the OAuth2 button on the login page.

        Set($EnableOAuth2, 1);

- `$OAuthCreateNewUser`

    Set this to enable auto-creating new users based on the OAuth2 data.

        Set($OAuthCreateNewUser, 1);

- `$OAuthNewUserOptions`

    Set additional options when auto-creating new users. Default creates users as Privileged.

    The default is to set `Privileged => 1`. Set `Privileged => 0` to create Unprivileged users.

        Set($OAuthNewUserOptions, {
                Privileged => 1,
            },
        );

    Example with other user options to pass to RT

        Set($OAuthNewUserOptions, {
                 Privileged => 1,
                 Organization => 'ACME Inc.',
                 Lang => 'en-gb',
            },
         );

- `%OAuthNewUserGroups`

    RT groups to always add new users to for each Identity Provider.

    This is useful if the Identity Provider does not support groups.

         Set(%OAuthNewUserGroups,
            'authentik' => [ 'IT Support', 'Sales' ],
            'google' => [ 'Customer' ],
        );

- `$OAuthIDP`

    Set this to the label of the Identity Provider endpoint you want to use.
    The list of IDPs is in the internal configuration option `OAuthIDPs`.
    Default is `'google'`.

        Set($OAuthIDP, 'google');

    **NOTE**: This extension currently only supports a single OAuth2 provider. Even though
    multiple providers can be configured, only one can be enabled.

    Hopefully a future version of this extension will allow multiple OAuth2 providers.

- `%MetadataMap`

    **NOTE**: This is a sub-key of `%OAuthIDPs`. Each IDP has a MetadataMap.

    This defines a mapping from the fields returned in the user's metadata, to
    fields needed by this extension in RT. The `EmailAddress` field is required,
    and is used (by default) to identify the user account in the RT database. It
    must match with the email returned by the Identity Provider.

- `%OAuthIDPSecrets` Client ID and Secret

    **REQUIRED**

    You must set the **Client ID** and **Client Secret** here. These are given
    to you by your Identity Provider.  Each endpoint can have its own set of
    secrets, so you must specify the endpoint name as found in the `%OAuthIDPs`
    internal config option.

    For Google, they are found in the developer console where you configure the
    OAuth login.

- `%OAuthIDPOptions`

    For convenience, any `%OAuthIDPs` options can (optionally) be added to `%OAuthIDPOptions` instead.

    This avoids changing the plugin's default `etc/OAuth_Config.pm` file, or copying entire `%OAuthIDPs`
    sections to your site config, only to change a couple of options.

    Any `%OAuthIDPOptions` options in your local RT\_SiteConfig configuration (e.g. `etc/RT_SiteConfig.d/RT-Authen-OAuth2.pm`).
    will replace any default `%OAuthIDPs` options supplied in the extention's `etc/OAuth_Config.pm` file,
    which should normally not be changed.

    Configure only those options you wish to add or change from the default `%OAuthIDPs`.

    `%OAuthIDPOptions` also provides a `default` section for settings which apply to all IDPs unless an option
    has been explicitly configured for that IDP.

    **NOTE**: `%OAuthIDPOptions` or `%OAuthIDPs` cannot be used to set `client_id` or `client_secret` - these
    must be configured in `OAuthIDPSecrets`.

    The following defaults are set by the extension's `OAuth2_Config.pm`:

        Set(%OAuthIDPOptions,
           'default' => {
               'MetadataHandler' => 'RT::Authen::OAuth2::Google',   
               'GroupUserOptions' => {
                   'NoGroup' => { Privileged => 0,
                                },
               },
               'GroupListName' => 'groups',
               'AllowLoginWithoutGroups' => 1,
               'CreateNoGroupUser' => 1,
               'LoginUpdateGroups' => 0,
               'RemoveRTPassword' => 0,
               'CreateUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang', 'EmailAddress' ],
               'LoginUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang' ],
               'Admins' = [ 'root' ],
               },
        );

    **NOTE**: You can also replace the `default` section by copying **the whole** `default' => {...}, ` section to your `RT_SiteConfig`.
    (The `default` section is not merged but can be replaced.)

    You can then add/change any `%OAuthIDPs` options in your local RT\_SiteConfig, e.g.
    `etc/RT_SiteConfig.d/RT-Authen-OAuth2.pm`:

        # Options for authentik:

        Set($OAuthIDP, 'authentik');
        Set($AuthentikHost, "auth.example.com");
        Set($AuthentikSlug, "rt");

        Set(%OAuthIDPSecrets,
            'authentik' => {
                client_id => '.....',
                client_secret => '.....',
            },
        );

        # Our IDP settings for authentik:

        Set(%OAuthIDPOptions,
           'authentik' => {
               'GroupMap' => {
                        'NoGroup' => [ 'Staff' ],
                        'ACME Engineering' => [ 'Customer Support', 'Engineering' ],
                        'ACME Support' => [ 'Customer Support' ],
                        'ACME Sales' => [ 'Sales' ],
                        'ACME Finance' => [ 'Accounts' ],
                        'ACME Management' => [ 'Sales', 'Customer Support', 'Accounts' ],
                        'IT Administrators' => [ 'RT Admins' ],
               },
               'GroupUserOptions' => {
                   'NoGroup' => { Privileged => 0,
                                  Organization => '',
                                },
               },
               'LoginUpdateFields' => [ 'NickName', 'Organization', 'Lang', 'EmailAddress' ],
               'RequireGroup' => 'GroupMap',
               'LoginUpdateGroups' => 1,
               'RemoveRTPassword' => 1,
            },
        );

    (See below for a more detailed description of these options)

    IDP config options are applied and inherited in the following order:

    - 1
    `%OAuthIDPs` in RT database or plugin core config `plugins/RT-Authen-OAuth2OAuth2_Config.pm`
    - 2
    `%OAuthIDPOptions` 'default' section in plugin core config (or if replaced in `RT_SiteConfig`).
    - 3
    `%OAuthIDPOptions` IDP section in site config, e.g. `etc/RT_SiteConfig.d/RT-Authen-OAuth2.pm`. Settings will replace any previous defaults.

    If you prefer, you can ignore this feature and simply copy `%OAuthIDPs` to your `RT_SiteConfig`
    (as before), but you must set (and maintain) **all** of the replaced config options even if they
    are the same as the supplied defaults.

    RT only merges "hash-style" configuration options for core and site config at the top level,
    not recursively.

    For example, if you set in your `RT_SiteConfig`:

        Set(%OAuthIDPs,
           'authentik' => {
            ...
              <your config options>,
            ...
            },
        );

    The `%OAuthIDPs` options for `authentik` will not be inherited from the plugin
    core config, but other IDP sections are retained. (e.g. `'google' = > { ... }` ).

# INTERNAL CONFIGURATION DEFAULTS

- `$OAuthRedirect`

    This parameter is used by the IdP provider to define where the results are
    returned. Typically (always?) this must match what is configured in the IdP,
    and the name and path of the template components that handle the request. You
    should never need to change this.

    This should be a full URI (see rfc6819 section 4.1.5). Note that you may not
    be able to use RT->Config->Get('WebURL') at this point in the configuration
    loading, so you may need to explicitly provide your WebURL.

        Set($OAuthRedirect, RT->Config->Get('WebURL') . 'NoAuth/OAuthRedirect');

- `$OAuthDebugToken`

    If an RT log level is set to debug, (e.g. `$LogToSyslog`) this option enables or disables
    debug logging of the OAuth access token received from the IDP.

    To avoid cluttering the logs or logging potentially sensitive information, OAuth token
    debug logging is disabled by default. (Usually only needed for debugging OAuth
    authentication issues or testing new Identity Provider setups.)

    This option can also be set for each IDP in `%OAuthIDPs`.

# SECURITY CONSIDERATIONS

- `%OAuthIDPSecrets`

    If your RT configuration files are backed up or stored in a repository, or you keep
    multiple repositories for testing or development, take care that your secrets are 
    not accidentally committed to a repository where they are visible to others.

    You may want to add `Set(%OAuthIDPSecrets, ...` to a separate RT\_SiteConfig.d file,
    then add this file to your .gitignore, for example.

- **LoadColumn** option

    **NOTE**: This is a sub-key of `%OAuthIDPs`. Each IDP has a `LoadColumn` option.

    `LoadColumn` is set per IDP in `%OAuthIDPs` (or `%OAuthIDPOptions`) and specifies which 
    field from `MetadataMap` to use as the RT username during user lookup or creation.

    If not set, `EmailAddress` might be used depending on the default IDP configuration 
    \- **but this may be insecure**.

    It is important to note: username and email address are **separate fields** and may 
    be editable in the IDP or in RT.

    If the IDP and RT usernames happen to be the same as the user's email address and the IDP
    supplies separate username and email address fields, **DO NOT** set `LoadColumn` 
    to `EmailAddress`.

    If the usernames in the IDP do not match your RT usernames, one option is to
    rename the RT usernames to match the IDP. This is more secure, but may not 
    be practical in some situations.

    Avoid setting `EmailAddress` unless the IDP does not provide a suitable field for 
    the username which is unique and unchangeable.

    It is safer to set `LoadColumn` to `Name` or another field users cannot change.
    Otherwise there is nothing to prevent a user from changing the email address in their 
    IDP profile and logging in to RT as any other user (possibly even your RT root/admin user!)

    **If you must use email addresses, ensure users CANNOT change their email address in the IDP.**

    For Authentik, set `goauthentik.io/user/can-change-email: false` in a group attribute (or elsewhere) 
    to prevent users changing their email address.

    Only set `LoadColumn` to `EmailAddress` if no other reliable username identifier exists, 
    and you are sure users cannot change their email address.

        'LoadColumn' => 'EmailAddress',

# UNIQUE EMAIL ADDRESS CONSTRAINT

RT requires email addresses to be unique across all users. Some IDPs allow multiple users to have 
the same email address. If your usernames are not email addresses, attempting to add a second 
user with the same email address as any existing RT user (enabled/privileged or otherwise) will fail.

# GROUP AND USER CONFIGURATION OPTIONS

If the IDP supports groups, the following additional settings can be added to `%OAuthIDPOptions` (or `%OAuthIDPs`)
to control group behaviour and defaults for each IDP.

The following options are all subkeys of `%OAuthIDPOptions` which are described below.

    Set(%OAuthIDPOptions,
       'authentik' => {
           'MetadataMap' => {
                ....
            },
           'GroupMap' => {
                ....
            },
           'GroupUserOptions' => {
                ....
           },
           'GroupListName' => 'groups',
           'RequireGroup' => 'GroupMap',
           'AllowLoginWithoutGroups' => 1,
           'CreateNoGroupUser' => 1,
           'LoginUpdateGroups' => 1,
           'LoginUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang' ],
           'CreateUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang', 'EmailAddress' ],
           'LoadColumn' => 'Name',
           'RemoveRTPassword' => 0,
           'Admins' => [ 'root' ],
        },
    );

- `GroupMap`

    Mapping of IDP groups to one or more RT groups.

               'GroupMap' => {
                   'NoGroup' => [ 'Staff' ],
                   'ACME Engineering' => [ 'Customer Support', 'Engineering' ],
                   'ACME Support' => [ 'Customer Support' ],
                   'ACME Sales' => [ 'Sales' ],
                   'ACME Finance' => [ 'Accounts' ],
                   'ACME Management' => [ 'Sales', 'Customer Support', 'Accounts' ],
                   'IT Administrators' => [ 'RT Admins' ],
                },

    In the above example, a user in the _IDP group_ **ACME Management** will be added to
    the RT groups **Sales**, **Customer Support** and **Accounts**.

    **NOTE**: RT groups **MUST** already exist in RT or user creation / update will fail. Ensure the
    spelling, any spaces and upper/lower case etc. is correct.

    If a user is in multiple IDP groups, all unique mapped RT groups are added for all groups.

    The special group **NoGroup** is used to set some default RT groups if the IDP did not
    return any groups for the user. Removing this option means no default groups are set.

- `GroupUserOptions`

    Set per-group user options which override the same setting in `OAuthNewUserOptions` if present.

            'GroupUserOptions' => {
                 'NoGroup' => { Privileged => 0,
                              },
                 'Customer' => { Privileged => 0,
                                 Organization => '',
                                 Comments => 'Customer user managed by OAuth2',
                              },
                 'ACME Staff' => { Privileged => 1,
                                   Organization => 'ACME Inc.',
                                   Lang => 'en-gb',
                              },
             },

    **NOTE**: If a user is in IDP multiple groups, the last group matched is used. As Perl hashes do not preserve order,
    this can have unpredictable results if the same option is repeated but different for multiple groups.

    It is recommended for users to be in only a single group where `GroupUserOptions` is set. Multiple groups
    may still be used if the are no conflicting `GroupUserOptions`.

    If set in `GroupMap`, the special group **NoGroup** can be used to configure options for users
    not in any IDP groups. In the above example, users who are not in any groups will be set as
    Unprivileged users instead of the default Privileged.

- `GroupListName`

    Configure the name of the groups list in the IDP payload. Default: `groups`.

        'GroupListName' => 'groups',

    Extracts the list named `"groups": [...]` in the following payload:

        {
        ...
            "email": "....",
            "email_verified": true,
            "name": "....e",
            "given_name": "....",
            "preferred_username": "....",
            "nickname": "....",
            "groups": [
                "ACME Engineering",
                "ACME Staff",
                "authentik Admins",
                "Web Server Admins"
                "RT_Admins",
                "RT_Users",
            ]
        }

    **NOTE**: Groups is not part of the official userinfo OpenID schema, but is a quasi-standard. Only a single JSON group list "\[ \]" is supported. Other nested lists or data structures are not (yet) supported.

- `RequireGroup`

    Configure a list of required groups. A user must be a member of at least one `RequireGroup` 
    to log in to RT.

    By default, users in all groups (or none) are permitted.

        'RequireGroup' => ['GroupMap', '^RT_ ', 'Web Server Admins' ],

    `RequireGroup` can be a single option (as a string) or a list containing any or all of 
    the following:

- `GroupMap`

    Permits users in any group listed in `GroupMap`

- _Group Name_

    Permits users in a specifc group (exact match)

- `^`_Group Prefix_

    Permits users in any group name starting with a given prefix. e.g.: `^RT_` would match any group
    beginning with `"RT_"`.

- `AllowLoginWithoutGroups`

    If `RequireGroups` is enabled, this option permits users with no groups (`NoGroup`) 
    to login. If set to `0`, users with no groups in the IDP will not be able to log in RT, 
    even if they have a matching RT user account and can log in with another method. Default: 1.

        'AllowLoginWithoutGroups' => '1',   

- `CreateNoGroupUser`

    If the global `$OAuthCreateNewUser` option is enabled, this option enables or disables
    creation of new RT user accounts for users with no groups in the IDP. Default: 1.

        'CreateNoGroupUser' => '1',

    You may also need to set `GroupUserOptions` for `NoGroup`, for example if these
    users should be created as Privileged. (Default is Unprivileged).

- `LoginUpdateGroups`

    Enable this option to always update a user's RT groups at every login. 

    This means a user's RT groups will be controlled by their IDP group memberships
    as configured by `GroupMap`.

    Upon login, users will be added to any RT groups mapped by `GroupMap` they are 
    not a member of. Users will also be **removed** from any RT groups not mapped in `GroupMap`.

    Default: 0 (Groups are only added for newly created RT users.)

- `LoginUpdateFields` / `CreateUpdateFields`

    Controls which fields are updated during login / for newly created RT users.

    You may want to set all fields from the IDP when a new user is created, 
    but allow some fields to be subsequently changed in RT (and not be updated 
    again when the user logs in.)

    Example:

    Update all fields from the IDP for newly created RT users (default):

           'CreateUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang', 'EmailAddress' ],

    Setting the following would allow users to change **RealName** and **NickName**:

           'LoginUpdateFields' => [ 'Organization', 'Lang', 'EmailAddress' ],

    Defaults:

           'CreateUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang', 'EmailAddress' ],
           'LoginUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang' ],    

    **NOTE**: **EmailAddress** is not updated on login by default. RT requires unique email addresses.
    This avoids a user being unable to login if we try to change **EmailAddress** to an
    address already in use by another user. If you are confident such conflicts are unlikely
    to occur with your RT users, add `EmailAddress` to your `LoginUpdateFields` configuration.

    **Name** (the username itself) is also not updated for the same reason.

- `RemoveRTPassword`

    Enable this option to remove the user's RT passsword after a successful OAuth2 login.

    This means **users will only be able to log in to RT using OAuth2 SSO**. 

    Passwords in RT will be deleted and cannot be used to login. (Non-admin users will also not
    be able to set a new password.)

    **NOTE**: This action is irreversible: RT's password hashes are deleted and not retained.
    It is therefore not possible to "reactivate" a previous password (unless you restore
    it from a database backup.) To login again with RT username/password, an admin user 
    can set a new password for the user.

    By default, the 'root' RT user's password is never updated. 

    See `Admins` to configure special admin users.

- `Admins`

    List of special / RT admin users. 

    No attribute or group changes will be applied for these users.

    Default: 

        'Admins' => [ 'root' ],

    - No IDP group membership are enforced. (Configured in `RequireGroup`).
    - No groups are updated on login if `LoginUpdateGroups` is enabled.
    - No user attributes are updated on login.
    - No RT password update if `RemoveRTPassword` is enabled.

- `%OAuthIDPs` Internal Options

    These are defaults for common endpoints. They should only be modified
    by the RT admin with good cause; most will want to leave these as they are.

            'LoginPageButton' => '/static/images/your_login_button.png',
            'authorize_path' => '/o/oauth2/auth',
            'site' => 'https://your.auth.server',
            'name' => 'ACME SSO Server',
            'protected_resource_path' => '/application/o/userinfo',
            'scope' => 'openid profile email',
            'access_token_path' => '/o/oauth2/token',

    See `etc/OAuth_Config.pm` in this extension's directory tree for a full list.

    Note, not all services listed here are tested and working. They may be added
    as supported options in future releases, or by customer request.
