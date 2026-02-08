class FeedFormatter {
    constructor(opt) {
        if(opt && opt.ads){
            this.tmpl = new Template(FeedFormatter.TMPL_ADS);
        } else {
            this.tmpl = new Template(FeedFormatter.TMPL);
        }
        var feed_filter = {
            image : FF.channel.image,
            folder: function(v){
                return v ? v.ry(8,"...") : "Uncategolized";
            }
        };
        this.tmpl.add_filters(feed_filter);
    }
    compile() {
        return this.tmpl.compile()
    }
}
FeedFormatter.TMPL = Template.get("inbox_feed");
FeedFormatter.TMPL_ADS = Template.get("inbox_adfeeds");

