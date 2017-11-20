use inc::Module::Install;

RTx     'RT-Authen-OAuth2';
license 'gplv2';
repository 'https://github.com/bestpractical/rt-authen-oauth2';

# has not been well tested with versions before 4.4, but seems to work
# fine with later 4.0.X releases.
requires_rt '4.0.0';

requires 'Net::OAuth2';

sign;
WriteAll;
