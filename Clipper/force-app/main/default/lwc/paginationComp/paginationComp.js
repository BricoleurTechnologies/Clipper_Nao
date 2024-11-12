import {LightningElement,api,track,wire} from 'lwc';
//Import apex method 
import fetchStockTakeResults from '@salesforce/apex/fetchStockTakeResult.fetchStockTakeResults';
import { refreshApex } from "@salesforce/apex";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
  import { RefreshEvent } from 'lightning/refresh';
  import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class paginationComp extends LightningElement {
  
    // JS Properties 
    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    @track
    records = []; //All records available in the data table
    columns = []; //columns information available in the data table
    totalRecords = 0; //Total no.of records
    pageSize; //No.of records to be displayed per page
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number    
    recordsToDisplay = []; //Records to be displayed on the page
    draftValues = [];
    @api recordId;
     @track relatedRecordResult;

error;
@wire(fetchStockTakeResults, { recordid: "$recordId" })
  wiredfetchStockTakeResults(result){
                this.relatedRecordResult = result;
    if (result.data) {
      this.records = result.data;
      
        this.totalRecords = this.records.length; // update total records count                 
        this.pageSize = this.pageSizeOptions[0]; //set pageSize with default value as first option
        this.paginationHelper(); // call helper menthod to update pagination logic
        console.log('@@@@'+this.pageSize);
      this.error = undefined;
    } else if (result.error) {
      this.error = error;
      this.records = undefined;
    }
  }



    get bDisableFirst() {
        return this.pageNumber == 1;
    }

    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }
  
  
  
    // connectedCallback method called when the element is inserted into a document
    connectedCallback() {
        // set datatable columns info
        console.log('error while fetch contacts--> ' + JSON.stringify(this.records));
        this.columns = [{
                label: 'StockTake Result ID',
                fieldName: 'Name',
            },
            {
                label: 'StockTake Count',
                fieldName: 'Stocktake_Count__c',
                editable: true,
            },
            
        ];
        
        // fetch contact records from apex method 
        /*fetchStockTakeResults({recordid:this.recordId})
            .then((result) => {
                if (result != null) {
                    console.log('RESULT--> ' + JSON.stringify(result));
                    this.records = result;
                    
                }
            })
            .catch((error) => {
                console.log('error while fetch contacts--> ' + JSON.stringify(error));
            });*/
    }
 

  

 async handleSave(event) {
    // Convert datatable draft values into record objects
    var records = event.detail.draftValues.slice().map((draftValue) => {

      var fields = Object.assign({}, draftValue);
       fields={...fields,flag__c:true}
      return { fields };
    });
    // Clear all datatable draft values
    this.draftValues = [];
  try {
      // Update all records in parallel thanks to the UI API
      const recordUpdatePromises = records.map((record) => updateRecord(record));
      await Promise.all(recordUpdatePromises);

      // Report success with a toast
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Contacts updated",
          variant: "success",
        }),
      );

      // Display fresh data in the datatable
      await refreshApex(this.relatedRecordResult);
       // this.dispatchEvent(new RefreshEvent());

    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error updating or reloading contacts",
          message: error.body.message,
          variant: "error",
        }),
      );
    }
 }
   @api
  get outputValue() {
    return this.records;
  }

  toggleOutput() {
    this.records = !this.records;
    console.log('output: ', this.records);
    this.dispatchEvent(new FlowAttributeChangeEvent('outputValue', this.records));
  }

    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.paginationHelper();
    }

    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }

    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }

    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }


    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }

        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.records[i]);
        }
        
    }
}