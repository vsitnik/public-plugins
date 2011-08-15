package EnsEMBL::Selenium::Test::Location;
use strict;
use base 'EnsEMBL::Selenium::Test::Species';
use Test::More; 

__PACKAGE__->set_default('timeout', 5000);
#------------------------------------------------------------------------------
# Ensembl Location link test
# Can add more cases or extend the existing test cases
#------------------------------------------------------------------------------
sub test_location {
  my ($self) = @_;
  my $sel    = $self->sel;
  my $SD     = $self->get_species_def;

  $self->open_species_homepage($self->species);  
  my $location_text = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{LOCATION_TEXT};

  if($location_text) {
    $sel->ensembl_click_links(["link=Location ($location_text)"]);
    my @location_array = split(/\:/,$location_text);
    $sel->ensembl_is_text_present($SD->thousandify(@location_array[1]))
    and $sel->ensembl_is_text_present("Region in detail");
#    and $sel->ensembl_images_loaded;

    #Test ZMENU (only for human)
    if($self->species eq 'homo_sapiens') {
      $self->attach_das;
      $sel->ensembl_wait_for_ajax(15000);
      
      $sel->ensembl_open_zmenu('Summary',"class^=drag");
      $sel->click_ok("link=Centre here")
      and $sel->ensembl_wait_for_ajax(undef,'2000')      
      and $sel->go_back();      

      #TODO:: ZMenu on viewtop and ViewBottom panel
    }
    #Whole genome link
    $sel->ensembl_click_links(["link=Whole genome"]);
    $sel->ensembl_is_text_present("This genome has yet to be assembled into chromosomes") if(!scalar @{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')});

    @location_array[0] =~ s/chr//;
    #Chromosome summary link (only click for sepcies with chromosome)
    if(grep(/@location_array[0]/,@{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')})) {
      $sel->ensembl_click_links(["link=Chromosome summary"]);
      $sel->ensembl_is_text_present("Chromosome Statistics");
    }

    $sel->ensembl_click_links(["link=Region overview","link=Region in detail","link=Comparative Genomics"]);

    my %synteny_hash  = $SD->multi('DATABASE_COMPARA', 'SYNTENY');    
    my $synteny_count = scalar keys %{$synteny_hash{ucfirst($self->species)}};
    my %alignments    = $SD->multi('DATABASE_COMPARA', 'ALIGNMENTS');
    
    my ($alignment_count,$multi_species_count) = $self->alignments_count($SD);

    $sel->ensembl_click_links(["link=Alignments (image) ($alignment_count)","link=Alignments (text) ($alignment_count)","link=Multi-species view ($multi_species_count)"],'8000') if($alignment_count);
    $sel->ensembl_click_links(["link=Synteny ($synteny_count)"], '20000') if(grep(/@location_array[0]/,@{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')}) && $synteny_count);

    #Markers        
    if($SD->table_info_other(ucfirst($self->species),'core', 'marker_feature')->{'rows'}) {
      $sel->ensembl_click_links(["link=Markers"], '8000');

      if($self->species eq 'homo_sapiens') {
        $sel->ensembl_is_text_present("mapped markers found:");
        $sel->ensembl_click_links(["link=D6S989"]);
        $sel->ensembl_is_text_present("Marker D6S989");
        $sel->go_back();
      }
    }

    #Testing genetic variations last for human only
    if($self->species eq 'homo_sapiens') {
      my $resequencing_counts = $SD->databases(ucfirst($self->species))->{'DATABASE_VARIATION'}{'#STRAINS'} if exists $SD->databases(ucfirst($self->species))->{'DATABASE_VARIATION'};
      $sel->ensembl_click_links(["link=Resequencing ($resequencing_counts)"], '8000');
      $sel->type_ok("loc_r", "6:27996744-27996844");
      $sel->click_ok("//input[\@value='Go']");
      $sel->pause(5000);
      $sel->ensembl_is_text_present("Basepairs in secondary strains");

      $sel->open_ok("Homo_sapiens/Location/LD?db=core;r=6:27996744-27996844;pop1=12131");
      $sel->pause(5000);
      $sel->ensembl_is_text_present("Prediction method:");
      
      $sel->ensembl_click_links(["link=Region in detail"]);
      $self->export_data('CSV (Comma separated values)','seqname,source');
    }

  } else {
    print "  No Location \n";
    $sel->ensembl_is_text_present("Location (not available)");
  }
}
1;