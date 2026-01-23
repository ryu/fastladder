class AddUniqueIndexToMembersAuthKey < ActiveRecord::Migration[8.1]
  def change
    # Partial unique index: only applies to non-NULL auth_keys
    # This allows multiple members to have NULL auth_key while
    # ensuring all actual API keys are unique
    add_index :members, :auth_key, unique: true, where: "auth_key IS NOT NULL"
  end
end
