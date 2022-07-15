use strict;
use warnings;

use lib qw{ . lib};

use Test::More tests => 4;
use Test::Output;

use Data::Dumper;
use JSON::PP;
use UnitTestSetup;

BEGIN {
  {
    no strict 'refs';

    *{'HTTP::Request::new'}     = sub { bless {}, 'HTTP::Request'; };
    *{'HTTP::Request::request'} = sub { new HTTP::Response; };

    *{'HTTP::Response::new'}        = sub { bless {}, 'HTTP::Response'; };
    *{'HTTP::Response::is_success'} = sub { 1; };

    *{'LWP::UserAgent::new'}     = sub { bless {}, 'LWP::UserAgent'; };
    *{'LWP::UserAgent::request'} = sub { new HTTP::Response; };
  }

  use Module::Loaded;

  mark_as_loaded(HTTP::Request);
  mark_as_loaded(HTTP::Response);
  mark_as_loaded(LWP::UserAgent);

  use_ok('Amazon::Credentials');
} ## end BEGIN

init_test;

my $stderr_from;

subtest 'insecure => undef' => sub {
  $stderr_from = stderr_from(
    sub {
      Amazon::Credentials->new( profile => 'foo', debug => 1 );
    }
  );

  ok( $stderr_from =~ /blocked/, 'configuration file dump blocked' )
    or diag($stderr_from);
};

subtest 'insecure => 1' => sub {

  $stderr_from = stderr_from(
    sub {
      Amazon::Credentials->new(
        profile  => 'foo',
        debug    => 1,
        insecure => 1
      );
    }
  );

  ok( $stderr_from !~ /foo-aws-access-key-id/xsm, 'credentials blocked' )
    or diag($stderr_from);

  ok(
    $stderr_from =~ /aws_access_key_id/xsm,
    'configuration contents NOT blocked'
  ) or diag($stderr_from);
};

subtest 'insecure => 2' => sub {

  $stderr_from = stderr_from(
    sub {
      Amazon::Credentials->new(
        { profile  => 'foo',
          debug    => 1,
          insecure => 2
        }
      );
    }
  );

  ok( $stderr_from =~ /foo\-aws\-access\-key\-id/xsm,
    'credentials NOT blocked' )
    or diag($stderr_from);
};
