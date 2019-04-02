# JSONB Demo Application

Since Postgres 9.4, `json` and `jsonb` columns have been available. As you might surmise,
these are meant to hold JSON-formatted data. You could, of course, use a text
column to store formatted JSON (or XML, or really any sort of structured
information expressible as text).

However, JSON columns offer a few meaningful advantages:

1. They validate the incoming text payload as well-formatted JSON (e.g. matching
   octets, proper key/value structure)
2. From a code readability standpoint, it is easier to see what types of data
   belong here
3. ActiveRecord converts JSON-type columns to hashes (string keys) automatically
   for us
4. We can query json columns by key name, by value, or by nested object
   structure.

`json` columns store the text input exactly as provided (including any
extraneous whitespace, though that gets stripped by ActiveRecord's
hash-ification). Performing a key-level query on a `json` column requires a
linear scan of all records.

`jsonb` columns convert the text input into a native postgres format. This does
introduce some edge cases (notably around representation of very large or very
small numbers). `jsonb` columns can be indexed by keys using GIN (Generalized
INverted) indexes. This does require that you be able to make predictions about
the structure of the JSON contained in a given `jsonb` column. It also means
that writing to `jsonb` columns is slower, and in fact that it requires a
row-level lock of the data during the write (to preserve the integrity of the
indexes).

This added ability to index the data makes `jsonb` a frequent winner when it
comes to storing structured data. In fact, properly indexed `jsonb` columns with
a consistent data schema can be as performant, if not more so, than NoSQL
databases (such as Mongo) in terms of speed when reading and writing data and
ability to handle load. MongoDB still has cases where it is a better choice, but
Postgres is pretty rad.

Read more about [JSON types
here](https://www.postgresql.org/docs/9.4/datatype-json.html) if you so please.

## App Summary

We're making an application to store workout history. Every day will have a
different workout with different exercises. We want to be able to track progress
of individual exercises over time, and do things like query for all days a given
exercises was performed.

Here is the body we're looking at for a given workout:

```javascript
{
  type: "workout_summary",
  id: "be4f2331-0e15-486d-9eea-d4fdaf6cd19b",
  datetime: "2019-04-02 15:27:51 UTC" // ISO 8601
  exercises: {
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
      weight: 95,f
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
}
```

It's pretty to imagine this as the JSON body either posted to (sans UUIDs, of
course) or returned from a REST endpoint (not implemented here).

You might also notice how the `exercise` body is very consistent so far, but
it's pretty easy to imagine how that might vary -- perhaps we're using
resistance bands, or body weight, or even doing an exercise based on time or
speed instead of sets/reps/weight (e.g. "20 minutes on the treadmill at 8 mph").
Or perhaps a pyramid sort of thing where we have a set of 5, a set of 3, and a
set of 1 (for a given exercise) performed in succession.

We could definitely, if we felt so inclined, represent all of this with
relatively traditional data models. Today, we do not feel so inclined and are
instead going to try capturing the full range of flexibility.

## Setup

You'll want to be running Postgres 9.4 or greater. I'm running Postgres 11. Go
ahead and modify your `config/database.yml` as needed.

## Creating Our Model

