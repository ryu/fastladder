# frozen_string_literal: true

# Concern for bulk subscription update operations in API controllers
module BulkSubscriptionUpdates
  extend ActiveSupport::Concern

  private

  # "1,2,3" -> [1, 2, 3]
  def parse_subscription_ids
    params[:subscribe_id].to_s.split(/\s*,\s*/).map(&:to_i).reject(&:zero?)
  end

  # メンバーの購読のみを対象にする
  def member_subscriptions(ids)
    @member.subscriptions.where(id: ids)
  end

  # "0" or "1" -> boolean or nil
  def parse_boolean(value)
    return nil unless value =~ /^[01]$/
    value.to_i == 1
  end

  # フォルダIDが有効かチェックして返す
  def validated_folder_id(folder_id)
    id = folder_id.to_i
    return nil unless id > 0
    @member.folders.exists?(id) ? id : nil
  end
end
