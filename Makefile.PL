use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	   => 'VcsTools-History',
   'VERSION' => '1.004',
   'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
   ($] >= 5.005 ?
    (ABSTRACT   => 'VCS History management tools',
     AUTHOR     => 'Dominique Dumont (domi@barrayar.grenoble.hp.com)') : ()),
   'PREREQ_PM' =>
   {
    'Puppet::Body' => '1.015',
    'Puppet::Storage' => '1.004',
    'MLDBM' => 0,
    'Time::Local' => 0
   }
  );
