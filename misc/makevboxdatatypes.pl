#!/usr/bin/perl
#
# Generates the Datatypes File
#
use strict;
use warnings;
my %types;

open (VBOX, "~/Documents/Programming/code-repos/git/RemoteBox/share/remotebox/vboxService.pm");
my @a = <VBOX>;
chomp(@a);
close(VBOX);

foreach my $line (@a) {
	next if ($line !~ m/vbox:/);
	$line =~ s/^.*\'vbox://g;
	$line =~ s/\'.*$//g;
	$types{$line} = 1;
}

print "# Serializers for missing datatypes in vboxService.pm\n";
print "use strict;\n";
print "use warnings;\n\n";

foreach my $key (sort(keys(%types))) {
	print q[sub SOAP::Serializer::as_] . $key . " {\n";
    	print q[    my $self = shift;] . "\n";
    	print q[    my ($value, $name, $type, $attr) = @_;] . "\n";
    	print q|    return [$name, {'xsi:type' => 'vbox:| . $key . q|', %$attr}, $value]| . ";\n";
	print "}\n\n";
}

print "1;\n";
