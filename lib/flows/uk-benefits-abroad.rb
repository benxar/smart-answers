satisfies_need "392"
status :draft

exclude_countries = %w(holy-see british-antarctic-territory)
situations = ['going_abroad','already_abroad']
eea_countries = %w(austria belgium bulgaria croatia cyprus czech-republic denmark estonia finland france germany gibraltar greece hungary iceland ireland italy latvia liechtenstein lithuania luxembourg malta netherlands norway poland portugal romania slovakia slovenia spain sweden switzerland)
former_yugoslavia = %w(bosnia-and-herzegovina kosovo macedonia montenegro serbia)
social_security_countries_jsa = former_yugoslavia + %w(guernsey_jersey new-zealand)
social_security_countries_mat = former_yugoslavia + %w(barbados guernsey_jersey israel turkey)
social_security_countries_iidb = former_yugoslavia + %w(barbados bermuda guernsey_jersey israel jamaica mauritius philippines turkey)
social_security_countries_bereavement_benefits = former_yugoslavia + %w(barbados bermuda canada guernsey_jersey israel jamaica mauritius new-zealand philippines turkey usa)

# Q1
multiple_choice :going_or_already_abroad? do
  option :going_abroad
  option :already_abroad
  save_input_as :going_or_already_abroad

  calculate :question_titles do
    if responses.last == 'going_abroad'
      PhraseList.new(:going_abroad_country_question_title)
    else
      PhraseList.new(:already_abroad_country_question_title)
    end
  end

  calculate :how_long_question_titles do
    if responses.last == 'going_abroad'
      PhraseList.new(:going_abroad_how_long_question_title)
    else
      PhraseList.new(:already_abroad_how_long_question_title)
    end
  end

  calculate :channel_islands_question_titles do
    if responses.last == 'going_abroad'
      PhraseList.new(:ci_going_abroad_question_title)
    else
      PhraseList.new(:ci_already_abroad_question_title)
    end
  end

  calculate :channel_islands_prefix do
    if responses.last == 'going_abroad'
      PhraseList.new(:ci_going_abroad_prefix)
    else
      PhraseList.new(:ci_already_abroad_prefix)
    end
  end

  calculate :already_abroad_text do
    if responses.last == 'already_abroad'
      PhraseList.new(:already_abroad_text)
    end
  end

  calculate :already_abroad_text_two do
    if responses.last == 'already_abroad'
      PhraseList.new(:already_abroad_text_two)
    end
  end


  calculate :iidb_maybe do
    if responses.last == 'already_abroad'
      PhraseList.new(:iidb_maybe_text)
    end
  end

  next_node :which_benefit?
end

# Q2
multiple_choice :which_benefit? do
  option :jsa
  option :pension
  option :winter_fuel_payment
  option :maternity_benefits
  option :child_benefits
  option :iidb
  option :ssp
  option :esa
  option :disability_benefits
  option :bereavement_benefits
  option :tax_credits
  option :income_support

  save_input_as :benefit

  next_node do |response|
    case response
    when 'jsa'
      if going_or_already_abroad == 'going_abroad'
        :jsa_how_long_abroad?
      else
        :channel_islands?
      end
    when 'pension'
      if going_or_already_abroad == 'going_abroad'
        :pension_going_abroad_outcome # A8
      else
        :pension_already_abroad_outcome # A9
      end
    when 'winter_fuel_payment'
      :which_country_wfp?
    when 'maternity_benefits'
      :channel_islands?
    when 'child_benefits'
      :channel_islands?
    when 'iidb'
      :iidb_already_claiming?
    when 'ssp'
      :which_country_ssp?
    when 'esa'
      :esa_how_long_abroad?
    when 'disability_benefits'
      :db_how_long_abroad?
    when 'bereavement_benefits'
      :channel_islands?
    when 'tax_credits'
      :eligible_for_tax_credits?
    when 'income_support'
      if going_or_already_abroad == 'going_abroad'
        :is_how_long_abroad?
      else
        :income_support_already_abroad_outcome
      end
    end
  end
end

# Q3a going abroad
multiple_choice :jsa_how_long_abroad? do
  option :less_than_a_year_medical => :jsa_less_than_a_year_medical_outcome # A1
  option :less_than_a_year_other => :jsa_less_than_a_year_other_outcome # A2
  option :more_than_a_year => :channel_islands? # Q3b
end

