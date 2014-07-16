# == Class: nsupdate
#
# This class is used to do dynamic update of a nameserver.
# N.B: inclusion of this class only push a script named dynamic-nsupdate. This script is
# used by nsupdate::update define. See documentation of this define for further information
#
class nsupdate {

  file {'/usr/local/sbin/dynamic-nsupdate':
    ensure  => present,
    owner   => 'root',
    group   => 'admin',
    mode    => '0770',
    source  => 'puppet:///modules/softec_private/sbin/dynamic-nsupdate'
  }
}
