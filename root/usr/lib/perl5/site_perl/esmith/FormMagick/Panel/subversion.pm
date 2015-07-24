#!/usr/bin/perl -w 
#----------------------------------------------------------------------
# $Id: subversion.pm 1 2006-05-29 11:25:58Z jonathan $
# vim: ft=perl ts=4 sw=4 et:
#----------------------------------------------------------------------
# copyright (C) 2006 Jonathan Martens
# copyright (C) 2002 Mitel Networks Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#----------------------------------------------------------------------

package esmith::FormMagick::Panel::subversion;

use strict;
use warnings;

use esmith::FormMagick;
use esmith::AccountsDB;
use esmith::ConfigDB;
use esmith::DomainsDB;
use esmith::cgi;
use esmith::util;
use File::Basename;
use Exporter;
use Carp;

use constant TRUE => 1;
use constant FALSE => 0;

our @ISA = qw(esmith::FormMagick Exporter);

our @EXPORT = qw(
    print_repository_table
    print_repository_name_field
    print_privileges
    print_vhost_message
    group_list
    user_list
    max_repository_name_length
    handle_repository
    remove_repository
    getExtraParams
    print_save_or_add_button
    validate_name
    validate_radio
    validate_description
    wherenext
);

our $configdb = esmith::ConfigDB->open
        or die "Can't open the Config database : $!\n" ;

our $accountdb = esmith::AccountsDB->open
        or die "Can't open the Account database : $!\n" ;

# fields and records separator for sub records
use constant FS => "," ;
use constant RS => ";" ;

=pod

=head1 NAME

esmith::FormMagick::Panels::subversion - Subversion

=head1 SYNOPSIS

use esmith::FormMagick::Panels::subversion

my $panel = esmith::FormMagick::Panel::subversion->new();
$panel->display();

=head1 DESCRIPTION

This module is the backend to the subversion panel, responsible 
for supplying all functions used by that panel. It is a subclass 
of esmith::FormMagick itself, so it inherits the functionality 
of a FormMagick object.

=cut

=head2 new()

Exactly as for esmith::FormMagick

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = esmith::FormMagick::new($class);
    $self->{calling_package} = (caller)[0];

    return $self;
}

=head1 HTML GENERATION ROUTINES

Routines for generating chunks of HTML needed by the panel.

=cut

=head2 subversion_status_print()

Display the status of all services involved: modSSL (provides Secure Scoket Layer (SSL) better known as the https protocl for httpd), modDAV (procides Distributed Authoring and Versioning 
(DAV) for httpd), modDAVSVN (provides SVN (Subversion) for DAV for the httpd)

=cut