# Q3b
multiple_choice :channel_islands? do
  option :guernsey_jersey
  option :abroad

  save_input_as :country

  calculate :country_name do
    if responses.last == 'guernsey_jersey'
      PhraseList.new(:ci_country_name)
    end
  end

  next_node do |response|
    if response == 'abroad'
      :"which_country_#{benefit}?"
    else
      if benefit == 'jsa'
        :"jsa_social_security_#{going_or_already_abroad}_outcome"
      elsif benefit == 'maternity_benefits'
        :employer_paying_ni?
      elsif benefit == 'child_benefits'
        :child_benefits_ss_outcome
      elsif benefit == 'iidb'
        :"iidb_#{going_or_already_abroad}_ss_outcome"
      else
        ''
      end
    end
  end
end

# Q3c
country_select :which_country_jsa?, :exclude_countries => exclude_countries do
  situations.each do |situation|
    key = :"which_country_#{situation}_jsa"
    precalculate key do
      PhraseList.new key
    end
  end

  save_input_as :country

  calculate :country_name do
    WorldLocation.all.find { |c| c.slug == country }.name
  end

  next_node do |response|
    if eea_countries.include?(response)
      :"jsa_eea_#{going_or_already_abroad}_outcome" # A3 or A4
    elsif social_security_countries_jsa.include?(response)
      :"jsa_social_security_#{going_or_already_abroad}_outcome" # A5 or A6
    else
      :jsa_not_entitled_outcome # A7
    end
  end
end

# Q4
country_select :which_country_wfp?, :exclude_countries => exclude_countries do
  situations.each do |situation|
    key = :"which_country_#{situation}_wfp"
    precalculate key do
      PhraseList.new key
    end
  end

  next_node do |response|
    if eea_countries.include?(response)
      :wfp_eea_eligible_outcome # A10
    else
      :wfp_not_eligible_outcome # A11
    end
  end
end

# Q5
country_select :which_country_maternity_benefits?, :exclude_countries => exclude_countries do
  save_input_as :country
  situations.each do |situation|
    key = :"which_country_#{situation}_maternity"
    precalculate key do
      PhraseList.new key
    end
  end

  next_node do |response|
    if eea_countries.include?(response)
      :working_for_a_uk_employer? 
    else
      :employer_paying_ni? 
    end
  end
end

# Q6
multiple_choice :working_for_a_uk_employer? do
  option :yes => :eligible_for_smp?
  option :no => :maternity_benefits_maternity_allowance_outcome # A12
end

# Q7
multiple_choice :eligible_for_smp? do
  option :yes => :maternity_benefits_eea_entitled_outcome # A13
  option :no => :maternity_benefits_maternity_allowance_outcome # A12
end

# Q8
multiple_choice :employer_paying_ni? do
  option :yes
  option :no

  next_node do |response|
    if response == 'yes'
      :eligible_for_smp?
    else
      if social_security_countries_mat.include?(country)
        :"maternity_benefits_social_security_#{going_or_already_abroad}_outcome" # A14 or A15
      else
        :maternity_benefits_not_entitled_outcome # A17
      end
    end
  end
end

# Q9
country_select :which_country_child_benefits?, :exclude_countries => exclude_countries do
  save_input_as :country
  situations.each do |situation|
    key = :"which_country_#{situation}_child"
    precalculate key do
      PhraseList.new key
    end
  end

  save_input_as :country

  calculate :country_name do
    WorldLocation.all.find { |c| c.slug == country }.name
  end

  next_node do |response|
    if eea_countries.include?(response)
      :do_either_of_the_following_apply? # Q10
    elsif former_yugoslavia.include?(response)
      :"child_benefits_fy_#{going_or_already_abroad}_outcome" # A17 or A18
    elsif %w(barbados canada israel mauritius new-zealand).include?(response)
      :child_benefits_ss_outcome # A19
    elsif %w(jamaica turkey usa).include?(response)
      :child_benefits_jtu_outcome # A20
    else
      :child_benefits_not_entitled_outcome # A22
    end
  end
end

# Q10
multiple_choice :do_either_of_the_following_apply? do
  option :yes => :child_benefits_entitled_outcome # A21
  option :no => :child_benefits_not_entitled_outcome # A22
end

# Q11
country_select :which_country_ssp?, :exclude_countries => exclude_countries do
  save_input_as :country
  situations.each do |situation|
    key = :"which_country_#{situation}_ssp"
    precalculate key do
      PhraseList.new key
    end
  end

  save_input_as :country

  calculate :country_name do
    WorldLocation.all.find { |c| c.slug == country }.name
  end

  next_node do |response|
    if eea_countries.include?(response)
      :working_for_uk_employer_ssp? # Q12
    else
      :employer_paying_ni_ssp? # Q13
    end
  end
