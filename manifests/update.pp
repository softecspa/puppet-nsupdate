# == Define: nsupdate::update
#
# This define make dynamic update of a zone in nameserver.
# Define automatically include nsupdate class therefore you don't need to explicitly include the class.
#
# === Parameters
#
# [*zone*]
#  DNS zone on wich update will be made. mandatory
#
# [*host_name*]
#  hostname to add in DNS zone. If nothing is specified, $hostname fact will be used
#
# [*nameserver*]
#  Nameserver address on which make update. If nothig is specifed global variable $nsupdate_nameserver will be used
#
# [*record_type*]
#  Type of record to update. Admitted value are A or CNAME. Default: A
#
# [*ttl*]
#  TTL (in seconds) of DNS record. Default: 180
#
# [*content*]
#  content of DNS record to update. It may be an ip address in case of A record or another DNS record in case of CNAME record. If nothing is specified
#  public ip is used. public ip is calculated by dynamic-nsupdate script visiting a web page that return client ipaddress.
#
# [*priv_key*]
#  Bind private key used to make update on ns_server. If nothing is specified global variable $nsupdate_key will be used.
#
# [*key_name*]
#  Name of private key used. If nothing is specified, global variable $nsupdate_keyname will be used
#
# [*interface*]
#  Use ip address of this interface. Usefully in case of backplane records.
#
# [*monitor*]
#  If is set to true, add a nrpe::check_dig check and export a nagios_service tagged with nagios_check_dig_${nagios_hostname}. Default: false
#
# [*nagios_hostname*]
#  Nagios hostname used to tag nagios_service exported by this define if monitor=true. Default: tiglio
#
# === Examples
#
# 1) Create record A $hostname.example.com containing visible public ip address of the node. Default global variables will be used to determine nameserver and private key and keyname
#
#    nsupdate::update { "$hostname.example.com":
#      zone   => 'example.com',
#    }
# 2) Create record A $hostname.backplane.example.com based on eth0 ip address
#
#    nsupdate::update{"$hostname.backplane.example.com":
#      zone       => 'backplane.example.com',
#      interface  => 'eth0',
#    }
#
# 3) Create recor A on a given hostname, zone containing a given ip address
#
#    nsupdate::update { "foo.example.com":
#     hostname  => 'foo',
#     zone      => 'example.com',
#     content   => 'xx.yy.zz.ww'
#    }
#
# 4) Create a CNAME record foo.example.com -> bar.example2.com
#
#    nsupdate::update { "foo.example.com":
#      hostname      => 'foo',
#      zone          => 'example.com',
#      content       => 'bar.example2.com.'
#      record_type   => 'CNAME',
#    }
#
# 5) Create A record on given zone on a given nameserver using given priv_key/keyname. Content will be public visible address
#   nsupdate::update { "foo.example.com":
#     hostname      => 'foo',
#     zone          => 'example.com',
#     nameserver    => 'ns1.example.com',
#     priv_key      => 'xxxxxxxxxxxxxxxxxxxxxxx',
#     priv_keyname  => 'keyname',
#   }
#
define nsupdate::update (
  $zone,
  $host_name        ='',
  $nameserver       = '',
  $record_type      = 'A',
  $ttl              = 180,
  $content          = '',
  $priv_key         = '',
  $key_name         = '',
  $interface        = '',
  $monitor          = false,
  $nagios_hostname  = 'tiglio'
) {

  include nsupdate

  if ($record_type != 'A') and ($record_type != 'CNAME') and ($record_type != 'PTR') {
    fail ('record_type can be A or CNAME or PTR')
  }

  if !is_integer($ttl) {
    fail ('ttl must be an integer value')
  }

  if ($content != '') and ($interface != '') {
    fail ('cannot use content and interface params togheter' )
  }

  $namehost= $host_name ? {
    ''      => $::hostname,
    default => $host_name
  }

  $real_nameserver = $nameserver ? {
    ''      => $::nsupdate_nameserver,
    default => $nameserver,
  }

  #TODO: la funzione url_get nel modulo common non va. E' lo script che ricava l'ip pubblico
  $record_content = $interface ? {
    ''      => $content ?{
      ''      => $content,
      default => " -c $content "
    },
    default => " -i $interface"
  }

  $private_key = $priv_key ? {
    ''      => $::nsupdate_key,
    default => $priv_key,
  }

  $private_key_name = $key_name ? {
    ''      => $::nsupdate_keyname,
    default => $key_name
  }

  exec {"delete_record_${namehost}_${zone}":
    command  => "/usr/local/sbin/dynamic-nsupdate -a del -z $zone -h $namehost $record_content -k $private_key -n $private_key_name -r $record_type -t $ttl -s $real_nameserver",
    unless   => "/usr/local/sbin/dynamic-nsupdate -a check -z $zone -h $namehost $record_content -k $private_key -n $private_key_name -r $record_type -t $ttl -s $real_nameserver",
    require  => File['/usr/local/sbin/dynamic-nsupdate'],
  }

  exec {"add_record_${namehost}_${zone}":
    command     => "/usr/local/sbin/dynamic-nsupdate -a add -z $zone -h $namehost $record_content -k $private_key -n $private_key_name -r $record_type -t $ttl -s $real_nameserver",
    unless      => "/usr/local/sbin/dynamic-nsupdate -a check -z $zone -h $namehost $record_content -k $private_key -n $private_key_name -r $record_type -t $ttl -s $real_nameserver",
    require     => File['/usr/local/sbin/dynamic-nsupdate'],
    subscribe   => Exec["delete_record_${namehost}_${zone}"],
    refreshonly => true
  }

  if $monitor {

    $string_check = $interface? {
      default => inline_template("<%= ipaddress_${interface} %>"),
      ''      => $content? {
        default => $content,
        ''      => '`wget -q -O - http://tools.softecspa.it/myip.php?pass=equ9oHoogazu`',
      }
    }

    $check_name=regsubst($name, '\*', 'star')
    nrpe::check_dig {$check_name :
      record        =>  "${namehost}.$zone",
      type          =>  $record_type,
      string_check  => $string_check,
    }

    @@nagios::check {$check_name:
      checkname             => 'check_nrpe_1arg',
      service_description   => "dig ${check_name}",
      params                => "!check_dig_$check_name",
      target                => "nsupdate_${::hostname}.cfg",
      tag                   => "nagios_check_dig_${nagios_hostname}",
      host                  => $::hostname,
      notification_period   => 'workhours',
    }
  }

}
