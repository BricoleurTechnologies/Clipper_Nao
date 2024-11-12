import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { loadScript } from "lightning/platformResourceLoader";
import workbook from "@salesforce/resourceUrl/writeExcel";
import getOpps from '@salesforce/apex/OpportunityController.getOpps';

import OPP_NAME from "@salesforce/schema/Opportunity.Name";
import OPP_STAGE from "@salesforce/schema/Opportunity.StageName";
import OPP_CLOSE_DATE from "@salesforce/schema/Opportunity.CloseDate";

const OPP_FIELDS = [OPP_NAME, OPP_STAGE, OPP_CLOSE_DATE];

export default class ExcelJSDemo extends LightningElement {
    
    librariesLoaded = false;
    @api recordId;
    opps;
    oppName;
    dateClosed;
    stageName;

    //@wire(getRecord, { recordId: "$recordId", fields: OPP_FIELDS })
    @wire(getOpps, {oppId: "$recordId"})
    loadOpp({ error, data }) {
        if(error) {
            let message = "Unknown error";
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(", ");
            }
            else if (typeof error.body.message === "string") {
                message = error.body.message;
            }
            console.log('error message bric ', message);
        }
        else if(data) {
            console.log('data bric ',data);
            this.opps = data;
        }
    }

    renderedCallback() {
        if(this.librariesLoaded) return;
        this.librariesLoaded = true;
        //loadScript(this, workbook + "/write-excel-file.min.js")
        loadScript(this, workbook)
            .then(async (data) => {
                console.log("success------>>>", data);
            })
            .catch(error => {
                console.log("failure-------->>>>", error);
            });
    }
    
    // calling the download function from xlsxMain.js
    async download() {
        let _self = this;
        console.log('_self '+_self);
        var columns = [
            {
                column: 'Name',
                type: String,
                // wrap: 'true',
                // color: '#ccaaaa',
                value: d => d.Name
            },
            {
                column: 'Close Date',
                type: Date,
                format: 'dd/mm/yyyy',
                value: d => new Date(d.CloseDate)
            },
            {
                column: 'Stage',
                type: String,
                value: d => d.StageName
            }
        ];
        // When passing `objects` and `schema`.
        await writeXlsxFile(_self.opps, {
            schema: columns,
            fileName: 'file.xlsx'
        })
    }
}