({
    renderPdf : function(component, event, helper) {
        var oppId = component.get("v.recordId");
        var pageUrl = "/apex/OnlineQuoteFormPDF?Id="+oppId;
        component.set("v.vfPageUrl", pageUrl);
    }
})