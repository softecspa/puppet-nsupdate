puppet-nsupdate
===============

manage nsupdate for dynamic creation or DNS records

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with [Modulename]](#setup)
 * [Setup requirements](#setup-requirements)
4. [Usage - Configuration options and additional functionality](#usage)
 * [nsupdate::update](nsupdateupdate)
 * [nsupdate::reverse](nsupdatereverse)

##Overview
This module manage dynamic dns record creation through nsupdate.

##Module Description
Module uses a script pushed from the softec\_private module to manage nsupdate.

##Setup
    include ispconfig_logarchive

###Setup Requirements
module requires:
 * a script called dynamic\_nsupdate in path puppet:///modules/softec\_private/sbin
 * global variable $::nsupdate\_nameserver
 * global variable $::nsupdate\_key
 * global variable $::nsupdate\_keyname
 * global variable $::nagios\_hostname (used if you set monitor => true)


##Usage

Module have to be used through its defines update e reverse

###nsupdate::update
This define check if you dynamic record exists and, if true, the correctness. It the record is incorrect it will be removed and recreated. You can create A records and CNAME.

Please refer to the define documentation to see some examples

###nsupdate::reverse
This define create a PTR record. Like the update define, it cheks correctness of existent records and, if necessary, it destroy and recreate the record.

Please refer to the define documentation to see some examples
