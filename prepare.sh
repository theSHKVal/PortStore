#!/usr/bin/bash

cpan -if Config::Simple IO::Socket::INET String::CRC32;
chmod a+x PortStore.pl;
./PortStore.pl;