[Check out the official Rails docs if you
please](https://edgeguides.rubyonrails.org/active_record_postgresql.html#json-and-jsonb)

We've got a model already set up, which was generated using:

```bash
$ rails g model Workout uuid:uuid date:datetime exercises:jsonb
```

This generated the following migration:

```ruby
class CreateWorkouts < ActiveRecord::Migration[5.2]
  def change
    create_table :workouts do |t|
      t.uuid :uuid
      t.datetime :date
      t.jsonb :exercises

      t.timestamps
    end
  end
end
```

(We didn't need to enable the Postgres UUID extensions because we're not having
PG create our UUIDs nor are we using UUIDs as primary keys, at least yet. All we
get here is a fixed-width string column with some syntactic magic when it comes
to searching by UUID).

And gives us the following model:

```ruby
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
end
```

## Populating Data

We can save our first record like so:

```ruby
e = {
  squat: {
    type: 'exercise',
    name: 'squat',
    id: SecureRandom.uuid,
    sets: 3,
    reps_per_set: 5,
    weight: 135,
    total_reps_completed: 15,
    successful: true
  }
}

w = Workout.new(uuid: SecureRandom.uuid, date: DateTime.now, exercises: e)
w.save
```

This gives us the following console output:

<pre>
irb(main):040:0> w = Workout.new(uuid: SecureRandom.uuid, date: DateTime.now, exercises: e)
=> #<Workout id: nil, uuid: "b16b45a4-59df-439e-9bc3-200bc4f9351b", date: "2019-04-02 16:42:29", exercises: {"squat"=>{"type"=>"exercise", "name"=>"squat", "id"=>"51addb0e-14a5-4611-93c1-749a7ec03cd3", "sets"=>3, "reps_per_set"=>5, "weight"=>135, "total_reps_completed"=>15, "successful"=>true}}, created_at: nil, updated_at: nil>
irb(main):041:0> w.save
   (0.3ms)  BEGIN
  Workout Create (0.6ms)  INSERT INTO "workouts" ("uuid", "date", "exercises", "created_at", "updated_at") VALUES ($1, $2, $3, $4, $5) RETURNING "id"  [["uuid", "b16b45a4-59df-439e-9bc3-200bc4f9351b"], ["date", "2019-04-02 16:42:29.889455"], ["exercises", "{\"squat\":{\"type\":\"exercise\",\"name\":\"squat\",\"id\":\"51addb0e-14a5-4611-93c1-749a7ec03cd3\",\"sets\":3,\"reps_per_set\":5,\"weight\":135,\"total_reps_completed\":15,\"successful\":true}}"], ["created_at", "2019-04-02 16:42:31.004102"], ["updated_at", "2019-04-02 16:42:31.004102"]]
   (0.8ms)  COMMIT
=> true
</pre>

If you run `$ rails db:seed`, you'll have some pre-populated data to work with.

## Querying Data - Simple Queries

Let's grab our first workout and look at our exercise:

```ruby
w = Workout.first
w.exercises
```

We get back a `Hash` with string keys. So we could get back a real value with
`w.exercises['squat']`, but not with `w.exercises[:squat]`. This means we have
to be careful both with access and updates. We'll discuss a workaround for this
later.

## Updating Data

Let's say we realize that instead of 15 reps, we actually did 16.

```ruby
w.exercises["squat"]["total_reps_completed"] = 16
```

We can save this with `w.save` and see everything updated in place just as we
desire.

We can also use [native postgres
functions](https://medium.com/@louiseswift/quickly-familiarise-yourself-with-postgres-jsonb-in-rails-567d41e1f6a4)
to update data.

If we try to use a symbol as our key, like so, we run into some weird problems:

```ruby
w.exercises["exercises"]["squat"][:total_reps_completed] = 72
```

This gives us the following (notice the last two lines):

```ruby
{
  "id"=>"88c53c39-4b51-42a8-9f3c-147701a789f0",
  "name"=>"squat",
  "sets"=>3,
  "type"=>"exercise",
  "weight"=>135,
  "successful"=>true,
  "reps_per_set"=>5,
  "total_reps_completed"=>16,
  :total_reps_completed=>72
}
```

When we save, the latter value will overwrite the former value, but *only
because* it was inserted later (hashes in Ruby retain knowledge of the order keys
were inserted). This is not safe to trust, especially in a production
environment.

## Querying Data - Advanced Queries

Suppose we want to find all exercises where we performed squats. One option,
certainly, would be to grab all workout records and then linearly search through
them:

```ruby
Workout.all.select { |workout| workout.exercises['squat'].present? }
```

This is a bad idea and we should not do it, as it requires that we load all
records into memory (even if we use batching).

Let's instead use a JSON query:

```ruby
Workout.where('exercises ? :key', key: 'squat')
```

This query basically says "Give me all workouts whose exercise hash has a
top-level key of "squat".

Similarly, we could find all workouts that contain either squats or bench
presses (or both):

```ruby
Workout.where('exercises ?| array[:keys]', keys: ['squat', 'bench'])
```

Or just workouts that contain both squats and bench presses:

```ruby
Workout.where('exercises ?& array[:keys]', keys: ['squat', 'bench'])
```

Or perhaps all workouts where squatting was successful (however we determine
that):

```ruby
Workout.where("exercises -> 'squat' @> ?", { successful: true}.to_json)
```

Or maybe we just want to find all days we squatted where we did at least 3 reps
per set:

```ruby
Workout.where("(exercises -> 'squat' ->> 'reps_per_set')::int >= :reps", reps: 3)
```

Let's look at the following query operators:

| operator | description |
|----------|------------------------|
| `->` | Get next JSON object by key |
| `->>` | Get next JSON object as string (can cast) |
| `#>` | follow path, return JSON object |
| `#>>` | follow path, return string |
| `@>` | return json object if left value contains right value |
| `?` | return json object if left value contains the right value as a key |
| `?\|` | return json object if left value contains any of the right-hand values as keys |
| `?&` | return json object if left value contains all of the right hand values as keys |

You can read more about [JSON operators
here](https://www.postgresql.org/docs/9.4/functions-json.html)

## Setting up Indices

We could set up a broad index on the `exercises` column like so (in our
migration):

```ruby
add_index :workouts, :exercises, using: :gin
```

This will index top-level keys.

If we want to create further indices, perhaps for a specific path, we'll need to
modify ActiveRecord to dump its schema in SQL form and then use an expression.

## Other Optimizations and Convenience Boosters

### Symbols as Keys

We can, if we feel so inclined, have our JSON column be returned as a Hash with
indifferent access by default:

```ruby
class JsonbSerializer
  def self.dump(hsh)
    hsh
  end

  def self.load(hsh)
    (hsh || {}).with_indifferent_access
  end
end
```

A serializer must respond to both `.dump` and `.load` - ActiveRecord already
serializes incoming JSON correctly. We just need it to handle the JSON coming
out.

Then we'll just need to update our model appropriately:

```ruby
class Workout < ApplicationRecord
  serialize :exercises, JsonbSerializer
end
```

### Default Values

It may be useful to have our json columns have a default value of an empty hash,
particularly when it comes to querying and data validation:

```ruby
class CreateWorkouts < ActiveRecord::Migration[5.2]
  def change
    create_table :workouts do |t|
      t.uuid :uuid
      t.datetime :date
      t.jsonb :exercises, null: false, default: '{}'

      t.timestamps
    end
  end
end
```

### Store Accessors

If we find that we're using the same accessor repeatedly, e.g.
`workout.exercises[:squat]`, we can create a custom accessor for it:

```ruby
class Workout < ApplicationRecord
  serialize :exercises, JsonbSerializer

  store_accessor :exercises, :squat, :bench
end
```

Calling `workout.bench` will yield the exact same value as
`workout.exercises[:bench]` - ditto for `workout.bench = ...` and
`workout.exercises.bench = ...`

## Resources

+ [Postgres 9.5 JSON functions](https://www.postgresql.org/docs/9.5/functions-json.html)
+ [Example JSON queries with ActiveRecord](https://johnmosesman.com/post/querying-postgres-json-columns-with-activerecord/)
+ [Using Postgres and JSONB with Ruby on Rails](https://nandovieira.com/using-postgresql-and-jsonb-with-ruby-on-rails)
+ [Unleash the Power of JSON in Postgres](https://blog.codeship.com/unleash-the-power-of-storing-json-in-postgres/)
+ [Quickly Familiarize Yourself with Postgres JSONB in Rails](https://medium.com/@louiseswift/quickly-familiarise-yourself-with-postgres-jsonb-in-rails-567d41e1f6a4)
