# /=====================================================================\ #
# |  LaTeXML::Core::List                                                | #
# | Digested objects produced in the Stomach                            | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Bruce Miller <bruce.miller@nist.gov>                        #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #
package LaTeXML::Core::List;
use strict;
use warnings;
use LaTeXML::Global;
use LaTeXML::Common::Object;
use LaTeXML::Common::Error;
use LaTeXML::Common::Dimension;
use List::Util qw(min max);
use base qw(Exporter LaTeXML::Core::Box);
our @EXPORT = (qw(&List));

# Tricky; don't really want a separate constructor for a Math List,
# but you really have to specify it in the arguments
# BUT you can't infer the mode from the current state ($STATE may have already switched
#  back to text) or from the modes of the boxes (may be mixed)
# So, it has to be specified along with the boxes;
# Here we simply allow
#    List($box,.... mode=>'math')
# Also, if there's only 1 box, we just return it!
sub List {
  my (@boxes) = @_;
  my $mode = 'text';
  # Hacky special case!!!
  if ((scalar(@boxes) >= 2) && ($boxes[-2] eq 'mode')
    && (($boxes[-1] eq 'math') || ($boxes[-1] eq 'text'))) {
    $mode = pop(@boxes); pop(@boxes); }
  if (scalar(@boxes) == 1) {
    return $boxes[0]; }    # Simplify!
  else {
    my $list = LaTeXML::Core::List->new(@boxes);
    $list->setProperty(mode => $mode) if $mode eq 'math';
    return $list; } }

sub new {
  my ($class, @boxes) = @_;
  my ($bx, $font, $locator);
  my @bxs = @boxes;
  while (defined($bx = shift(@bxs)) && (!defined $locator)) {
    $locator = $bx->getLocator unless defined $locator; }
  @bxs = @boxes;
  # Maybe the most representative font for a List is the font of the LAST box (that _has_ a font!) ???
  while (defined($bx = pop(@bxs)) && (!defined $font)) {
    $font = $bx->getFont unless defined $font; }
  return bless [[@boxes], $font, $locator || '', undef, {}], $class; }

sub isMath {
  my ($self) = @_;
  return ($$self[4]{mode} || 'text') eq 'math'; }

sub unlist {
  my ($self) = @_;
  return @{ $$self[0] }; }

sub revert {
  my ($self) = @_;
  return map { Revert($_) } $self->unlist; }

sub toString {
  my ($self) = @_;
  return join('', grep { defined $_ } map { $_->toString } $self->unlist); }

# Methods for overloaded operators
sub stringify {
  my ($self) = @_;
  my $type = ref $self;
  $type =~ s/^LaTeXML:://;
  return $type . '[' . join(',', map { Stringify($_) } $self->unlist) . ']'; }    # Not ideal, but....

sub equals {
  my ($a, $b) = @_;
  return 0 unless (defined $b) && ((ref $a) eq (ref $b));
  my @a = $a->unlist;
  my @b = $b->unlist;
  while (@a && @b && ($a[0]->equals($b[0]))) {
    shift(@a); shift(@b); }
  return !(@a || @b); }

sub beAbsorbed {
  my ($self, $document) = @_;
  return map { $document->absorb($_) } $self->unlist; }

sub computeSize {
  my ($self) = @_;
  my ($wd, $ht, $dp) = (0, 0, 0);
  foreach my $box (@{ $$self[0] }) {
    my $w = $box->getWidth;
    my $h = $box->getHeight;
    my $d = $box->getDepth;
    if (ref $w) {
      $wd += $w->valueOf; }
    else {
      Warn('expected', 'Dimension', undef,
        "Width of " . Stringify($box) . " yeilded a non-dimension: " . Stringify($w)); }
    if (ref $h) {
      $ht = max($ht, $h->valueOf); }
    else {
      Warn('expected', 'Dimension', undef,
        "Height of " . Stringify($box) . " yeilded a non-dimension: " . Stringify($h)); }
    if (ref $d) {
      $dp = max($dp, $d->valueOf); }
    else {
      Warn('expected', 'Dimension', undef,
        "Width of " . Stringify($box) . " yeilded a non-dimension: " . Stringify($d)); }
  }
  $$self[4]{width}  = Dimension($wd) unless defined $$self[4]{width};
  $$self[4]{height} = Dimension($ht) unless defined $$self[4]{height};
  $$self[4]{depth}  = Dimension($dp) unless defined $$self[4]{depth};
  return; }

#======================================================================
1;

__END__

=pod 

=head1 NAME

C<LaTeXML::Core::List> - represents lists of digested objects;
extends L<LaTeXML::Core::Box>.

=head1 AUTHOR

Bruce Miller <bruce.miller@nist.gov>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
