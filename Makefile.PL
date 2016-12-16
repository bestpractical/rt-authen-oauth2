use inc::Module::Install;

RTx     'RT-Authen-OAuth2';
license 'gplv2';
repository 'https://github.com/bestpractical/rt-authen-oauth2';

requires_rt '4.4.0';

requires 'Net::OAuth2';

sign;
WriteAll;
