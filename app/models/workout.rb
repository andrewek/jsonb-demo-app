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

class Workout < ApplicationRecord
  serialize :exercises, JsonbSerializer
  store_accessor :exercises, :squat, :bench
end
