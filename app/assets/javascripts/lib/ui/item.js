class ItemFormatter {
    constructor() {
        this.tmpl = new Template(ItemFormatter.TMPL);
        var filters = {
            created_on  : Filter.created_on,
            modified_on : Filter.modified_on,
            author      : Filter.author,
            enclosure   : Filter.enclosure,
            category    : Filter.category
        };
        this.tmpl.add_filters(filters);
    }
    compile() {
        return this.tmpl.compile();
    }
    reset_count() {
        this.item_count = 0;
    }
}
ItemFormatter.TMPL = Template.get("inbox_items");

