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
# Author wes@barely3am.com (with the help of BestPractical.com)
#
# [1] http://www.ren-isac.net
# [2] http://www.indiana.edu

package RT::IODEF;

our $VERSION = '0.03_1';

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
        next if($field =~ /Addresscategory$/);
		if($val){
			# shim for handling ext-categories
			if($field =~ /EventDataFlowSystemNodeAddress$/){
                $xml->add($field,$val);
                my $cat = $ticket->FirstCustomFieldValue('Incident Address Category'); ## todo -- this doesn't scale well fix it
				eval { $xml->add('IncidentEventDataFlowSystemNodeAddresscategory',$cat) };
				# shim, if there is a non-enumuerated category, use the ext-cat option
				if($@){
					$RT::Logger->debug('adding as ext-value');
					$xml->add($field,'ext-value');
					$xml->add('IncidentEventDataFlowSystemNodeAddressext-category',$val);
				}
			} elsif($field =~ /Addresscidr$/){
				$xml->add('IncidentEventDataFlowSystemNodeAddresscategory','ipv4-net');
				$xml->add('IncidentEventDataFlowSystemNodeAddress',$val);
			} elsif($field =~ /Addressasn$/){
				$xml->add('IncidentEventDataFlowSystemNodeAddresscategory','asn');
                $xml->add('IncidentEventDataFlowSystemNodeAddress',$val);
			} else {
				eval { $xml->add($field,$val) };
			}
		}
	}
	
	return($xml->out());
}	
	

eval "require RT::IODEF_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/IODEF_Vendor.pm});
eval "require RT::IODEF_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/IODEF_Local.pm});

1;