sub subversion_status_print {
    my $self = shift ;
    my $q = $self->{cgi} ;

    my $modSSL = $configdb->get('modSSL')
        or ($self->error('ERR_NO_MODSSL_RECORD') and return undef) ;

    my $modSSLStatus = 0 ;
    $modSSLStatus = 1 if ( ( $modSSL->prop('status') || 'disabled' ) eq 'enabled' ) ;
    
    my $modDAV = $configdb->get('modDAV')
        or ($self->error('ERR_NO_MODDAV_RECORD') and return undef) ;

    my $modDAVStatus = 0 ;
    $modDAVStatus = 1 if ( ( $modDAV->prop('status') || 'disabled' ) eq 'enabled' ) ;
    
    my $modDAVSVN = $configdb->get('modDAVSVN')
        or ($self->error('ERR_NO_MODDAVSVN_RECORD') and return undef) ;

    my $modDAVSVNStatus = 0 ;
    $modDAVSVNStatus = 1 if ( ( $modDAVSVN->prop('status') || 'disabled' ) eq 'enabled' ) ;
    
    my $SysConfig = $configdb->get('sysconfig') ;
    my $SMEVersion = ( $SysConfig->prop('ReleaseVersion') || 0 ) ;
    $SMEVersion =~ s/^(\d+)\..*$/$1/ ;

    print $q->start_table({-class => 'sme-noborder'}), "\n";

    print $q->Tr(
        esmith::cgi::genCell( $q,
        "<img align=\"right\" src=\"/server-common/subversion_light_" . $modSSLStatus . ".jpg\" ALT=\"" .
            $self->localise('SERVICE_MODSSL_' . $modSSLStatus) . "\">" ),
        esmith::cgi::genCell( $q,
            $self->localise('SERVICE_MODSSL_' . $modSSLStatus) , "sme-noborders-label" ),
        esmith::cgi::genCell( $q, "<!--<a class=\"button-like\""
            . "href=\"subversion?page=3&Next=First&Current=" . $modSSLStatus . "\">"
            . $self->localise('BUTTON_LABEL_SERVICE_' . $modSSLStatus )
            . "</a>-->", "sme-noborders-content" ),"\n",
    ),"\n";

    print $q->Tr(
        esmith::cgi::genCell( $q,
        "<img align=\"right\" src=\"/server-common/subversion_light_" . $modDAVStatus . ".jpg\" ALT=\"" .
            $self->localise('SERVICE_MODDAV_' . $modDAVStatus) . "\">" ),
        esmith::cgi::genCell( $q,
            $self->localise('SERVICE_MODDAV_' . $modDAVStatus) , "sme-noborders-label" ),
        esmith::cgi::genCell( $q, "<a class=\"button-like\""
            . "href=\"subversion?page=4&Next=First&Current=" . $modDAVStatus . "\">"
            . $self->localise('BUTTON_LABEL_SERVICE_' . $modDAVStatus )
            . "</a>", "sme-noborders-content" ),"\n",
    ),"\n";

    print $q->Tr(
        esmith::cgi::genCell( $q,
        "<img align=\"right\" src=\"/server-common/subversion_light_" . $modDAVSVNStatus . ".jpg\" ALT=\"" .
            $self->localise('SERVICE_MODDAVSVN_' . $modDAVSVNStatus) . "\">" ),
        esmith::cgi::genCell( $q,
            $self->localise('SERVICE_MODDAVSVN_' . $modDAVSVNStatus) , "sme-noborders-label" ),
        esmith::cgi::genCell( $q, "<a class=\"button-like\""
            . "href=\"subversion?page=5&Next=First&Current=" . $modDAVSVNStatus . "\">"
            . $self->localise('BUTTON_LABEL_SERVICE_' . $modDAVSVNStatus )
            . "</a>", "sme-noborders-content" ),"\n",
    ),"\n";

    print $q->end_table(),"\n";

    return undef;
}

=head2 subversion_repository_print()

This function displays a table of repositories on the system 
including the links to modify and remove the repository

=cut

sub subversion_repository_print {
    my $self = shift;
    my $q = $self->{cgi};
    my $name        = $self->localise('NAME');
    my $description = $self->localise('DESCRIPTION');
    my $modify      = $self->localise('MODIFY');
    my $remove      = $self->localise('REMOVE');
    my $action_h    = $self->localise('ACTION');
    my @repositories = $accountdb->get_all_by_prop('type' => 'repository');

    unless ( scalar @repositories )
    {
        print $q->Tr($q->td($self->localise('NO_REPOSITORIES')));
        return "";
    }

    print $q->start_table({-CLASS => "sme-border"}),"\n";
    print $q->Tr (
                  esmith::cgi::genSmallCell($q, $name,"header"),
                  esmith::cgi::genSmallCell($q, $description,"header"),
                  esmith::cgi::genSmallCell($q, $action_h,"header", 3)),"\n";
    my $scriptname = basename($0);

    foreach my $r (@repositories)
    {
        my $repositoryname = $r->key();
        my $repositorydesc = $r->prop('Description');

        my $modifiable = $r->prop('Modifiable') || 'yes';
        my $removable = $r->prop('Removable') || 'yes';

        my $params = $self->build_repository_cgi_params($repositoryname, $r->props());

        my $href = "$scriptname?$params&action=modify&wherenext=";

        my $actionModify = '&nbsp;';
        if ($modifiable eq 'yes')
        {
            $actionModify .= $q->a({href => "${href}CreateModify"},$modify)
                      . '&nbsp;';
        }

        my $actionRemove = '&nbsp;';
        if ($removable eq 'yes')
        {
            $actionRemove .= $q->a({href => "${href}Remove"}, $remove)
                  . '&nbsp';
        }

        print $q->Tr (
            esmith::cgi::genSmallCell($q, $repositoryname,"normal"),
            esmith::cgi::genSmallCell($q, $repositorydesc,"normal"),
            esmith::cgi::genSmallCell($q, $actionModify,"normal"),
            esmith::cgi::genSmallCell($q, $actionRemove,"normal"));
    }

    print $q->end_table,"\n";

    return "";
}

