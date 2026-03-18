attributes :id, :chore_id, :performed_by_id, :created_by_id, :source_text

child(:chore) do
  extends 'api/v1/chores/base'
end

child(:performed_by) do
  extends 'api/v1/users/base'
end

child(:created_by) do
  extends 'api/v1/users/base'
end
