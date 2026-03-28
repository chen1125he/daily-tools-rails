attributes :id, :chore_type, :chore_id, :custom_chore_name, :performer_id, :creator_id, :source_text, :points, :performed_at

node(:chore_name) { |record| record.display_chore_name }

child(:chore) do
  extends 'api/v1/chores/base'
end

child(performer: :performer) do
  extends 'api/v1/users/base'
end

child(creator: :creator) do
  extends 'api/v1/users/base'
end