=head2 subversion_repository_add_print()

This function prints the link to add a new repository

=cut

sub subversion_repository_add_print {
    my $self = shift;
    my $q = $self->{cgi};
    print $self->localise('ADD_REPOSITORY');
    return "";
}

=head2 print_privileges()

Prints a warning message that vhosts whose content is this repository will be modified to point to primary site.

=cut

sub print_privileges {
    my $self = shift;
    my $q = $self->{cgi};
    print qq(<tr><td colspan="2">) . $self->localise('PRIVILEGES') . qq(</td></tr>);
    return "";
}

=head2 print_vhost_message()

Prints a warning message that vhosts whose content is this repository will be modified to point to primary site.

=cut

sub print_vhost_message {
    my $self = shift;
    my $q = $self->{cgi};
    my $name = $q->param('name');

    my $domaindb = esmith::DomainsDB->open();
    my @domains = $domaindb->get_all_by_prop(Content => $name);
    my $vhostListItems = join "\n",
        (map ($q->li($_->key." ".$_->prop('Description')),
        @domains));
    if ($vhostListItems)
    {
        print $self->localise('VIRTUAL_HOST_MESSAGE', {vhostList => $vhostListItems});
    }
    return undef;
}

=head2 print_save_or_add_button()

Prints the ADD button when a new repository is addded and the SAVE buttom 
whem modifications are made.

=cut

sub print_save_or_add_button {
    my ($self) = @_;

    if ($self->cgi->param("action") eq "modify") {
        $self->print_button("SAVE");
    } else {
        $self->print_button("ADD");
    }

}

=head1 HELPER FUNCTIONS FOR THE PANEL

Routines for modifying the database and signaling events 
from the server-manager panel

=cut

=head2 mod_dav_status_change()

This method changes the status of the httpd mod_dav module.

=cut

sub mod_dav_status_change {
    my $self = shift ;
    $self->debug_msg("Start of sub 'mod_dav_status_change'.") ;
    my $current = $self->{cgi}->param('Current') ;
    $self->debug_msg("'mod_dav_status_change' : \$current = $current") ;

    my $modDAV = $configdb->get('modDAV')
        || ($self->error('ERR_NO_MODDAV_RECORD') and return undef);
    my $modDAVSVN = $configdb->get('modDAVSVN')
        || ($self->error('ERR_NO_MODDAVSVN_RECORD') and return undef);

    if ( $current ) {
        $modDAV->set_prop("status", "disabled") ;
        $self->debug_msg("'mod_dav_status_change' : mod_dav disabled.") ;
        $modDAVSVN->set_prop("status", "disabled") ;
        $self->debug_msg("'mod_dav_svn_status_change' : mod_dav_svn disabled.") ;
    } else {
        $modDAV->set_prop("status", "enabled") ;
        $self->debug_msg("'mod_dav_status_change' : mod_dav enabled.") ;
    }

    if (system ("/sbin/e-smith/signal-event", "subversion-modify") == 0) {
        $self->debug_msg("'subversion-modify' : files update OK.") ;
        $self->success("CONFIG_CHANGE_SUCCESS");
    } else {
        $self->debug_msg("'subversion-modify' : files update fails.") ;
        $self->error("CONFIG_CHANGE_ERROR");
    }
    return undef ;
}

=head2 mod_dav_svn_status_change()

This method changes the status of the httpd mod_dav_svn module.

=cut

