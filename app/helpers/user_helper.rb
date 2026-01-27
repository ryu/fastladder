module UserHelper
  def subscribe_button(feedlink)
    return unless current_member

    if (subs = current_member.check_subscribed(feedlink)).present?
      raw <<~HTML
        <span class="subscribed">[subscribed]</span>
        <button class="subs_edit" rel="edit:#{subs.id}" onkeydown="subs_edit.call(this,event)" onmousedown="subs_edit.call(this,event)" onclick="return false">edit</button>
      HTML
    else
      link_to "add", subscribe_path(url: feedlink), class: "subscribe"
    end
  end
end
