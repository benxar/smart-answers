module SmartAnswer::Calculators
  class MarriageAbroadCalculator
    attr_accessor :ceremony_country
    attr_writer :resident_of
    attr_writer :partner_nationality
    attr_writer :sex_of_your_partner
    attr_writer :marriage_or_pacs

    def initialize(data_query: nil, country_name_formatter: nil, registrations_data_query: nil)
      @data_query = data_query || MarriageAbroadDataQuery.new
      @country_name_formatter = country_name_formatter || CountryNameFormatter.new
      @registrations_data_query = registrations_data_query || RegistrationsDataQuery.new
    end

    def partner_british?
      @partner_nationality == 'partner_british'
    end

    def partner_not_british?
      !partner_british?
    end

    def partner_is_national_of_ceremony_country?
      @partner_nationality == 'partner_local'
    end

    def partner_is_not_national_of_ceremony_country?
      !partner_is_national_of_ceremony_country?
    end

    def partner_is_neither_british_nor_a_national_of_ceremony_country?
      @partner_nationality == 'partner_other'
    end

    def resident_of_uk?
      @resident_of == 'uk'
    end

    def resident_outside_of_uk?
      !resident_of_uk?
    end

    def resident_of_ceremony_country?
      @resident_of == 'ceremony_country'
    end

    def resident_outside_of_ceremony_country?
      !resident_of_ceremony_country?
    end

    def resident_of_third_country?
      @resident_of == 'third_country'
    end

    def resident_outside_of_third_country?
      !resident_of_third_country?
    end

    def partner_is_opposite_sex?
      @sex_of_your_partner == 'opposite_sex'
    end

    def partner_is_same_sex?
      @sex_of_your_partner == 'same_sex'
    end

    def want_to_get_married?
      @marriage_or_pacs == 'marriage'
    end

    def world_location
      WorldLocation.find(ceremony_country) || raise(SmartAnswer::InvalidResponse)
    end

    def ceremony_country_name
      world_location.name
    end

    def fco_organisation
      world_location.fco_organisation
    end

    def overseas_passports_embassies
      if fco_organisation
        fco_organisation.offices_with_service 'Registrations of Marriage and Civil Partnerships'
      else
        []
      end
    end

    def marriage_and_partnership_phrases
      if same_sex_marriage_country? || same_sex_marriage_country_when_couple_british?
        'ss_marriage'
      elsif same_sex_marriage_and_civil_partnership?
        'ss_marriage_and_partnership'
      end
    end

    def country_name_lowercase_prefix
      if @country_name_formatter.requires_definite_article?(ceremony_country)
        @country_name_formatter.definitive_article(ceremony_country)
      elsif @country_name_formatter.has_friendly_name?(ceremony_country)
        @country_name_formatter.friendly_name(ceremony_country).html_safe
      else
        ceremony_country_name
      end
    end

    def country_name_uppercase_prefix
      @country_name_formatter.definitive_article(ceremony_country, true)
    end

    def country_name_partner_residence
      if ceremony_country_is_british_overseas_territory?
        'British (overseas territories citizen)'
      elsif ceremony_country_is_french_overseas_territory?
        'French'
      elsif ceremony_country_is_dutch_caribbean_island?
        'Dutch'
      elsif %w(hong-kong macao).include?(ceremony_country)
        'Chinese'
      else
        "National of #{country_name_lowercase_prefix}"
      end
    end

    def embassy_or_consulate_ceremony_country
      if @registrations_data_query.has_consulate?(ceremony_country) || @registrations_data_query.has_consulate_general?(ceremony_country)
        'consulate'
      else
        'embassy'
      end
    end

    def ceremony_country_is_french_overseas_territory?
      @data_query.french_overseas_territories?(ceremony_country)
    end

    def opposite_sex_consular_cni_country?
      @data_query.os_consular_cni_countries?(ceremony_country)
    end

    def opposite_sex_consular_cni_in_nearby_country?
      @data_query.os_consular_cni_in_nearby_country?(ceremony_country)
    end

    def opposite_sex_no_marriage_related_consular_services_in_ceremony_country?
      @data_query.os_no_marriage_related_consular_services?(ceremony_country)
    end

    def opposite_sex_affirmation_country?
      @data_query.os_affirmation_countries?(ceremony_country)
    end

    def ceremony_country_in_the_commonwealth?
      @data_query.commonwealth_country?(ceremony_country)
    end

    def ceremony_country_is_british_overseas_territory?
      @data_query.british_overseas_territories?(ceremony_country)
    end

    def opposite_sex_no_consular_cni_country?
      @data_query.os_no_consular_cni_countries?(ceremony_country)
    end

    def opposite_sex_marriage_via_local_authorities?
      @data_query.os_marriage_via_local_authorities?(ceremony_country)
    end

    def opposite_sex_in_other_countries?
      @data_query.os_other_countries?(ceremony_country)
    end

    def same_sex_ceremony_country_unknown_or_has_no_embassies?
      @data_query.ss_unknown_no_embassies?(ceremony_country)
    end

    def same_sex_marriage_not_possible?
      @data_query.ss_marriage_not_possible?(ceremony_country, self)
    end

    def same_sex_marriage_country?
      @data_query.ss_marriage_countries?(ceremony_country)
    end

    def same_sex_marriage_country_when_couple_british?
      @data_query.ss_marriage_countries_when_couple_british?(ceremony_country)
    end

    def same_sex_marriage_and_civil_partnership?
      @data_query.ss_marriage_and_partnership?(ceremony_country)
    end

    def civil_partnership_equivalent_country?
      @data_query.cp_equivalent_countries?(ceremony_country)
    end

    def civil_partnership_cni_not_required_country?
      @data_query.cp_cni_not_required_countries?(ceremony_country)
    end

    def civil_partnership_consular_country?
      @data_query.cp_consular_countries?(ceremony_country)
    end

    def country_without_consular_facilities?
      @data_query.countries_without_consular_facilities?(ceremony_country)
    end

    def opposite_sex_21_days_residency_required?
      @data_query.os_21_days_residency_required_countries?(ceremony_country)
    end

    def ceremony_country_is_dutch_caribbean_island?
      @data_query.dutch_caribbean_islands?(ceremony_country)
    end

    def requires_7_day_notice?
      @data_query.requires_7_day_notice?(ceremony_country)
    end

    def same_sex_alt_fees_table_country?
      @data_query.ss_alt_fees_table_country?(ceremony_country, self)
    end

    def civil_partnership_institution_name
      if ceremony_country == 'cyprus'
        'High Commission'
      else
        'British embassy or consulate'
      end
    end
  end
end
