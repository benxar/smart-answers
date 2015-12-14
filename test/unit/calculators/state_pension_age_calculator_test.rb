require_relative "../../test_helper"

module SmartAnswer::Calculators
  class StatePensionAgeCalculatorTest < ActiveSupport::TestCase

    context "female, born 29th Feb 1968" do
      setup do
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "female", dob: Date.parse("1968-02-29"))
      end

      should "be eligible for state pension on 1 March 2034" do
        assert_equal Date.parse("2035-03-01"), @calculator.state_pension_date
      end
    end

    context "current_weekly_rate" do
      should "be 107.45 before 6th April 2013" do
        Timecop.travel(Date.parse("2013-04-05")) do
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
            gender: "male", dob: Date.parse("1950-04-04"), qualifying_years: 30)
          assert_equal 107.45, @calculator.current_weekly_rate
        end
      end

      should "be 110.15 on or after 6th April 2013" do
        Timecop.travel(Date.parse("2013-04-08")) do
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
            gender: "male", dob: Date.parse("1950-04-04"), qualifying_years: 30)
          assert_equal 110.15, @calculator.current_weekly_rate
        end
      end

      should "fall back to the last rate available" do
        Timecop.travel('2045-01-01') do
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
            gender: "male", dob: Date.parse("2000-04-04"), qualifying_years: 29)
          assert @calculator.current_weekly_rate.is_a?(Numeric)
        end
      end
    end

    context "male born 6 April 1957 " do
      setup do
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "female", dob: Date.parse("1957-04-06"))
      end
    end

    context "female born 22 years ago" do
      setup do
        Timecop.travel(Date.parse("2012-10-09"))
      end

      should "return ni_years_to_date = 3 - dob 22 years ago on April" do
        dob = Date.civil(22.years.ago.year, 4, 6)
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "female", dob: dob)
        assert_equal 3, @calculator.available_years
      end

      should "return ni_years_to_date = 3 - dob 22 years ago on July" do
        dob = Date.civil(22.years.ago.year, 7, 6)
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "female", dob: dob)
        assert_equal 3, @calculator.available_years
      end

      should "return ni_years_to_date = 2" do
        dob = Date.civil(22.years.ago.year, 1, 20)
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "female", dob: dob)
        assert_equal 3, @calculator.available_years
      end
    end

    context "test available years functions" do
      context "male born 26 years and one month plus, no qualifying_years" do
        setup do
          dob =  (Date.today - (26.years - 1.month))
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
            gender: "male", dob: dob)
        end

        should "available_years = 6" do
          assert_equal 6, @calculator.available_years
        end
      end

      context "male born 26 years and one month ago, no qualifying_years" do
        setup do
          Timecop.travel(Date.parse("2013-04-06"))
          dob = Date.civil(26.years.ago.year, 3, 6)
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
            gender: "male", dob: dob)
        end

        should "available_years = 7" do
          assert_equal 7, @calculator.available_years
        end
      end

      # NOTE: leave this test in case we need to turn on the day calculation
      # context "male born 26 years and one day in future, no qualifying_years" do
      #   setup do
      #     dob = 1.day.since(26.years.ago)
      #     @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(gender: "male", dob: dob)
      #   end
      #   should "avialable_years = 6" do
      #     assert_equal 6, @calculator.available_years
      #   end
      # end

      context "male born 26 years and one day ago, no qualifying_years" do
        setup do
          Timecop.travel(Date.parse("2013-03-01"))
          dob = Date.civil(26.years.ago.year, 4, 5)
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
            gender: "male", dob: dob)
        end

        should "available_years = 6" do
          assert_equal 6, @calculator.available_years
        end
      end

      context "32 years old with 10 qualifying_years" do
        setup do
          Timecop.travel(Date.parse("2013-03-01"))
          dob = Date.civil(32.years.ago.year, 4, 6)
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
            gender: "female", dob: dob, qualifying_years: 10)
        end

        should "available_years = 12" do
          assert_equal 12, @calculator.available_years
        end
      end

      context "testing what would get if not enough time to get full state pension" do
        should "state that user has 13 remaining years and would get 2/3 of basic pension" do
          Timecop.travel("2012-10-09") do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1960-04-04"), qualifying_years: 7)
            assert_equal 13, @calculator.years_to_pension
            assert_equal 71.63, @calculator.what_you_would_get_if_not_full
          end
        end
      end

      context "(testing years_to_pension)" do
        context "born 1988 before and after 6th April" do
          setup do
            Timecop.travel(Date.parse("2012-10-09"))
          end

          should "return 43 on 4th April " do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1988-04-04"))
            assert_equal 43, @calculator.years_to_pension
          end

          should "return 44 on 8th April " do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1988-04-08"))
            assert_equal 44, @calculator.years_to_pension
          end

          should "return 44 on 6th April " do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1988-04-06"))
            assert_equal 44, @calculator.years_to_pension
          end

          should "return 32 for dob 29/06/77" do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "female", dob: Date.parse("1977-06-29"))
            assert_equal 32, @calculator.years_to_pension
          end

          should "return 3 for dob 03/03/53" do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "female", dob: Date.parse("1953-03-03"))
            assert_equal 3, @calculator.years_to_pension
          end

          should "return 6 for dob 26/12/53" do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1953-12-26"))
            assert_equal 6, @calculator.years_to_pension
          end
        end

        context "born 1977 before and after 6th April" do
          setup do
            Timecop.travel(Date.parse("2012-10-09"))
          end

          should "return 32 on 12th April " do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1977-04-12"))
            assert_equal 32, @calculator.years_to_pension
          end

          should "return 31 on 4th April " do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1977-04-04"))
            assert_equal 31, @calculator.years_to_pension
          end

          should "return 32 on 6th April " do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1977-04-06"))
            assert_equal 32, @calculator.years_to_pension
          end
        end

        context "remaining years tests" do
          setup do
            Timecop.travel(Date.parse("2012-10-09"))
          end

          teardown do
            Timecop.return
          end

          should "state that user has 13 remaining_years" do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
                gender: "male", dob: Date.parse("1960-04-04"), qualifying_years: 21)
            assert_equal 13, @calculator.years_to_pension
          end

          should "state that user has 26 remaining_years" do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
                gender: "male", dob: Date.parse("1972-02-04"), qualifying_years: 13)
            assert_equal 26, @calculator.years_to_pension
          end

          should "state that user has 34 remaining_years" do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
                gender: "male", dob: Date.parse("1978-11-03"), qualifying_years: 13)
            assert_equal 34, @calculator.years_to_pension
          end

          should "state the user has 5 remaining_years" do
            @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
                gender: "male", dob: Date.parse("1952-06-07"), qualifying_years: 33)
            assert_equal 5, @calculator.years_to_pension
          end
        end
      end
    end

    context "state_pension_age tests" do
      context "testing dynamic pension dates" do
        should "be 66 years, date 2029-11-10" do
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1963-11-10"))
          assert_equal "67 years", @calculator.state_pension_age
          assert_equal Date.parse("2030-11-10"), @calculator.state_pension_date
        end

        should "be 68 years, 2047-04-06" do
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1979-04-06"))
          assert_equal "68 years", @calculator.state_pension_age
          assert_equal Date.parse("2047-04-06"), @calculator.state_pension_date
        end

        should "be 68 years, 2052-01-01" do
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1984-01-01"))
          assert_equal "68 years", @calculator.state_pension_age
          assert_equal Date.parse("2052-01-01"), @calculator.state_pension_date
        end
      end

      context "testing set pension dates from data file" do
        should "67 years; 2044-05-06" do
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1977-05-05"))
          assert_equal Date.parse("2044-05-06"), @calculator.state_pension_date
          assert_equal "67 years, 1 day", @calculator.state_pension_age
        end

        should "67 years; dob: 1968-02-29; pension date: 2034-03-01 " do
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1968-02-29"))
          assert_equal "67 years", @calculator.state_pension_age
          assert_equal Date.parse("2035-03-01"), @calculator.state_pension_date
        end

        should "67 years; 2035-10-06 with dob: 1968-10-06" do
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1968-10-06"))
          assert_equal "67 years", @calculator.state_pension_age
          assert_equal Date.parse("2035-10-06"), @calculator.state_pension_date
        end

        should "67 years; 2035-11-05 with dob: 1968-11-05" do
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1968-11-05"))
          assert_equal "67 years", @calculator.state_pension_age
          assert_equal Date.parse("2035-11-05"), @calculator.state_pension_date
        end

        should "67 years; 2035-11-06 with dob: 1968-11-06" do
          @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1968-11-06"))
          assert_equal "67 years", @calculator.state_pension_age
          assert_equal Date.parse("2035-11-06"), @calculator.state_pension_date
        end
      end

      context "tests for state_pension_date dynamic dates" do
        should "male/female born 1950 Apr 06" do
          @calc_male = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1950 Apr 06"))
          @calc_female = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "female", dob: Date.parse("1950 Apr 06"))
          assert_equal Date.parse("06 Apr 2015"), @calc_male.state_pension_date #(:female)
          assert_equal Date.parse("06 May 2010"), @calc_female.state_pension_date #(:female)
        end

        should "male/female born 1953 Dec 05" do
          @calc_male = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1953 Dec 05"))
          @calc_female = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "female", dob: Date.parse("1953 Dec 05"))
          assert_equal Date.parse("05 Dec 2018"), @calc_male.state_pension_date #(:female)
          assert_equal Date.parse("06 Nov 2018"), @calc_female.state_pension_date #(:female)
        end

        should "male/female born 1953 Dec 06" do
          @calc_male = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1953 Dec 06"))
          @calc_female = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "female", dob: Date.parse("1953 Dec 06"))
          assert_equal Date.parse("06 Mar 2019"), @calc_male.state_pension_date #(:female)
          assert_equal Date.parse("06 Mar 2019"), @calc_female.state_pension_date #(:female)
        end
      end

      context "testing state_pension_date with female" do
        should "male/female born 1953 Dec 05" do
          @calc_male = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "male", dob: Date.parse("1953 Dec 05"))
          @calc_female = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
              gender: "female", dob: Date.parse("1953 Dec 05"))
          assert_equal Date.parse("06 Nov 2018"), @calc_male.state_pension_date(:female)
          assert_equal Date.parse("06 Nov 2018"), @calc_female.state_pension_date #(:female)
        end
      end
    end

    context "within_four_months_one_day_from_state_pension?" do
      setup do
        Timecop.travel("2013-07-16")
      end

      should "be within four months of pension if born 16 July 1948" do
        calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "male", dob: Date.parse("16 July 1948"))

        assert calculator.within_four_months_one_day_from_state_pension?
      end

      should "be within four months of pension if born 15 November 1948" do
        calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "male", dob: Date.parse("15 November 1948"))

        assert calculator.within_four_months_one_day_from_state_pension?
      end
    end

    context "born on 05-11-1948" do
      setup do
        Timecop.travel("2013-07-22")
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "male", dob: Date.parse("5 November 1948"))
      end

      should "should have 45 available years" do
        assert_equal 45, @calculator.available_years
      end
    end

    context "within_four_months_one_day_from_state_pension?" do
      # test edge cases
      setup do
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "female", dob: Date.parse("1 Feb 1952")) # retires 2013-11-06
      end

      should "not be true for someone exactly four months from state pension date" do
        Timecop.travel("2013-07-06")
        refute @calculator.within_four_months_one_day_from_state_pension?
      end

      should "be true for someone under four months from state pension date" do
        Timecop.travel("2013-07-07")
        assert @calculator.within_four_months_one_day_from_state_pension?
      end
    end

    context "check ni_years_to_date_from_dob before" do
      setup do
        Timecop.travel("2014-04-01")
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "male", dob: Date.parse("6 May 1958"), qualifying_years: 50)
      end

      should "be 36 based on birthday not having happened yet" do
        assert_equal 36, @calculator.ni_years_to_date_from_dob
      end
    end

    context "check ni_years_to_date_from_dob after" do
      setup do
        Timecop.travel("2014-06-01")
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "male", dob: Date.parse("1 May 1958"), qualifying_years: 50)
      end

      should "be 37 years based on birthday having occured" do
        assert_equal 37, @calculator.ni_years_to_date_from_dob
      end
    end

    context "check ni_years_to_date_from_dob before and in same month" do
      setup do
        Timecop.travel("2014-04-01")
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "male", dob: Date.parse("6 April 1958"), qualifying_years: 50)
      end

      should "be 36 years based on birthday not having happened yet" do
        assert_equal 36, @calculator.ni_years_to_date_from_dob
      end
    end

    context "check ni_years_to_date_from_dob after and in same month" do
      setup do
        Timecop.travel("2014-04-10")
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "male", dob: Date.parse("6 April 1958"), qualifying_years: 50)
      end

      should "be 37 years based on birthday having occurred" do
        assert_equal 37, @calculator.ni_years_to_date_from_dob
      end
    end

    context "check correct pension age and date" do
      setup do
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "male", dob: Date.parse("7 June 1960"), qualifying_years: 20)
      end

      should "be 66 years 3 months and 7 September 2026" do
        assert_equal "66 years, 3 months", @calculator.state_pension_age
        assert_equal Date.parse("7 September 2026"), @calculator.state_pension_date
      end
    end

    context "check additional state pension age" do
      setup do
        Timecop.travel("2014-04-10")
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "male", dob: Date.parse("23 March 1969"), qualifying_years: 0)
      end

      should "be 67 years" do
        assert_equal "67 years", @calculator.state_pension_age
      end
    end

    context "#birthday_on_feb_29??" do
      should "be true for a date that is a the 29th of feb" do
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "male", dob: Date.parse("29 February 1976"), qualifying_years: 20)
        assert_equal true, @calculator.birthday_on_feb_29?
      end

      should "be false for a date that is not the 29th of feb" do
        @calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(
          gender: "male", dob: Date.parse("7 June 1960"), qualifying_years: 20)
        assert_equal false, @calculator.birthday_on_feb_29?
      end
    end

    context "#over_55?" do
      should "be true for someone older than 55" do
        Timecop.travel("2015-01-01")
        calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(gender: "male", dob: Date.parse("1 January 1960"), qualifying_years: 20)
        assert_equal true, calculator.over_55?
      end

      should "be false for someone younger than 55" do
        Timecop.travel("2015-01-01")
        calculator = SmartAnswer::Calculators::StatePensionAgeCalculator.new(gender: "male", dob: Date.parse("1 January 1961"), qualifying_years: 20)
        assert_equal false, calculator.over_55?
      end
    end
  end
end
