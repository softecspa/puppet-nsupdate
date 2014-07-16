# == Define: nsupdate::reverse
#
# This define make dynamic update of a reverse zone in nameserver.
# Define automatically include nsupdate class therefore you don't need to explicitly include the class.
#
# === Parameters
#
# [*host_name*]
#  hostname to set in reverse record. If it's not set $hostname fact will be used
#
# [*domain*]
#  domain to set in reverse record. If it's not set backplane will be used
#
# [*ttl*]
#  TTL (in seconds) of DNS record. Default: 180
#
# [*interface*]
#  Use ip address of this interface instead of specify if.
#
# [*ip_address*]
#  Use this ip address. If interface and ip_address aren't specified <name> will be used if it's a real ip address
#
# [*nameserve*]
#  Nameserver address on which make update. If nothig is specifed global variable $nsupdate_nameserver will be used
#
# [*priv_key*]
#  Bind private key used to make update on ns_server. If nothing is specified global variable $nsupdate_key will be used.
#
# [*key_name*]
#  Name of private key used. If nothing is specified, global variable $nsupdate_keyname will be used
#
# === Examples
#
# 1) Create PTR record for the host in backplane zone specifing the backplane address
#
#    nsupdate::reverse { "192.168.34.1": }
#
# 2) Create PTR record for the host in backplane zone using eth0 address
#
#    nsupdate::reverse{"foo":
#      interface  => 'eth0',
#    }
#
# 3) Create PTR record for the host in backplane zone specifing a different hostname
#
#    nsupdate::update { "192.168.34.1":
#     hostname  => 'foo',
#    }
#
# 4) Create PTR record for the host in example.com zone specifing a different hostname
#
#    nsupdate::update { "192.168.34.1":
#      hostname      => 'foo',
#      domain        => 'example.com',
#    }
#
define nsupdate::reverse (
  $host_name  = '',
  $nameserver = '',
  $domain     = 'backplane',
  $ttl        = 180,
  $interface  = '',
  $ip_address = '',
  $priv_key   = '',
  $key_name   = '',
) {

    if !is_integer($ttl) {
        fail ('ttl must be an integer value')
    }

    if ($ip_address == '') and ($interface == '') and (! $name =~ /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/) {
      fail ('if ip_address and interface aren\'t specified name must be an ip address')
    }

    if ($ip_address != '') and (! $ip_address =~ /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/) {
      fail ('ip_address parameter must be a valid ip address')
    }

    if ($ip_address != '') and ($interface != '') {
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

    $private_key = $priv_key ? {
      ''      => $::nsupdate_key,
      default => $priv_key,
    }

    $private_key_name = $key_name ? {
      ''      => $::nsupdate_keyname,
      default => $key_name
    }

    $real_ip_address = $interface ? {
      ''      => $ip_address ? {
        ''      => $name,
        default => $ip_address
      },
      default => inline_template("<%= ipaddress_${interface} %>"),
    }

    $zone = inline_template('<%= @real_ip_address.split(\'.\')[2] %>.<%= @real_ip_address.split(\'.\')[1] %>.<%= @real_ip_address.split(\'.\')[0] %>.in-addr.arpa')
    $last_octet=inline_template('<%= real_ip_address.split(\'.\')[3] %>')

    nsupdate::update{$name :
      zone        => $zone,
      host_name   => $last_octet,
      record_type => 'PTR',
      content     => "${namehost}.${domain}",
    }
}
