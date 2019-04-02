# == Schema Information
#
# Table name: workouts
#
#  id         :bigint(8)        not null, primary key
#  date       :datetime
#  exercises  :jsonb
#  uuid       :uuid
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class WorkoutTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
