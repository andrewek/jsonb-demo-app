## FIRST WORKOUT

e = {
  squat: {
    type: 'exercise',
    name: 'squat',
    id: SecureRandom.uuid,
    sets: 3,
    reps_per_set: 5,
    weight: 135,
    total_reps_completed: 14,
    successful: false
  }
}

Workout.create!(uuid: SecureRandom.uuid, date: 1.week.ago, exercises: e)

## SECOND WORKOUT

e = {
  bench: {
    type: 'exercise',
    name: 'bench',
    id: SecureRandom.uuid,
    sets: 3,
    reps_per_set: 5,
    weight: 95,
    total_reps_completed: 27,
    successful: true
  }
}

Workout.create!(uuid: SecureRandom.uuid, date: 5.days.ago, exercises: e)

## THIRD WORKOUT

e = {
  squat: {
    type: "exercise",
    name: "squat",
    id: "773dcc5e-609a-47b6-ad2f-298440734319",
    sets: 3,
    reps_per_set: 5,
    weight: 135,
    total_reps_completed: 15,
    successful: true
  },
  bench: {
    type: "exercise",
    name: "bench",
    id: "8f23eddb-192b-40dc-bd53-ac78aee39488",
    sets: 5,
    reps_per_set: 5,
    weight: 95,
    total_reps_completed: 24,
      succesful: false
  },
  row: {
    type: "exercise",
    name: "bent-over row",
    id: "c391862a-44f4-4942-b61c-3319fc151365",
    sets: 3,
    reps_per_set: 5,
    weight: 95,
    total_reps_completed: 17,
    succesful: true
  }
}

Workout.create!(uuid: SecureRandom.uuid, date: 3.days.ago, exercises: e)