sub mod_dav_svn_status_change {
    my $self = shift ;
    $self->debug_msg("Start of sub 'mod_dav_svn_status_change'.") ;
    my $current = $self->{cgi}->param('Current') ;
    $self->debug_msg("'mod_dav_svn_status_change' : \$current = $current") ;

    my $modDAV = $configdb->get('modDAV')
        || ($self->error('ERR_NO_MODDAV_RECORD') and return undef);
    my $modDAVSVN = $configdb->get('modDAVSVN')
        || ($self->error('ERR_NO_MODDAVSVN_RECORD') and return undef);

    if ( $current ) {
        $modDAVSVN->set_prop("status", "disabled") ;
        $self->debug_msg("'mod_dav_svn_status_change' : mod_dav_svn disabled.") ;
    } else {
        $modDAVSVN->set_prop("status", "enabled") ;
        $self->debug_msg("'mod_dav_dvn_status_change' : mod_dav_svn enabled.") ;
        $modDAV->set_prop("status", "enabled") ;
        $self->debug_msg("'mod_dav_status_change' : mod_dav enabled.") ;
    }

    if (system ("/sbin/e-smith/signal-event", "subversion-modify") == 0) {
        $self->debug_msg("'subversion-modify' : files update OK.") ;
        $self->success("CONFIG_CHANGE_SUCCESS");
    } else {
        $self->debug_msg("'subversion-modify' : files update fails.") ;
        $self->error("CONFIG_CHANGE_ERROR");
    }
    return undef ;
}

=head2 build_repository_cgi_params($self, $repositoryname, %oldprops)

Constructs the parameters for the links in the repository table

=cut

sub build_repository_cgi_params {
    my ($self, $repositoryname, %oldprops) = @_;

    #$oldprops{'description'} = $oldprops{Name};
    #delete $oldprops{Name};

    my %props = (
        page    => 0,
        page_stack => "",
        #".id"         => $self->{cgi}->param('.id') || "",
        name => $repositoryname,
        #%oldprops
    );

    return $self->props_to_query_string(\%props);
}


*wherenext = \&CGI::FormMagick::wherenext;
sub print_repository_name_field {
    my $self = shift;
    my $in = $self->{cgi}->param('name') || '';
    my $action = $self->{cgi}->param('action') || '';
    my $recMaxLength = $configdb->get('maxRepositoryNameLength');
    my $maxLength = $recMaxLength->value;
    print qq(<tr><td colspan="2">) . $self->localise('NAME_FIELD_DESC',
        {maxLength => $maxLength}) . qq(</td></tr>);
    print qq(<tr><td class="sme-noborders-label">) .
        $self->localise('NAME') . qq(</td>\n);
    if ($action eq 'modify' and $in) {
        my $rec = $accountdb->get($in);
	my $modifiable = $rec->prop('Modifiable') || 'yes';
	my $removable = $rec->prop('Removable') || 'yes';
        print qq(
            <td class="sme-noborders-content">$in
            <input type="hidden" name="name" value="$in">
         <!--   <input type="hidden" name="modifiable" value="$modifiable"> -->
         <!--   <input type="hidden" name="removable" value="$removable"> -->
            <input type="hidden" name="action" value="modify">
            </td>
        );

        # Read the values for each field from the accounts db and store
        # them in the cgi object so our form will have the correct
        # info displayed.
        my $q = $self->{cgi};
        if ($rec)
        {

	    $q->param(-name=>'description',
		-value=>$rec->prop('Description'));
	    $q->param(-name=>'groupsRead',
		-value=>join(FS, split(FS, $rec->prop('GroupsRead'))));
	    $q->param(-name=>'usersRead',
		-value=>join(FS, split(FS, $rec->prop('UsersRead'))));
	    $q->param(-name=>'groupsWrite',
		-value=>join(FS, split(FS, $rec->prop('GroupsWrite'))));
	    $q->param(-name=>'usersWrite',
		-value=>join(FS, split(FS, $rec->prop('UsersWrite'))));
            $q->param(-name=>'authentification_required',
		-value=>$rec->prop('AuthentificationRequired'));
            $q->param(-name=>'access_type',
		-value=>$rec->prop('AccessType'));
            $q->param(-name=>'force_ssl',
		-value=>$rec->prop('ForceSSL'));
            $q->param(-name=>'autoversioning',
		-value=>$rec->prop('SVNAutoVersioning') || 'on');
            $q->param(-name=>'mime',
		-value=>$rec->prop('ModMimeUseProfilePath') || 'off');

        }
    } else {
        print qq(
            <td><input type="text" name="name" value="$in">
            <input type="hidden" name="action" value="create">
            </td>
        );
    }

    print qq(</tr>\n);
    return undef;

}

