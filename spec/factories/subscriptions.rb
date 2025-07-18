# frozen_string_literal: true

FactoryBot.define do
  factory :subscription do
    association :user
    tier { :basic }
    status { :active }
    current_period_start { Time.current }
    current_period_end { 1.month.from_now }
    
    trait :pro do
      tier { :pro }
    end
    
    trait :enterprise do
      tier { :enterprise }
    end
    
    trait :inactive do
      status { :inactive }
    end
    
    trait :canceled do
      status { :canceled }
      canceled_at { Time.current }
    end
  end
end