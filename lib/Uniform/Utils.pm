package Uniform::Utils;

use strict;
use warnings;
use Exporter 'import';
use Carp qw(croak);

our $VERSION = '1.00';
our @EXPORT_OK = qw(normalize_http_headers);

# Shared production-grade normalization engine utilized by all Uniform distributions
sub normalize_http_headers {
    my ($hash) = @_;
    croak "Header argument must be a HASH reference" unless ref($hash) eq 'HASH';

    my (%normalized, %priority);

    for my $key (keys %$hash) {
        next unless defined $key;
        my $val = $hash->{$key};

        my $norm = lc "$key";
        $norm =~ s/^\s+|\s+$//g;

        my $is_http_env = $norm =~ s/^http[-_]//;
        my $rank = ($is_http_env ? 0 : 2) + ($norm =~ /-/ ? 1 : 0);

        $norm =~ tr/_/-/;
        $norm =~ s/-+/-/g;

        # Guard clause: Ignore unrelated, malformed, or hostile names.
        # This prevents a bogus key from colliding with valid metadata after normalization.
        next unless $norm =~ /\Ahx-[a-z0-9]+(?:-[a-z0-9]+)*\z/;

        # Some adapters preserve duplicate headers as an array reference.
        # HTTP specs define these fields as single values, so the last defined value wins.
        if (ref($val) eq 'ARRAY') {
            ($val) = reverse grep { defined && !ref } @$val;
        }
        next if ref $val;

        # Prioritize real HTTP header spellings over CGI/PSGI environment spellings
        # if an adapter accidentally supplies both down the pipeline.
        next if exists($priority{$norm}) && $priority{$norm} > $rank;

        $normalized{$norm} = $val;
        $priority{$norm} = $rank;
    }

    return \%normalized;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Uniform::Utils - Shared production-grade utility functions for Uniform ecosystem authors

=head1 FUNCTIONS

=head2 normalize_http_headers( \%raw_hash )

Accepts a raw hash reference of incoming network parameters and transforms them into a
clean, normalized data model based on strict ecosystem validation criteria:

=over 4

=item * B<Case Insensitivity>: All incoming keys are lowercased and bounding whitespace is stripped.

=item * B<Environment Pruning>: CGI/PSGI C<HTTP_> and C<HTTP-> environment prefixes are safely removed.

=item * B<Priority Ranking>: Real HTTP header definitions cleanly take precedence over environment-variable duplicates.

=item * B<Array Reduction>: Duplicate incoming headers packed into array references are automatically reduced down to the last scalar definition.

=item * B<Security Sandboxing>: Keys failing structural validation checks are rejected entirely, filtering out malicious header manipulation or collision vectors.

=back

=cut