end

# Q12
multiple_choice :working_for_uk_employer_ssp? do
  option :yes
  option :no

  next_node do |response|
    if response == 'yes'
      :"ssp_#{going_or_already_abroad}_entitled_outcome" # A23 or A24
    else
      :"ssp_#{going_or_already_abroad}_not_entitled_outcome" # A25 or A26
    end
  end
end

# Q13
multiple_choice :employer_paying_ni_ssp? do
  option :yes
  option :no

  next_node do |response|
    if response == 'yes'
      :"ssp_#{going_or_already_abroad}_entitled_outcome" # A23 or A24
    else
      :"ssp_#{going_or_already_abroad}_not_entitled_outcome" # A25 or A26
    end
  end
end

# Q14
multiple_choice :eligible_for_tax_credits? do
  option :crown_servant
  option :cross_border_worker
  option :none_of_the_above

  next_node do |response|
    if response == 'crown_servant'
      :tax_credits_crown_servant_outcome # A27
    elsif response == 'cross_border_worker'
      :tax_credits_cross_border_worker_outcome # A28
    else
      :tax_credits_how_long_abroad?
    end
  end
end

# Q15
multiple_choice :tax_credits_how_long_abroad? do
  option :tax_credits_up_to_a_year => :tax_credits_why_going_abroad? # Q19
  option :tax_credits_more_than_a_year => :tax_credits_children? # Q16
end

# Q16
multiple_choice :tax_credits_children? do
  option :yes => :which_country_tax_credits? # Q17
  option :no => :tax_credits_unlikely_outcome # A29
end

# Q17
country_select :which_country_tax_credits?, :exclude_countries => exclude_countries do
  save_input_as :country
  situations.each do |situation|
    key = :"which_country_#{situation}_tax_credits"
    precalculate key do
      PhraseList.new key
    end
  end

  save_input_as :country

  calculate :country_name do
    WorldLocation.all.find { |c| c.slug == country }.name
  end

  next_node do |response|
    if eea_countries.include?(response)
      :tax_credits_currently_claiming? # Q18
    else
      :tax_credits_unlikely_outcome # A29
    end
  end
end

# Q18
multiple_choice :tax_credits_currently_claiming? do
  option :yes => :tax_credits_eea_entitled_outcome # A30
  option :no => :tax_credits_unlikely_outcome # A29
end

# Q19
multiple_choice :tax_credits_why_going_abroad? do
  option :tax_credits_holiday => :tax_credits_holiday_outcome # A31
  option :tax_credits_medical_treatment => :tax_credits_medical_death_outcome #A32
  option :tax_credits_death => :tax_credits_medical_death_outcome #A32
end


# Q20
multiple_choice :esa_how_long_abroad? do
  option :esa_under_a_year_medical
  option :esa_under_a_year_other
  option :esa_more_than_a_year

  next_node do |response|
    case response
    when 'esa_under_a_year_medical'
      :"esa_#{going_or_already_abroad}_under_a_year_medical_outcome"
    when 'esa_under_a_year_other'
      :"esa_#{going_or_already_abroad}_under_a_year_other_outcome"
    else
      :which_country_esa?
    end
  end
end

# Q21
country_select :which_country_esa?, :exclude_countries => exclude_countries do
  save_input_as :country
  situations.each do |situation|
    key = :"which_country_#{situation}_esa"
    precalculate key do
      PhraseList.new key
    end
  end

  save_input_as :country

  calculate :country_name do
    WorldLocation.all.find { |c| c.slug == country }.name
  end

  next_node do |response|
    if eea_countries.include?(response)
      :"esa_#{going_or_already_abroad}_eea_outcome" # A37 or # A38
    else
      :"esa_#{going_or_already_abroad}_other_outcome" # A39 or A40
    end
  end
end

# Q22
multiple_choice :iidb_already_claiming? do
  option :yes => :channel_islands? # Q3b
  option :no => :iidb_maybe_outcome # A41
end

# Q23
country_select :which_country_iidb?, :exclude_countries => exclude_countries do
  save_input_as :country
  situations.each do |situation|
    key = :"which_country_#{situation}_esa"
    precalculate key do
      PhraseList.new key
    end
  end

  save_input_as :country

  calculate :country_name do
    WorldLocation.all.find { |c| c.slug == country }.name
  end

  next_node do |response|
    if eea_countries.include?(response)
      :"iidb_#{going_or_already_abroad}_eea_outcome" # A42 or A43
    elsif social_security_countries_iidb.include?(response)
      :"iidb_#{going_or_already_abroad}_ss_outcome" # A44 or A45
    else
      :"iidb_#{going_or_already_abroad}_other_outcome" # A46 or A47
    end
  end