=pod

=head2 group_list()

Returns a hash of groups for the Create/Modify screen's group 
field's drop down list.

=cut

sub group_list
{
    my @groups = $accountdb->groups();
    my %groups = ();
    foreach my $g (@groups) {
        $groups{$g->key()} = $g->prop('Description')." (".$g->key.")";
    }
    return \%groups;
}

=head2 user_list()

Returns a hash of users for the Create/Modify screen's user field's
drop down list.

=cut

sub user_list
{
    my @users = $accountdb->users();
    my %users = ();
    foreach my $u (@users) {
        $users{$u->key()} = $u->prop('LastName').", ". $u->prop('FirstName')." (". $u->key.")";
    }
    return \%users;
}

=head2 svn_prop_list()

Returns a hash of users for the Create/Modify screen's user field's
drop down list.

=cut

sub svn_prop_list
{
    my %props = (
		  'GET'		=> 'GET', 
		  'POST'	=> 'POST', 
                  'PUT'		=> 'PUT', 
		  'DELETE'	=> 'DELETE', 
		  'CONNECT'	=> 'CONNECT', 
		  'OPTIONS'	=> 'OPTIONS', 
		  'TRACE'	=> 'TRACE', 
		  'PATCH'	=> 'PATCH', 
		  'PROPFIND'	=> 'PROPFIND', 
		  'PROPPATCH'	=> 'PROPPATCH',
		  'MKCOL'	=> 'MKCOL', 
		  'COPY'	=> 'COPY', 
		  'MOVE'	=> 'MOVE', 
		  'LOCK'	=> 'LOCK', 
		  'UNLOCK'	=> 'UNLOCK'
		);
    return \%props;
}

=head1 THE ROUTINES THAT ACTUALLY DO THE WORK

=cut

=head2 handle_repositories()

Determine whether to modify or add the repository

=cut

sub handle_repositories {
    my ($self) = @_;


    if ($self->cgi->param("action") eq "create") {
        $self->create_repository();
    } else {
        $self->modify_repository();
    }
}

=head2 create_repository()

Handle the create event for the repository

=cut

sub create_repository {
    my ($self) = @_;
    my $name = $self->cgi->param('name');
    my $msg;

    $msg = $self->validate_name($name);
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->max_repository_name_length($name);
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->conflict_check($name);
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->validate_radio($self->cgi->param('access_type'));
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->validate_radio($self->cgi->param('force_ssl'));
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->validate_radio($self->cgi->param('authentification_required'));
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->validate_radio($self->cgi->param('autoversioning'));
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->validate_radio($self->cgi->param('mime'));
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    my $gr_list;
    my @groupsRead = $self->cgi->param('groupsRead');
    foreach my $gr (@groupsRead) {
        if ($gr_list) {
            $gr_list .= "," . $gr;
        } else {
            $gr_list = $gr;
        }
    }

    my $ur_list;
    my @usersRead = $self->cgi->param('usersRead');
    foreach my $ur (@usersRead) {
        if ($ur_list) {
            $ur_list .= "," . $ur;
        } else {
            $ur_list = $ur;
        }
    }

    my $gw_list;
    my @groupsWrite = $self->cgi->param('groupsWrite');
    foreach my $gw (@groupsWrite) {
        if ($gw_list) {
            $gw_list .= "," . $gw;
        } else {
            $gw_list = $gw;
        }
    }

    my $uw_list;
    my @usersWrite = $self->cgi->param('usersWrite');
    foreach my $uw (@usersWrite) {
        if ($uw_list) {
            $uw_list .= "," . $uw;
        } else {
            $uw_list = $uw;
        }
    }

    my $uid  = $accountdb->get_next_uid();
    if (my $acct = $accountdb->new_record($name, {
            Description              => $self->cgi->param('description'),
            GroupsRead               => "$gr_list",
            UsersRead                => "$ur_list",
            GroupsWrite              => "$gw_list",
            UsersWrite               => "$uw_list",
	    Modifiable               => 'yes',
            Removable                => 'yes',
            ForceSSL                 => $self->cgi->param('force_ssl'),
            AccessType               => $self->cgi->param('access_type'),
            AuthentificationRequired => $self->cgi->param('authentification_required'),
            SVNAutoVersioning        => $self->cgi->param('autoversioning'),
            ModMimeUseProfilePath    => $self->cgi->param('mime'),
            type                     => 'repository',
        }) )
    {
        # Untaint $name before use in system()
        $name =~ /(.+)/; $name = $1;
        if (system ("/sbin/e-smith/signal-event", "repository-create", $name) == 0) {
            $self->success("SUCCESSFULLY_CREATED_REPOSITORY");
        } else {
            $self->error("ERROR_WHILE_CREATING_REPOSITORY");
        }
    } else {
        $self->error('CANT_CREATE_REPOSITORY');
    }
}

