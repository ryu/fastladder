class AddUniqueIndexToMembersAuthKey < ActiveRecord::Migration[8.1]
  def up
    # 重複チェック（non-NULL値のみ）
    # MySQLではNULL値は複数許可されるため、NULL値の重複はチェックしない
    duplicates = Member.where.not(auth_key: nil)
                       .group(:auth_key)
                       .having("COUNT(*) > 1")
                       .pluck(:auth_key)

    if duplicates.any?
      raise ActiveRecord::IrreversibleMigration,
            "Duplicate auth_key values found: #{duplicates.join(', ')}. " \
            "Please resolve these duplicates before running this migration."
    end

    # MySQLでもNULL複数許可は標準動作のため WHERE句不要
    # PostgreSQL/SQLite/MySQLすべてで動作する
    add_index :members, :auth_key, unique: true
  end

  def down
    remove_index :members, :auth_key
  end
end
