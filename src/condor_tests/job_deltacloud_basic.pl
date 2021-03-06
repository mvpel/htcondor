#! /usr/bin/env perl
##**************************************************************
##
## Copyright (C) 1990-2007, Condor Team, Computer Sciences Department,
## University of Wisconsin-Madison, WI.
## 
## Licensed under the Apache License, Version 2.0 (the "License"); you
## may not use this file except in compliance with the License.  You may
## obtain a copy of the License at
## 
##    http://www.apache.org/licenses/LICENSE-2.0
## 
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
##**************************************************************

use CondorTest;
use strict;
use warnings;

#$cmd = 'job_deltacloud_basic.cmd';
my $cmd = $ARGV[0];
my $debuglevel = 1;

CondorTest::debug( "Submit file for this test is $cmd\n",$debuglevel);
CondorTest::debug( "looking at env for condor config\n",$debuglevel);

my $condor_config = $ENV{CONDOR_CONFIG};

CondorTest::debug("CONDOR_CONFIG = $condor_config\n",$debuglevel);

my $testdesc =  'Deltacloud basic test';
my $testname = "job_deltacloud_basic";

my $aborted = sub {
	my %info = @_;
	my $done;
	CondorTest::debug( "Abort event not expected \n",$debuglevel);
	die "Abort event not expected!\n";
};

my $held = sub {
	my %info = @_;
	my $cluster = $info{"cluster"};
	my $holdreason = $info{"holdreason"};

	CondorTest::debug( "Held event not expected: $holdreason \n",$debuglevel);
	system("condor_status -any -l");
	die "Deltacloud job being held not expected\n";
};

my $submit = sub
{
	my %args = @_;
	my $cluster = $args{"cluster"};
	print "ok\n";
};

my $execute = sub
{
	my %args = @_;
	my $cluster = $args{"cluster"};

	my $service_url = `condor_q $cluster -format "%s" GridResource | sed 's/.* //'`;
	chomp $service_url;
	CondorTest::debug("Service URL is $service_url\n", $debuglevel);
	my $instance_id = "";
	my $cnt = 0;
	while ( $instance_id eq "" && $cnt < 5 ) {
		$instance_id = (split( " ", `condor_q $cluster -format "%s" GridJobId` ))[2];
		chomp $instance_id;
		sleep( 2 );
	}
	die "Failed to find instance id\n" if ( $service_url eq "" || $instance_id eq "" );
	CondorTest::debug("Instance id is $instance_id\n", $debuglevel);

	system( "wget --post-data= --http-user=mockuser --http-passwd=mockpassword $service_url/instances/$instance_id/stop" );
	if ( $? != 0 ) {
		#die "Failed to stop instance\n";
		CondorTest::debug("Failed to stop instance, letting test continue...\n",$debuglevel);
	}
};

my $deltacloudd_out = "deltacloudd.out";

my $success = sub
{
	my %info = @_;
	my $line = "";
	my $successcount = 0;
	my $keypaircount = 0;
	my $keyspairs = 2;
	my $successes = 8;

	# TODO Is there anything useful to check in server output?
#	print "Checking server output - ";
#
#	open(SERVER,"<$deltacloudd_out") or die "Failed to open <$deltacloudd_out>:$!\n";
#	while(<SERVER>) {
#		chomp();
#		$line = $_;
#		if($line =~ /^CreateKeyPair/) {
#			$keypaircount += 1;
#		} elsif($line =~ /^DeleteKeyPair/) {
#			$keypaircount += 1;
#		} elsif($line =~ /^Return Success/) {
#			$successcount += 1;
#		} else {
#			# ignore the rest
#		}
#	}
#	close(SERVER);
#	if(($successcount == $successes) && ($keypaircount == $keyspairs)) {
		print "ok\n";
#	} else {
#		print "bad\n";
#	}


	print "Job executed successfully\n";
	# Verify that output file contains expected "Done" line
};

CondorTest::RegisterSubmit( $testname, $submit );
CondorTest::RegisterExitedSuccess( $testname, $success);
CondorTest::RegisterExecute($testname, $execute);
CondorTest::RegisterHold( $testname, $held );

if( CondorTest::RunTest($testname, $cmd, 0) ) {
	CondorTest::debug( "$testname: SUCCESS\n",$debuglevel);
	exit(0);
} else {
	CondorTest::debug( "$testname: FAILED\n",$debuglevel);
	die "$testname: CondorTest::RunTest() failed\n";
}

