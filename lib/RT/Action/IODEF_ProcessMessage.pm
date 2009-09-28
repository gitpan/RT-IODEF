# COPYRIGHT:
#
# Copyright 2009 REN-ISAC[1] and The Trustees of Indiana University[2]
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
# Author saxjazman@cpan.org (with the help of BestPractical.com)
#
# [1] http://www.ren-isac.net
# [2] http://www.indiana.edu

package RT::Action::IODEF_ProcessMessage;

use strict;
use warnings;

use base qw(RT::Action::IODEF);
use XML::IODEF;
use RT::Condition::IODEF;

sub Prepare { 
	my $self = shift;
	return(undef) unless($self->TransactionObj->ContentObj() && $self->TransactionObj->ContentObj()->Id()); # unless there is an attachment
	my $cond = RT::Condition::IODEF->new(
		CurrentUser		=> $self->CurrentUser(),
		TicketObj		=> $self->TicketObj(),
		TransactionObj	=> $self->TransactionObj(),
	);
	my $iodef = $cond->IsIODEF();
	return(undef) unless($iodef);
	$self->{'Argument'} = $iodef;
	return(1);
}

sub Commit {
	my $self = shift;
	my $iodef = $self->Argument();
	
	my $Ticket = $self->TicketObj();
	
	# get a list of the _IODEF_Incident custom fields in our Queue
	my $cfs = RT::CustomFields->new($self->CurrentUser());
	$cfs->LimitToQueue($self->TicketObj->Queue());
	# we hold the IODEF fields in the Description field by default
	$cfs->Limit(FIELD => 'Description', VALUE => '_IODEF_Incident', OPERATOR => 'LIKE');
	
	# cycle through the list of our _IODEF_Incident fields and append the values 
	# out of the IODEF document
	while (my $cf = $cfs->Next()){
		$RT::Logger->debug('Field: '.$cf->Name());
		# the description field holds the IODEF field name
		my $field = $cf->Description();
		$field =~ s/^_IODEF_//g;
		my $val = eval { $iodef->get($field)};
		next if($@);
		if($val){
			if($val eq 'ext-value'){
				$field =~ s/category$/ext-category/;
				$val = $iodef->get($field);
			}
			$self->TicketObj->AddCustomFieldValue(Field => $cf, Value => $val);
		}
	}
	
	$RT::Logger->debug('Success: '.__PACKAGE__);
	return(1);
}


1;
