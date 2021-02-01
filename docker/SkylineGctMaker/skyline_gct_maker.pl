#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Text::CSV_XS;

my $lc = 0;
my @allheaders;
my $working_dir = $ARGV[0];
my $base_name = $ARGV[1];
my $report_name = $ARGV[2];
my $new_sample_key = "RatioLightToHeavy";
if ($#ARGV > 2) {
	$new_sample_key = $ARGV[3];
}
my @probe_annotation_fields;
my @sample_annotation_fields;
my %sample_starting_columns;
my @sample_order;
my $PROBE_ANNOT_FLAG = 0;
my $FIRST_SAMPLE_FLAG = 1;
my $GENERIC_SAMPLE_FLAG = 2;
my $FLAG = $PROBE_ANNOT_FLAG;
my $current_samplename_offset;
my $first_line_string = "";
my @gct_document;
my %sample_annotation_field_index;
my $csv = Text::CSV_XS->new();

my $gct_name = $working_dir."/".$base_name.".gct";
print STDERR "Report Name Received ".($report_name)."\n";
print STDERR "GCT to be created: ".($gct_name)."\n";

my $edited_report_name;

sub StripEmptyColumns
{
	my $csvFile = Text::CSV_XS->new ({ keep_meta_info => 1, quote_space => 0 });
	open my $ifh, '<', $report_name or die "Failed to open report\n";

	#Get column headers
    my $rowRef = $csvFile->getline($ifh);
	my @columns = @$rowRef;
	my $colCount = scalar(@columns);
	my @filled_columns = ();
	my %rep_annotations =();
	my @values = ();
	# Read the rows
	my $rowCount = 0;
	while($rowRef = $csvFile->getline($ifh))
	{
		my @row_values = @$rowRef;
		my $cell_count = scalar(@row_values);
		if($cell_count != $colCount)
		{
			die "Unexpected number of values in row: " . $cell_count . " Expected: " . $colCount;
		}
		my $col = 0;
		for (my $i = 0; $i < $cell_count; $i++) 
		{
			my $value = $row_values[$i];
			$values[$rowCount][$col] = $value;
			if(length(trim($value)) > 0)
			{
				# If the value is not an empty string, then this column will be included in the output
				$filled_columns[$i] = 1;
				my $annotation = $columns[$i];    # Name of the annotation
				my $idx = index $annotation, " "; # Replicate annotation column headers include the replicate name 
				                                  # and annotation separated by a space, e.g. A01_acq_01 pert_batch_id
				if($idx != -1)
				{
					$annotation = substr $annotation, $idx; # Name of the annotation minus the replicate name
					# Remember replicate annotations that had a value in any replicate.
					# It is possible that the annotation does not have values for some of the replicates.
					# The column would be blank for those replicates. We don't want to exclude them
					$rep_annotations{$annotation} = 1; 
				}
			}
			$col++;
		}
		$rowCount++;
	}
	close $ifh;
	
	my @keep_columns = ();
	for (my $i = 0; $i < $colCount; $i++)
	{
		if(!$filled_columns[$i])
		{
			my $annotation = $columns[$i];
			my $idx = index $annotation, " ";
			if($idx != -1)
			{
			    # This is a replicate annotation column, e.g. A01_acq_01 pert_batch_id
				$annotation = substr $annotation, $idx; # Name of the annotation minus the replicate name
				if(exists $rep_annotations{$annotation})
				{
					# We will include the column since there was at least one replicate where the value for this
					# annotation was not blank. Haven't yet seen any examples of this, though.
					print STDOUT "Adding back replicate annotation column " . $columns[$i] ."\n";
					$keep_columns[$i] = 1;
				}
			}
		}
		else
		{
			$keep_columns[$i] = 1;
		}
	}
	
	$edited_report_name = $report_name . "_minus_blank_columns.csv";
	open my $ofh, '>', $edited_report_name or die $!;
	
	# Print the column headers
	my $excluded = 0;
	my @colsToPrint = ();
	for (my $i = 0; $i < $colCount; $i++)
	{
		if(!$keep_columns[$i])
		{
			print STDOUT "Excluding column " . $columns[$i] . "\n";
			$excluded++;
			next;
		}
		push(@colsToPrint, $columns[$i]);
	}
	$csvFile->print($ofh, \@colsToPrint);
	print $ofh "\n";
	print STDOUT "Excluded " . $excluded . " columns.\n";

	# Print rows
	for (my $r = 0; $r < $rowCount; $r++) 
	{
		my @valsToPrint = ();
		for (my $c = 0; $c < $colCount; $c++)
		{
			if(!$keep_columns[$c])
			{
			 	next;
			}
			
			my $val = $values[$r][$c];
			push(@valsToPrint, $val);
		}
		$csvFile->print($ofh, \@valsToPrint);
		print $ofh "\n";
	}
	close $ofh;
}
# Trim function to remove whitespace from the start and end of the string
sub trim($)
{
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}