=head2 modify_repository()

Handle the modify event for the repository

=cut

sub modify_repository {
    my ($self) = @_;
    my $name = $self->cgi->param('name');
    my $msg;

    $msg = $self->validate_name($name);
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->validate_radio($self->cgi->param('access_type'));
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->validate_radio($self->cgi->param('force_ssl'));
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->validate_radio($self->cgi->param('authentification_required'));
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->validate_radio($self->cgi->param('autoversioning'));
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    $msg = $self->validate_radio($self->cgi->param('mime'));
    unless ($msg eq "OK")
    {
        return $self->error($msg);
    }

    my $gr_list;
    my @groupsRead = $self->cgi->param('groupsRead');
    foreach my $gr (@groupsRead) {
        if ($gr_list) {
            $gr_list .= "," . $gr;
        } else {
            $gr_list = $gr;
        }
    }

    my $ur_list;
    my @usersRead = $self->cgi->param('usersRead');
    foreach my $ur (@usersRead) {
        if ($ur_list) {
            $ur_list .= "," . $ur;
        } else {
            $ur_list = $ur;
        }
    }

    my $gw_list;
    my @groupsWrite = $self->cgi->param('groupsWrite');
    foreach my $gw (@groupsWrite) {
        if ($gw_list) {
            $gw_list .= "," . $gw;
        } else {
            $gw_list = $gw;
        }
    }

    my $uw_list;
    my @usersWrite = $self->cgi->param('usersWrite');
    foreach my $uw (@usersWrite) {
        if ($uw_list) {
            $uw_list .= "," . $uw;
        } else {
            $uw_list = $uw;
        }
    }

    if (my $acct = $accountdb->get($name)) {
        if ($acct->prop('type') eq 'repository') {

            $acct->merge_props(
            Description              => $self->cgi->param('description'),
            GroupsRead               => "$gr_list",
            UsersRead                => "$ur_list",
            GroupsWrite              => "$gw_list",
            UsersWrite               => "$uw_list",
            ForceSSL                 => $self->cgi->param('force_ssl'),
            AccessType               => $self->cgi->param('access_type'),
            AuthentificationRequired => $self->cgi->param('authentification_required'),
            SVNAutoVersioning        => $self->cgi->param('autoversioning'),
            ModMimeUseProfilePath    => $self->cgi->param('mime'),
            type                     => 'repository',
            );

            # Untaint $name before use in system()
            $name =~ /(.+)/; $name = $1;
            if (system ("/sbin/e-smith/signal-event", "repository-modify",
                $name) == 0)
            {
                $self->success("SUCCESSFULLY_MODIFIED_REPOSITORY");
            } else {
                $self->error("ERROR_WHILE_MODIFYING_REPOSITORY");
            }
        } else {
            $self->error('CANT_FIND_REPOSITORY');
        }
    } else {
        $self->error('CANT_FIND_REPOSITORY');
    }
}

=head2 modify_repository()

Handle the remove event for the repository

=cut

