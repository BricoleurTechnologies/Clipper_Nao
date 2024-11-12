import { LightningElement, track } from "lwc";
import getOppList from "@salesforce/apex/ExcelExportPOC.getOpp";
export default class ExcelExportLWC extends LightningElement {
  @track xlsHeader = []; 
  @track workSheetNameList = [];
  @track xlsData = []; 
  @track filename = "Opp Export.xlsx";
  @track oppData = []; 

  connectedCallback() {
    //apex call for bringing the contact data  
    getOppList()
      .then(result => {
        console.log(result);
        this.oppData = [...this.oppData, ...result];
        this.xlsFormatter(result, "Opportunities");
      })
      .catch(error => {
        console.error(error);
      });
  }

  // formating the data to send as input to  xlsxMain component
  xlsFormatter(data, sheetName) {
    let Header = Object.keys(data[0]);
    this.xlsHeader.push(Header);
    this.workSheetNameList.push(sheetName);
    this.xlsData.push(data);
  }

   // calling the download function from xlsxMain.js 
  download() {
    this.template.querySelector("c-xlsx-main").download();
  }
}