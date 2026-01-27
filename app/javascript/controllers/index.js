// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"

// Eager load controllers that existed before
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Explicitly register new controllers (workaround for importmap caching)
import KeyhelpController from "controllers/keyhelp_controller"
import SubscribeFormController from "controllers/subscribe_form_controller"
import SubsReloadController from "controllers/subs_reload_controller"
import ManageController from "controllers/manage_controller"
import PinButtonController from "controllers/pin_button_controller"
import MenuToggleController from "controllers/menu_toggle_controller"
import ViewmodeToggleController from "controllers/viewmode_toggle_controller"
import SortmodeToggleController from "controllers/sortmode_toggle_controller"
import ShowAllController from "controllers/show_all_controller"
import TipsController from "controllers/tips_controller"
import ElementHideController from "controllers/element_hide_controller"
import SubsItemController from "controllers/subs_item_controller"
import FolderToggleTemplateController from "controllers/folder_toggle_template_controller"
import RatePadController from "controllers/rate_pad_controller"
import ItemPinToggleController from "controllers/item_pin_toggle_controller"
import ItemCloseNextController from "controllers/item_close_next_controller"
import ClipRateController from "controllers/clip_rate_controller"
import ClipEscapeController from "controllers/clip_escape_controller"
import PreventSubmitController from "controllers/prevent_submit_controller"

application.register("keyhelp", KeyhelpController)
application.register("subscribe-form", SubscribeFormController)
application.register("subs-reload", SubsReloadController)
application.register("manage", ManageController)
application.register("pin-button", PinButtonController)
application.register("menu-toggle", MenuToggleController)
application.register("viewmode-toggle", ViewmodeToggleController)
application.register("sortmode-toggle", SortmodeToggleController)
application.register("show-all", ShowAllController)
application.register("tips", TipsController)
application.register("element-hide", ElementHideController)
application.register("subs-item", SubsItemController)
application.register("folder-toggle-template", FolderToggleTemplateController)
application.register("rate-pad", RatePadController)
application.register("item-pin-toggle", ItemPinToggleController)
application.register("item-close-next", ItemCloseNextController)
application.register("clip-rate", ClipRateController)
application.register("clip-escape", ClipEscapeController)
application.register("prevent-submit", PreventSubmitController)