sub remove_repository {
    my ($self) = @_;
    my $name = $self->cgi->param('name');
    if (my $acct = $accountdb->get($name)) {
        if ($acct->prop('type') eq 'repository') {
            $acct->set_prop('type', 'repository-deleted');

            my $domains_db = esmith::DomainsDB->open();
            my @domains = $domains_db->get_all_by_prop(Content=>$name);
            foreach my $d (@domains) {
                $d->set_prop(Content => 'Primary');
            }

            # Untaint $name before use in system()
            $name =~ /(.+)/; $name = $1;
            if (system ("/sbin/e-smith/signal-event", "repository-delete",
                $name) == 0)
            {
                $self->success("SUCCESSFULLY_DELETED_REPOSITORY");
                $acct->delete();
            } else {
                $self->error("ERROR_WHILE_DELETING_REPOSITORY");
            }
        } else {
            $self->error('CANT_FIND_REPOSITORY');
        }

    } else {
        $self->error('CANT_FIND_REPOSITORY');
    }
    $self->wherenext('First');
}

=head1 VALIDATION ROUTINES

=head2 max_repository_name_length()

Checks the length of a given repository name against the maximum set in the
maxAcctNameLength record of the configuration database.  Defaults to a
maximum length of $self->{defaultMaxLength} if nothing is set in the 
config db.

=cut

sub max_repository_name_length {
    my ($self, $data) = @_;
    $configdb->reload();
    my $max;
    if (my $max_record = $configdb->get('maxRepositoryNameLength')) {
        $max = $max_record->value();
    }

    if (length($data) <= $max) {
        return "OK";
    } else {
        return $self->localise("MAX_REPOSITORY_NAME_LENGTH_ERROR",
            {acctName => $data,
             maxRepositoryNameLength => $max,
             maxLength => $max});
    }
}

=head2 getExtraParams()

Sets variables used in the lexicon to their required values.

=cut

sub getExtraParams
{
    my $self = shift;
    my $q = $self->{cgi};
    my $name = $q->param('name');
    my $desc = '';

    if ($name)
    {
        my $acct = $accountdb->get($name);
        if ($acct)
        {
            $desc = $acct->prop('Description');
        }
    }
    return (name => $name, description => $desc);
}

=head2 validate_name()

Checks that the name supplied does not contain any unacceptable chars.
Returns OK on success or a localised error message otherwise.

=cut

sub validate_name {

    my ($self, $acctName) = @_;

    unless ($acctName =~ /^([a-z][\_\.\-a-z0-9]*)$/)
    {
        return $self->localise('ACCT_NAME_HAS_INVALID_CHARS',
                             {acctName => $acctName});
    }
    return "OK";

}

=head2 validate_radio()

Checks wether a value is checked for a radio button

=cut

sub validate_radio {

    my ($self, $acctName) = @_;

#    $self->debug(TRUE);
#    $self->debug_msg("$acctName") ;    

    unless($acctName ne '') {

        return $self->localise('ERROR_RADIO_VALUE_NOT_CHECKED', acctName => $acctName);

    }

    $self->debug(FALSE);

    return "OK";

}

=head2 validate_description()

#Checks that the name supplied does not contain any unacceptable chars.
#Returns OK on success or a localised error message otherwise.

=cut

sub validate_description {

    my ($self, $description) = @_;

    unless ($description =~ /^([\w\s\_\.\-]*)$/)
    {
        return $self->localise('DESCRIPTION_HAS_INVALID_CHARS',
                             {repoDescription => $description});
    }
    if ($description =~ /^\s*$/)
    {
	return $self->localise('DESCRIPTION_SHOULD_NOT_BE_EMPTY');
    }
    return "OK";

}

=head2 conflict_check()

Check the proposed name for clashes with existing pseudonyms or other
accounts of any type.

=cut

sub conflict_check
{
    my ($self, $name) = @_;
    my $rec = $accountdb->get($name);

    my $type;
    if (defined $rec)
    {
                my $type = $rec->prop('type');
                if ($type eq "pseudonym")
                {
                        my $acct = $rec->prop("Account");
                        my $acct_type = $accountdb->get($acct)->prop('type');

                        return $self->localise('ACCT_CLASHES_WITH_PSEUDONYM',
                                {acctName => $name, acctType => $acct_type, acct => $acct});
                }
    }
    elsif (defined getpwnam($name) || defined getgrnam($name))
    {
        $type = 'system';
    }
    else
    {
        # No account record and no account
        return 'OK';
    }
    return $self->localise('ACCOUNT_EXISTS',
        {acctName => $name, acctType => $type});
}

1;
