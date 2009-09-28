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

package RT::IODEF;

our $VERSION = '0.02_1';

use warnings;
use strict;

package RT::Ticket;

use XML::IODEF;

sub IODEF {
	my $self = shift;
	
	my $ticket = $self;
	
	my $xml = XML::IODEF->new();
	
	my $cfs = RT::CustomFields->new($self->CurrentUser());
	$cfs->LimitToQueue($ticket->Queue());
	$cfs->Limit(FIELD => 'Description', VALUE => '_IODEF_Incident', OPERATOR => 'LIKE');
	return(undef) unless($cfs->Count());

	while(my $cf = $cfs->Next()){
		my $field = $cf->Description();
		$field =~ s/_IODEF_//g;
		my $val = $ticket->FirstCustomFieldValue($cf->Name());
		## TODO -- what happens when we forget the address category?
		if($field eq 'IncidentIncidentDataEventDataSystemNodeAddressaddress'){
			unless($ticket->FirstCustomFieldValue('Incident Address Category')){
				my $c = RT::CustomField->new($self->CurrentUser());
				$c->Load('Incident Address Category');
				$ticket->AddCustomFieldValue(Field => $c, Value => 'unknown');
			}
		}
		if($val){
			# shim for handling ext-categories
			if($field =~ /Addresscategory$/){
				eval { $xml->add($field,$val) };
				# shim, if there is a non-enumuerated category, use the ext-cat option
				if($@){
					#$RT::Logger->debug($@);
					$RT::Logger->debug('adding as ext-value');
					$xml->add($field,'ext-value');
					$xml->add('IncidentIncidentDataEventDataSystemNodeAddressext-category',$val);
				}
			} elsif($field =~ /Addresscidr$/){
				$xml->add('IncidentIncidentDataEventDataSystemNodeAddresscategory','ipv4-net');
				#$xml->add('IncidentIncidentDataEventDataSystemNodeAddressext-category','ipv4-net');
				$xml->add('IncidentIncidentDataEventDataSystemNodeAddressaddress',$val);
			} elsif($field =~ /Addressasn$/){
				$xml->add('IncidentIncidentDataEventDataSystemNodeAddresscategory','ext-value');
                                $xml->add('IncidentIncidentDataEventDataSystemNodeAddressext-category','asn');
                                $xml->add('IncidentIncidentDataEventDataSystemNodeAddressaddress',$val);
			} else {
				$xml->add($field,$val);
			}
		}
	}
	
	return($xml->out());
}	
	

eval "require RT::IODEF_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/IODEF_Vendor.pm});
eval "require RT::IR::IODEF_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/IODEF_Local.pm});

1;