sub WriteGct
{
	open(RFH,$edited_report_name) || die "Failed to open report\n";

	while (<RFH>) {
		# chomp;
		my $line = $_;
		$line =~ s/\r|\n//g; # remove Windows CR
		my $csvparts = $csv->parse($line);
		my @parts = $csv->fields();
		if ($lc == 0) {
			for (my $i=0;$i<=$#parts;$i++) {
				#print "$i\t$FLAG\n";
				if ($parts[$i] =~ m/($new_sample_key)/g) {
					my $offset = pos($parts[$i])-length($new_sample_key);
					my $current_sample_name = substr($parts[$i],0,$offset-1);
					$sample_starting_columns{$current_sample_name} = $i;
					push @sample_order,$current_sample_name;
					$current_samplename_offset = $offset;
					if ($FLAG == $PROBE_ANNOT_FLAG) {
						$FLAG = $FIRST_SAMPLE_FLAG;
					} elsif ($FLAG == $FIRST_SAMPLE_FLAG) {
						$FLAG = $GENERIC_SAMPLE_FLAG;
					} 
					$first_line_string.=$current_sample_name;
					$first_line_string.="\t";
					next;
				}

				if ($FLAG == $PROBE_ANNOT_FLAG) {
					push @probe_annotation_fields,$parts[$i];
					$first_line_string.=$parts[$i];
					$first_line_string.="\t";
				} 
				elsif ($FLAG == $FIRST_SAMPLE_FLAG) {
					#do stuff
					my $current_sample_annotation_field = substr($parts[$i],$current_samplename_offset);
					push @sample_annotation_fields,$current_sample_annotation_field;
					$sample_annotation_field_index{$current_sample_annotation_field}=$#sample_annotation_fields;
				}
				elsif ($FLAG == $GENERIC_SAMPLE_FLAG) {
					#do stuff
				}
			}
			#exchange last tab for newline
			substr($first_line_string,-1)="\n";
			push @gct_document,$first_line_string;
			#maybe re-write first line to list id as sample key.
			#print "$first_line_string\n";
			#exit;
			#print Dumper %sample_annotation_field_index;
			#exit;
		} elsif ($lc == 1) {
			#collect the sample annots
			my $index_last_probe_annot_field = $#probe_annotation_fields;
			for (my $j=0;$j<=$#sample_annotation_fields;$j++) {
				my $current_gct_line=($sample_annotation_fields[$j])."\t";
				for (my $k=1;$k<=$index_last_probe_annot_field;$k++) {
					$current_gct_line.="NA\t";
				}
				#print "ANNOTATION: ".($sample_annotation_fields[$j])."\n";
				#print "-----------------------------------------------\n";
				#print $#parts;
				#print "\n";
				#print $#sample_order;
				#print "\n";
				for (my $m=0;$m<=$#sample_order;$m++) {
					#print "$m\t";
					my $annotation_column = $sample_starting_columns{$sample_order[$m]}+$j+1;
					#print "$annotation_column\t";
					#print $parts[$annotation_column];
					#print "\n";
					$current_gct_line.=$parts[$annotation_column];
					$current_gct_line.="\t";
				}
				#exchange last tab for newline
				substr($current_gct_line,-1)="\n";
				push @gct_document,$current_gct_line;
			}
			#but now we still need to get the data from the first line
			my @_temp_gct_line;
			for (my $n=0;$n<=$index_last_probe_annot_field;$n++) {
				push @_temp_gct_line,$parts[$n];
			}
			for (my $p=0;$p<=$#sample_order;$p++) {
				push @_temp_gct_line,$parts[$sample_starting_columns{$sample_order[$p]}];
			}
			my $gct_line = join("\t",@_temp_gct_line)."\n";
			push @gct_document,$gct_line;
		}
		else {
			#just collect data
			my $index_last_probe_annot_field = $#probe_annotation_fields;
			my @_temp_gct_line;
			for (my $n=0;$n<=$index_last_probe_annot_field;$n++) {
				push @_temp_gct_line,$parts[$n];
			}
			for (my $p=0;$p<=$#sample_order;$p++) {
				push @_temp_gct_line,$parts[$sample_starting_columns{$sample_order[$p]}];
			}
			my $gct_line = join("\t",@_temp_gct_line)."\n";
			push @gct_document,$gct_line;
		}
		$lc++;
	}
	close (RFH);

	my $num_probes = $lc-1;
	my $num_samples = $#sample_order + 1;
	my $num_probe_annot_fields = $#probe_annotation_fields;
	my $num_sample_annot_fields = $#sample_annotation_fields+1;

	print STDOUT "#1.3\n";
	print STDOUT "$num_probes\t$num_samples\t$num_probe_annot_fields\t$num_sample_annot_fields\n";
	for (my $j=0;$j<=$#gct_document;$j++) {
		print STDOUT $gct_document[$j];
	}

	open (OF,">$gct_name") || die "Could create report $gct_name\n";
	print OF "#1.3\n";
	print OF "$num_probes\t$num_samples\t$num_probe_annot_fields\t$num_sample_annot_fields\n";
	for (my $j=0;$j<=$#gct_document;$j++) {
		print OF $gct_document[$j];
	}
	close(OF);
}
StripEmptyColumns();
WriteGct();