end


outcome :jsa_less_than_a_year_medical_outcome # A1
outcome :jsa_less_than_a_year_other_outcome # A2
outcome :jsa_eea_going_abroad_outcome # A3
outcome :jsa_eea_already_abroad_outcome # A4
outcome :jsa_social_security_going_abroad_outcome # A5
outcome :jsa_social_security_already_abroad_outcome # A6
outcome :jsa_not_entitled_outcome # A7
outcome :pension_going_abroad_outcome # A8
outcome :pension_already_abroad_outcome # A9
outcome :wfp_eea_eligible_outcome # A10
outcome :wfp_not_eligible_outcome # A11
outcome :maternity_benefits_maternity_allowance_outcome # A12
outcome :maternity_benefits_eea_entitled_outcome # A13
outcome :maternity_benefits_social_security_going_abroad_outcome # A14
outcome :maternity_benefits_social_security_already_abroad_outcome # A15
outcome :maternity_benefits_not_entitled_outcome # A16
outcome :child_benefits_fy_going_abroad_outcome # A17
outcome :child_benefits_fy_already_abroad_outcome # A18
outcome :child_benefits_ss_outcome # A19
outcome :child_benefits_jtu_outcome # A20
outcome :child_benefits_entitled_outcome # A21
outcome :child_benefits_not_entitled_outcome # A22
outcome :ssp_going_abroad_entitled_outcome # A23
outcome :ssp_already_abroad_entitled_outcome # A24
outcome :ssp_going_abroad_not_entitled_outcome # A25
outcome :ssp_already_abroad_not_entitled_outcome # A26
outcome :tax_credits_crown_servant_outcome do # A27
  precalculate :tax_credits_crown_servant do
    if going_or_already_abroad == 'going_abroad'
      PhraseList.new(:tax_credits_going_abroad_helpline)
    else
      PhraseList.new(:tax_credits_already_abroad_helpline)
    end
  end
end

outcome :tax_credits_cross_border_worker_outcome do # A28
  precalculate :tax_credits_cross_border_worker do
    if going_or_already_abroad == 'going_abroad'
      PhraseList.new(:tax_credits_cross_border_going_abroad, :tax_credits_cross_border, :tax_credits_going_abroad_helpline)
    else
      PhraseList.new(:tax_credits_cross_border_already_abroad, :tax_credits_cross_border, :tax_credits_already_abroad_helpline)
    end  
  end
end

outcome :tax_credits_unlikely_outcome #A29
outcome :tax_credits_eea_entitled_outcome # A30
outcome :tax_credits_holiday_outcome do # A31
  precalculate :tax_credits_holiday do
    if going_or_already_abroad == 'going_abroad'
      PhraseList.new(:tax_credits_holiday_going_abroad, :tax_credits_holiday, :tax_credits_going_abroad_helpline)
    else
      PhraseList.new(:tax_credits_holiday_already_abroad, :tax_credits_holiday, :tax_credits_already_abroad_helpline)
    end
  end
end

outcome :tax_credits_medical_death_outcome do # A32
  precalculate :tax_credits_medical_death do
    if going_or_already_abroad == 'going_abroad'
      PhraseList.new(:tax_credits_medical_death_going_abroad, :tax_credits_medical_death, :tax_credits_going_abroad_helpline)
    else
      PhraseList.new(:tax_credits_medical_death_already_abroad, :tax_credits_medical_death, :tax_credits_already_abroad_helpline)
    end
  end
end

outcome :esa_going_abroad_under_a_year_medical_outcome # A33
outcome :esa_already_abroad_under_a_year_medical_outcome # A34
outcome :esa_going_abroad_under_a_year_other_outcome # A35
outcome :esa_already_abroad_under_a_year_other_outcome # A36
outcome :esa_going_abroad_eea_outcome # A37
outcome :esa_already_abroad_eea_outcome # A38
outcome :esa_going_abroad_other_outcome # A39
outcome :esa_already_abroad_other_outcome # A40
outcome :iidb_maybe_outcome # A41
outcome :iidb_going_abroad_eea_outcome # A42
outcome :iidb_already_abroad_eea_outcome # A43
outcome :iidb_going_abroad_ss_outcome # A44 
outcome :iidb_already_abroad_ss_outcome # A45
outcome :iidb_going_abroad_other_outcome # A46
outcome :iidb_already_abroad_other_outcome # A47
