requires 'HTTP::Message', '6.00';
requires 'JSON::MaybeXS', '1.004000';
requires 'LWP::UserAgent', '6.00';
requires 'Moo', '2.000000';
requires 'Safe::Isa', '1.000005';
requires 'Time::HiRes';

on test => sub {
  requires 'Test::Fatal', '0.014';
  requires 'Test::LoadAllModules', '0.021';
  requires 'Test::More', '0.98';
};
